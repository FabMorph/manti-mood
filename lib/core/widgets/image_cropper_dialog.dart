import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/crop_state_registry.dart';
import '../services/media_upload_service.dart';
import '../theme/app_colors.dart';
import 'product_image.dart';

enum CropAspectRatio {
  product4x3('4:3 (Ürün Kartı)', 4 / 3),
  square1x1('1:1 (Kare)', 1 / 1),
  widescreen16x9('16:9 (Geniş)', 16 / 9),
  banner16x7('16:7 (Vitrin Banner)', 16 / 7);

  final String label;
  final double ratio;
  const CropAspectRatio(this.label, this.ratio);
}

class ImageCropperDialog extends StatefulWidget {
  final String imageSource;
  final String? originalSource;
  final double? initialScale;
  final int? initialRotation;
  final Matrix4? initialMatrix;
  final double defaultAspectRatio;
  final String title;

  const ImageCropperDialog({
    super.key,
    required this.imageSource,
    this.originalSource,
    this.initialScale,
    this.initialRotation,
    this.initialMatrix,
    this.defaultAspectRatio = 4 / 3,
    this.title = 'Fotoğrafı Çerçevele & Ayarla',
  });

  /// Hızlı modal açma yardımcısı (Önceki kırpma ve zoom seviyesini otomatik hatırlar)
  static Future<String?> show(
    BuildContext context, {
    required String imageSource,
    String? originalSource,
    double? initialScale,
    int? initialRotation,
    Matrix4? initialMatrix,
    double defaultAspectRatio = 4 / 3,
    String title = 'Fotoğrafı Çerçevele & Ayarla',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImageCropperDialog(
        imageSource: imageSource,
        originalSource: originalSource,
        initialScale: initialScale,
        initialRotation: initialRotation,
        initialMatrix: initialMatrix,
        defaultAspectRatio: defaultAspectRatio,
        title: title,
      ),
    );
  }

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 4.0;

  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _controller = TransformationController();

  late String _effectiveImageSource;
  late CropAspectRatio _selectedRatio;
  double _currentScale = 1.0;
  int _rotationQuarterTurns = 0;
  bool _showGrid = true;
  bool _isSaving = false;
  bool _initialTransformApplied = false;

  double _frameW = 480.0;
  double _frameH = 210.0;

  ui.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    _selectedRatio = CropAspectRatio.values.firstWhere(
      (r) => (r.ratio - widget.defaultAspectRatio).abs() < 0.05,
      orElse: () => CropAspectRatio.banner16x7,
    );

    // 1. Orijinal yüksek çözünürlüklü görsel kaynağını belirle
    // Asla daha önce kırpılmış/küçültülmüş görsel üzerinden tekrar kırpma yapılmaz!
    final orig = widget.originalSource?.trim();
    if (orig != null && orig.isNotEmpty) {
      _effectiveImageSource = orig;
    } else {
      _effectiveImageSource = CropStateRegistry.getOriginalSource(widget.imageSource);
    }

    // 2. Daha önce kaydedilmiş zoom seviyesini algıla ve yükle
    final savedScale = widget.initialScale ?? CropStateRegistry.getSavedScale(widget.imageSource);
    _currentScale = savedScale.clamp(_minZoom, _maxZoom);

    // 3. Daha önce kaydedilmiş rotasyonu algıla
    final savedRotation = widget.initialRotation ?? CropStateRegistry.getSavedRotation(widget.imageSource);
    _rotationQuarterTurns = savedRotation % 4;

    _controller.addListener(_onTransformChanged);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      Uint8List? bytes = await _resolveSourceBytes(_effectiveImageSource);
      if (bytes == null && _effectiveImageSource != widget.imageSource) {
        // Master görsel başarısız olursa mevcut görseli dene
        bytes = await _resolveSourceBytes(widget.imageSource);
      }
      if (bytes != null && bytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _decodedImage = frame.image;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error decoding image in cropper: $e');
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<Uint8List?> _resolveSourceBytes(String source) async {
    final clean = source.trim();
    if (clean.isEmpty) return null;

    if (clean.startsWith('data:image') || clean.startsWith('data:')) {
      final comma = clean.indexOf(',');
      final b64 = comma != -1 ? clean.substring(comma + 1) : clean;
      return base64Decode(b64);
    }

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      try {
        final bundle = NetworkAssetBundle(Uri.parse(clean));
        final data = await bundle.load(clean);
        return data.buffer.asUint8List();
      } catch (e) {
        debugPrint('Network image fetch error: $e');
        return null;
      }
    }

    try {
      final assetPath = clean.startsWith('/')
          ? clean.substring(1)
          : (clean.startsWith('assets/') ? clean : 'assets/$clean');
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Asset load error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final clamped = scale.clamp(_minZoom, _maxZoom);
    if ((clamped - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = clamped;
      });
    }
  }

  void _setScale(double newScale, double frameWidth, double frameHeight) {
    final target = newScale.clamp(_minZoom, _maxZoom);
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale == 0) return;
    if ((target - currentScale).abs() < 0.001) return;

    final factor = target / currentScale;
    final center = Offset(frameWidth / 2, frameHeight / 2);

    final zoomMatrix = Matrix4.translationValues(center.dx, center.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0))
      ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));

    _controller.value = zoomMatrix * _controller.value;
    setState(() {
      _currentScale = target;
    });
  }

  void _applyInitialTransformIfNeeded(double frameWidth, double frameHeight) {
    if (_initialTransformApplied) return;
    _initialTransformApplied = true;

    final savedMatrix = widget.initialMatrix ?? CropStateRegistry.getSavedMatrix(widget.imageSource);
    if (savedMatrix != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.value = Matrix4.copy(savedMatrix);
          final scale = _controller.value.getMaxScaleOnAxis().clamp(_minZoom, _maxZoom);
          setState(() {
            _currentScale = scale;
          });
        }
      });
      return;
    }

    if ((_currentScale - 1.0).abs() > 0.01) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setScale(_currentScale, frameWidth, frameHeight);
        }
      });
    }
  }

  void _zoomStep(double multiplier, double frameWidth, double frameHeight) {
    // Sınır koruması: Sınır değerindeyken butonlara basılsa da hata vermez, sessizce etkisiz kalır
    if (multiplier > 1.0 && _currentScale >= _maxZoom - 0.001) {
      return;
    }
    if (multiplier < 1.0 && _currentScale <= _minZoom + 0.001) {
      return;
    }

    final target = (_currentScale * multiplier).clamp(_minZoom, _maxZoom);
    if ((target - _currentScale).abs() < 0.001) return;
    _setScale(target, frameWidth, frameHeight);
  }

  void _resetTransform() {
    _controller.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
      _rotationQuarterTurns = 0;
    });
  }

  void _rotate90() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  Future<Uint8List?> _renderCanvasCrop(ui.Image img) async {
    try {
      final double targetWidth = 1600.0;
      final double targetHeight = targetWidth / _selectedRatio.ratio;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        Rect.fromLTWH(0, 0, targetWidth, targetHeight),
      );

      canvas.clipRect(Rect.fromLTWH(0, 0, targetWidth, targetHeight));

      final frameW = _frameW > 0 ? _frameW : 480.0;
      final frameH = _frameH > 0 ? _frameH : (frameW / _selectedRatio.ratio);

      final double scaleFactor = targetWidth / frameW;
      canvas.scale(scaleFactor, scaleFactor);

      canvas.transform(_controller.value.storage);

      final isRotated90or270 = (_rotationQuarterTurns % 2 == 1);
      final double naturalW = isRotated90or270 ? img.height.toDouble() : img.width.toDouble();
      final double naturalH = isRotated90or270 ? img.width.toDouble() : img.height.toDouble();

      final fittedSizes = applyBoxFit(BoxFit.contain, Size(naturalW, naturalH), Size(frameW, frameH));
      final double fittedW = fittedSizes.destination.width;
      final double fittedH = fittedSizes.destination.height;

      canvas.save();
      canvas.translate(frameW / 2, frameH / 2);
      canvas.rotate(_rotationQuarterTurns * (math.pi / 2));

      if (isRotated90or270) {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: fittedH, height: fittedW),
          Paint()..filterQuality = FilterQuality.high,
        );
      } else {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: fittedW, height: fittedH),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
      canvas.restore();

      final picture = recorder.endRecording();
      final ui.Image cropped = await picture.toImage(targetWidth.toInt(), targetHeight.toInt());
      final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Canvas crop error: $e');
      return null;
    }
  }

  Future<void> _captureAndSave() async {
    try {
      setState(() => _isSaving = true);

      String? resultUrl;

      // 1. Offscreen Canvas Crop (Doğrudan hafızadan render - tam çözünürlüklü ve net)
      if (_decodedImage != null) {
        final croppedBytes = await _renderCanvasCrop(_decodedImage!);
        if (croppedBytes != null && croppedBytes.length > 500) {
          resultUrl = await MediaUploadService.instance.uploadRawImageBytes(
            croppedBytes,
            fileName: 'crop_${DateTime.now().millisecondsSinceEpoch}.png',
          );
        }
      }

      // 2. Secondary attempt: RepaintBoundary (Eğer canvas render edilemediyse yedek)
      if (resultUrl == null) {
        final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          try {
            final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null && byteData.lengthInBytes > 1000) {
              final bytes = byteData.buffer.asUint8List();
              resultUrl = await MediaUploadService.instance.uploadRawImageBytes(
                bytes,
                fileName: 'crop_${DateTime.now().millisecondsSinceEpoch}.png',
              );
            }
          } catch (boundaryErr) {
            debugPrint('RepaintBoundary capture failed: $boundaryErr');
          }
        }
      }

      // 3. Güvenlik Yedeği: Hiçbiri olmazsa etkin kaynağı döndür
      resultUrl ??= _effectiveImageSource;

      // Merkezi Registry'ye kaydet:
      // Böylece bir sonraki düzenlemede hem ORİJİNAL tam boy resim açılır,
      // hem de kullanıcının %400'e dayadığı sayaç tam %400 olarak korunur!
      CropStateRegistry.register(
        originalSource: _effectiveImageSource,
        croppedResult: resultUrl,
        scale: _currentScale,
        rotationQuarterTurns: _rotationQuarterTurns,
        transformMatrix: _controller.value,
        aspectRatio: _selectedRatio.ratio,
      );

      if (mounted) {
        Navigator.of(context).pop(resultUrl);
      }
    } catch (e) {
      debugPrint('Kırpma ve kaydetme hatası: $e');
      if (mounted) {
        Navigator.of(context).pop(_effectiveImageSource);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMasterSource = CropStateRegistry.hasMaster(widget.imageSource) ||
        (_effectiveImageSource != widget.imageSource && _effectiveImageSource.isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Çerçevenin dinamik boyut hesabı
            final double availableWidth = constraints.maxWidth;
            double frameW = availableWidth.clamp(240.0, 480.0);
            double frameH = frameW / _selectedRatio.ratio;

            // Dikey taşmayı önleme
            const double maxFrameH = 310.0;
            if (frameH > maxFrameH) {
              frameH = maxFrameH;
              frameW = frameH * _selectedRatio.ratio;
            }

            _frameW = frameW;
            _frameH = frameH;

            // Önceki zoom/konum ayarını ilk açılışta uygula
            _applyInitialTransformIfNeeded(frameW, frameH);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Başlık & Kapatma Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.crop, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Görseli sürükleyerek konumlandırabilir, zoom butonları veya parmak/tekerlek ile çerçeveye tam oturtarak en iyi görüntüyü yakalayabilirsiniz.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // Önceki zoom ayarı algılandı bilgi çipi
                if (hasMasterSource)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Önceki ayar (%${(_currentScale * 100).toInt()} zoom) ve orijinal yüksek çözünürlüklü fotoğraf yüklendi. İstediğiniz gibi yakınlaştırıp uzaklaştırabilirsiniz.',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Çerçeve Oranı Seçimi (Aspect Ratio Pills)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CropAspectRatio.values.map((ratioItem) {
                      final isSelected = _selectedRatio == ratioItem;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(ratioItem.label, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedRatio = ratioItem);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. CANLI ÖNİZLEME & ÇERÇEVELEME ALANI
                Expanded(
                  child: Center(
                    child: Container(
                      width: frameW,
                      height: frameH,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gerçek Kırpılacak Katman (RepaintBoundary)
                          RepaintBoundary(
                            key: _cropKey,
                            child: ClipRect(
                              child: Container(
                                width: frameW,
                                height: frameH,
                                color: Colors.transparent,
                                child: InteractiveViewer(
                                  transformationController: _controller,
                                  clipBehavior: Clip.hardEdge,
                                  minScale: _minZoom,
                                  maxScale: _maxZoom,
                                  boundaryMargin: const EdgeInsets.all(400),
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: _rotationQuarterTurns,
                                      child: ProductImage(
                                        imageUrl: _effectiveImageSource,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Kılavuz Çizgileri ve Köşe Nişangahları (RepaintBoundary DIŞINDA çizilir, fotoğrafa karışmaz)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _CropGridPainter(
                                  accentColor: AppColors.primary,
                                  showGrid: _showGrid,
                                ),
                              ),
                            ),
                          ),

                          // Sürükleme İpucu Rozeti
                          Positioned(
                            bottom: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app, size: 12, color: Colors.white70),
                                    SizedBox(width: 4),
                                    Text(
                                      'Kaydırmak için sürükleyin',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4. ZOOM VE AYAR ARAÇLARI ÇUBUĞU
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Sınır durumları
                      Builder(builder: (context) {
                        final bool isAtMin = _currentScale <= _minZoom + 0.001;
                        return IconButton(
                          tooltip: isAtMin ? 'Minimum sınır (%50)' : 'Uzaklaştır (-)',
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          color: isAtMin ? AppColors.textSecondary.withValues(alpha: 0.35) : AppColors.primary,
                          onPressed: () => _zoomStep(0.85, frameW, frameH),
                        );
                      }),

                      // Zoom Slider (Önceki zoom değerini tam olarak yansıtır)
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.cardBorder,
                            thumbColor: AppColors.primary,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _currentScale.clamp(_minZoom, _maxZoom),
                            min: _minZoom,
                            max: _maxZoom,
                            onChanged: (val) => _setScale(val, frameW, frameH),
                          ),
                        ),
                      ),

                      // Zoom In Butonu
                      Builder(builder: (context) {
                        final bool isAtMax = _currentScale >= _maxZoom - 0.001;
                        return IconButton(
                          tooltip: isAtMax ? 'Maksimum sınır (%400)' : 'Yakınlaştır (+)',
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: isAtMax ? AppColors.textSecondary.withValues(alpha: 0.35) : AppColors.primary,
                          onPressed: () => _zoomStep(1.18, frameW, frameH),
                        );
                      }),

                      // Yüzde Etiketi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '${(_currentScale.clamp(_minZoom, _maxZoom) * 100).toInt()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // 90 Derece Döndür
                      IconButton(
                        tooltip: '90° Sağa Döndür',
                        icon: const Icon(Icons.rotate_right, size: 20),
                        onPressed: _rotate90,
                      ),

                      // Kılavuz Çizgisi Aç/Kapa
                      IconButton(
                        tooltip: _showGrid ? 'Kılavuz Çizgisini Gizle' : 'Kılavuz Çizgisini Göster',
                        icon: Icon(
                          _showGrid ? Icons.grid_on : Icons.grid_off,
                          size: 19,
                          color: _showGrid ? AppColors.primary : AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _showGrid = !_showGrid),
                      ),

                      // Sıfırla
                      IconButton(
                        tooltip: 'Merkeze Al & %100 Yap',
                        icon: const Icon(Icons.restart_alt, size: 20),
                        onPressed: _resetTransform,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 5. ALT EYLEM BUTONLARI (KAYDET, VAZGEÇ, ORİJİNALE DÖN)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasMasterSource)
                      TextButton.icon(
                        icon: const Icon(Icons.undo, size: 14),
                        label: const Text('Orijinal Görsel', style: TextStyle(fontSize: 11)),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(_effectiveImageSource),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
                          child: const Text('Vazgeç'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(_isSaving ? 'Görsel Hazırlanıyor...' : 'Çerçeveyi Kaydet & Kullan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSaving ? null : _captureAndSave,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Çerçeve Kılavuz Çizgileri ve Köşe Nişangah Çizicisi
class _CropGridPainter extends CustomPainter {
  final Color accentColor;
  final bool showGrid;

  _CropGridPainter({
    required this.accentColor,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dış çerçeve çizgisi
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, borderPaint);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      // 1/3 ve 2/3 Dikey Çizgiler
      canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), gridPaint);
      canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), gridPaint);

      // 1/3 ve 2/3 Yatay Çizgiler
      canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), gridPaint);
      canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), gridPaint);
    }

    // Köşe L-Nişangahları (Corner Brackets)
    final cornerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 18.0;

    // Sol Üst
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), cornerPaint);

    // Sağ Üst
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), cornerPaint);

    // Sol Alt
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), cornerPaint);

    // Sağ Alt
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CropGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor || oldDelegate.showGrid != showGrid;
  }
}
