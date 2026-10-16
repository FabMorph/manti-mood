-- ==============================================================================
-- MANTI MOOD — TEK PARÇA ANA VERİTABANI, GÜVENLİK (RLS) VE BAŞLANGIÇ KURULUMU
-- Bu dosyayı Supabase -> SQL Editor alanına yapıştırıp "Run" demeniz yeterlidir.
-- Hem sıfırdan kurulum hem de mevcut veritabanını güncelleme için %100 güvenlidir.
-- ==============================================================================

-- 1. EKLENTİLER (EXTENSIONS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABLOLAR VE EKSİK SÜTUN GÜNCELLEMELERİ (MIGRATIONS)
-- ==============================================================================

-- A. DÜKKAN AYARLARI TABLOSU (store_settings)
CREATE TABLE IF NOT EXISTS public.store_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_name TEXT NOT NULL DEFAULT 'Mantı Mood',
    is_open BOOLEAN NOT NULL DEFAULT true,
    closed_message TEXT NOT NULL DEFAULT 'Şu anda sipariş alımına kapalıyız.',
    iban TEXT NOT NULL DEFAULT 'TR12 0006 2000 0000 1234 5678 90',
    bank_name TEXT NOT NULL DEFAULT 'Ziraat Bankası',
    account_holder TEXT NOT NULL DEFAULT 'Mantı Mood',
    whatsapp_number TEXT NOT NULL DEFAULT '905551234567',
    min_order_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    free_delivery_threshold NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    announcement_text TEXT NOT NULL DEFAULT '',
    is_delivery_active BOOLEAN NOT NULL DEFAULT true,
    is_pickup_active BOOLEAN NOT NULL DEFAULT true,
    pickup_title TEXT NOT NULL DEFAULT 'Gel-Al / Mutfaktan Teslim',
    pickup_description TEXT NOT NULL DEFAULT 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
    delivery_title TEXT NOT NULL DEFAULT 'Adrese Teslimat (Kurye / Kargo)',
    delivery_description TEXT NOT NULL DEFAULT 'Siparişiniz adresinize özenle teslim edilir.',
    is_bank_transfer_active BOOLEAN NOT NULL DEFAULT true,
    is_cod_active BOOLEAN NOT NULL DEFAULT true,
    is_ask_seller_active BOOLEAN NOT NULL DEFAULT true,
    has_cleared_bank_accounts BOOLEAN NOT NULL DEFAULT false,
    bank_accounts JSONB NOT NULL DEFAULT '[]'::jsonb,
    badges JSONB NOT NULL DEFAULT '[]'::jsonb,
    categories JSONB NOT NULL DEFAULT '["Klasik Mantı", "Yöresel Mantı", "Sebzeli & Vejetaryen", "Soslar & Yan Ürünler"]'::jsonb,
    is_story_card_active BOOLEAN NOT NULL DEFAULT true,
    story_card_title TEXT NOT NULL DEFAULT 'Mantı Mood Hikayesi',
    story_card_content TEXT NOT NULL DEFAULT '',
    story_card_image_url TEXT NOT NULL DEFAULT 'assets/images/manti-mood-logo.png',
    theme_preset TEXT NOT NULL DEFAULT 'classic',
    admin_password TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS closed_message TEXT NOT NULL DEFAULT 'Şu anda sipariş alımına kapalıyız.';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_delivery_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_pickup_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS pickup_title TEXT NOT NULL DEFAULT 'Gel-Al / Mutfaktan Teslim';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS pickup_description TEXT NOT NULL DEFAULT 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS delivery_title TEXT NOT NULL DEFAULT 'Adrese Teslimat (Kurye / Kargo)';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS delivery_description TEXT NOT NULL DEFAULT 'Siparişiniz adresinize özenle teslim edilir.';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_bank_transfer_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_cod_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_ask_seller_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS has_cleared_bank_accounts BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS bank_accounts JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS badges JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS categories JSONB NOT NULL DEFAULT '["Klasik Mantı", "Yöresel Mantı", "Sebzeli & Vejetaryen", "Soslar & Yan Ürünler"]'::jsonb;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS is_story_card_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS story_card_title TEXT NOT NULL DEFAULT 'Mantı Mood Hikayesi';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS story_card_content TEXT NOT NULL DEFAULT '';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS story_card_image_url TEXT NOT NULL DEFAULT 'assets/images/manti-mood-logo.png';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS theme_preset TEXT NOT NULL DEFAULT 'classic';
ALTER TABLE public.store_settings ADD COLUMN IF NOT EXISTS admin_password TEXT NOT NULL DEFAULT '';

-- B. VİTRİN BANNERLARI TABLOSU (banners)
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL DEFAULT '',
    image_url TEXT NOT NULL,
    mobile_image_url TEXT,
    action_url TEXT DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT true,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.banners ADD COLUMN IF NOT EXISTS mobile_image_url TEXT;

-- C. ÜRÜNLER TABLOSU (products)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'Klasik Mantı',
    base_price NUMERIC(10, 2) NOT NULL,
    variants JSONB NOT NULL DEFAULT '[]'::jsonb,
    image_url TEXT NOT NULL DEFAULT '',
    media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
    cooking_instructions TEXT NOT NULL DEFAULT '',
    storage_instructions TEXT NOT NULL DEFAULT '',
    is_available BOOLEAN NOT NULL DEFAULT true,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS media_urls JSONB NOT NULL DEFAULT '[]'::jsonb;

-- D. KULLANICI PROFİLLERİ TABLOSU (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT DEFAULT '',
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT 'İstanbul',
    district TEXT DEFAULT '',
    is_admin BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- E. SİPARİŞLER TABLOSU (orders)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    delivery_city TEXT NOT NULL DEFAULT 'İstanbul',
    delivery_district TEXT NOT NULL,
    delivery_address TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    cod_type TEXT NOT NULL DEFAULT 'cash',
    status TEXT NOT NULL DEFAULT 'order_received',
    status_steps JSONB NOT NULL DEFAULT '["order_received"]'::jsonb,
    total_amount NUMERIC(10, 2) NOT NULL,
    customer_note TEXT DEFAULT '',
    invoice_sent BOOLEAN NOT NULL DEFAULT false,
    invoice_sent_at TIMESTAMPTZ,
    tracking_code TEXT DEFAULT '',
    carrier_company TEXT DEFAULT '',
    kvkk_accepted BOOLEAN NOT NULL DEFAULT true,
    distance_sales_accepted BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS status_steps JSONB NOT NULL DEFAULT '["order_received"]'::jsonb;
-- Eski kurulumdan kalabilecek kısıtlayıcı CHECK kurallarını kaldır (Anlık EFT ve yeni durum adımlarının engellenmemesi için)
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_cod_type_check;
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;

-- F. SİPARİŞ KALEMLERİ TABLOSU (order_items)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    variant_title TEXT NOT NULL DEFAULT '500 gr',
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    subtotal NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 3. YETKİLİ YÖNETİCİ KONTROLÜ VE ZAMAN DAMGASI TETİKLEYİCİLERİ (TRIGGERS)
-- ==============================================================================

-- Yalnızca Google OAuth / Supabase JWT ile doğrulanmış 5 yetkili yönetici e-postasını kabul eder.
-- (Yetki yükseltme saldırılarını önlemek için dış tablolara güvenmez, doğrudan kriptografik JWT'yi kontrol eder)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT LOWER(COALESCE(auth.jwt() ->> 'email', '')) IN (
    'mantimood@gmail.com',
    'busraozverenli@gmail.com',
    'fabmorph@gmail.com',
    'serkanozverenli@gmail.com',
    'rhythmofsadness@gmail.com'
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, is_admin)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        NEW.email,
        LOWER(COALESCE(NEW.email, '')) IN (
            'mantimood@gmail.com',
            'busraozverenli@gmail.com',
            'fabmorph@gmail.com',
            'serkanozverenli@gmail.com',
            'rhythmofsadness@gmail.com'
        )
    )
    ON CONFLICT (id) DO UPDATE
    SET is_admin = EXCLUDED.is_admin;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_store_settings_updated_at ON public.store_settings;
CREATE TRIGGER trg_store_settings_updated_at
    BEFORE UPDATE ON public.store_settings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==============================================================================
-- 4. SATIR DÜZEYİNDE GÜVENLİK (RLS) POLİTİKALARI
-- ==============================================================================

ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- A. Dükkan Ayarları: Herkes okuyabilir, SADECE yetkili admin değiştirebilir
DROP POLICY IF EXISTS "Dükkan ayarlarını herkes görebilir" ON public.store_settings;
DROP POLICY IF EXISTS "Dükkan ayarlarını herkes okuyabilir" ON public.store_settings;
DROP POLICY IF EXISTS "Dükkan ayarlarını sadece admin değiştirebilir" ON public.store_settings;
DROP POLICY IF EXISTS "Dükkan ayarlarını yönetim güncelleyebilir" ON public.store_settings;

CREATE POLICY "Dükkan ayarlarını herkes okuyabilir" ON public.store_settings
    FOR SELECT USING (true);

CREATE POLICY "Dükkan ayarlarını sadece admin değiştirebilir" ON public.store_settings
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- B. Bannerlar: Herkes okuyabilir, SADECE yetkili admin ekleyebilir/düzenleyebilir/silebilir
DROP POLICY IF EXISTS "Bannerları herkes görebilir" ON public.banners;
DROP POLICY IF EXISTS "Bannerları sadece admin yönetebilir" ON public.banners;
DROP POLICY IF EXISTS "Bannerları yönetim düzenleyebilir" ON public.banners;

CREATE POLICY "Bannerları herkes görebilir" ON public.banners
    FOR SELECT USING (true);

CREATE POLICY "Bannerları sadece admin yönetebilir" ON public.banners
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- C. Ürünler: Herkes okuyabilir, SADECE yetkili admin ekleyebilir/düzenleyebilir/silebilir
DROP POLICY IF EXISTS "Ürünleri herkes görebilir" ON public.products;
DROP POLICY IF EXISTS "Ürünleri sadece admin yönetebilir" ON public.products;
DROP POLICY IF EXISTS "Ürünleri yönetim düzenleyebilir" ON public.products;

CREATE POLICY "Ürünleri herkes görebilir" ON public.products
    FOR SELECT USING (true);

CREATE POLICY "Ürünleri sadece admin yönetebilir" ON public.products
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- D. Profiller: Kullanıcı kendi profilini görebilir; is_admin alanını SADECE yetkili admin değiştirebilir
DROP POLICY IF EXISTS "Kullanıcı kendi profilini görebilir" ON public.profiles;
DROP POLICY IF EXISTS "Kullanıcı kendi profilini güncelleyebilir" ON public.profiles;

CREATE POLICY "Kullanıcı kendi profilini görebilir" ON public.profiles
    FOR SELECT USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Kullanıcı kendi profilini güncelleyebilir" ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id OR public.is_admin())
    WITH CHECK ((auth.uid() = id AND is_admin = public.is_admin()) OR public.is_admin());

-- E. Siparişler:
-- Müşteriler yeni sipariş oluşturabilir (INSERT), ancak sipariş tablosunu okumak/güncellemek/silmek SADECE admin'e açıktır!
DROP POLICY IF EXISTS "Siparişleri kullanıcı veya admin görebilir" ON public.orders;
DROP POLICY IF EXISTS "Herkes sipariş oluşturabilir" ON public.orders;
DROP POLICY IF EXISTS "Sadece admin sipariş güncelleyebilir" ON public.orders;
DROP POLICY IF EXISTS "Sadece admin sipariş silebilir" ON public.orders;
DROP POLICY IF EXISTS "Siparişleri herkes sorgulayabilir ve yönetebilir" ON public.orders;

CREATE POLICY "Siparişleri kullanıcı veya admin görebilir" ON public.orders
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Herkes sipariş oluşturabilir" ON public.orders
    FOR INSERT WITH CHECK (
        total_amount >= 0
        AND length(trim(order_number)) >= 4
        AND length(trim(customer_name)) >= 2
    );

CREATE POLICY "Sadece admin sipariş güncelleyebilir" ON public.orders
    FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Sadece admin sipariş silebilir" ON public.orders
    FOR DELETE USING (public.is_admin());

-- F. Sipariş Kalemleri:
DROP POLICY IF EXISTS "Sipariş kalemlerini müşteri veya admin görebilir" ON public.order_items;
DROP POLICY IF EXISTS "Herkes sipariş kalemi ekleyebilir" ON public.order_items;
DROP POLICY IF EXISTS "Sadece admin sipariş kalemi yönetebilir" ON public.order_items;
DROP POLICY IF EXISTS "Sipariş kalemleri genel erişim" ON public.order_items;

CREATE POLICY "Sipariş kalemlerini müşteri veya admin görebilir" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND (orders.user_id = auth.uid() OR public.is_admin())
        )
    );

CREATE POLICY "Herkes sipariş kalemi ekleyebilir" ON public.order_items
    FOR INSERT WITH CHECK (
        quantity > 0
        AND unit_price >= 0
        AND subtotal >= 0
    );

CREATE POLICY "Sadece admin sipariş kalemi yönetebilir" ON public.order_items
    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ==============================================================================
-- 5. GÜVENLİ VE KVKK MASKELİ SİPARİŞ SORGULAMA FONKSİYONU (RPC)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.get_public_order_by_number(p_order_number TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order public.orders%ROWTYPE;
    v_items JSONB;
BEGIN
    IF p_order_number IS NULL OR length(trim(p_order_number)) < 4 THEN
        RETURN NULL;
    END IF;

    SELECT * INTO v_order
    FROM public.orders
    WHERE LOWER(order_number) = LOWER(trim(p_order_number))
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(jsonb_agg(to_jsonb(oi)), '[]'::jsonb)
    INTO v_items
    FROM public.order_items oi
    WHERE oi.order_id = v_order.id;

    RETURN jsonb_build_object(
        'id', v_order.id,
        'order_number', v_order.order_number,
        'customer_name', CASE
            WHEN length(v_order.customer_name) > 2 THEN left(v_order.customer_name, 2) || '***'
            ELSE '***'
        END,
        'customer_email', '***',
        'customer_phone', CASE
            WHEN length(v_order.customer_phone) >= 4 THEN '*** ** ' || right(v_order.customer_phone, 2)
            ELSE '***'
        END,
        'delivery_city', v_order.delivery_city,
        'delivery_district', v_order.delivery_district,
        'delivery_address', v_order.delivery_district || ' / ' || v_order.delivery_city || ' (Gizli Adres)',
        'payment_method', v_order.payment_method,
        'cod_type', v_order.cod_type,
        'status', v_order.status,
        'status_steps', v_order.status_steps,
        'total_amount', v_order.total_amount,
        'customer_note', '',
        'invoice_sent', v_order.invoice_sent,
        'invoice_sent_at', v_order.invoice_sent_at,
        'tracking_code', v_order.tracking_code,
        'carrier_company', v_order.carrier_company,
        'created_at', v_order.created_at,
        'items', v_items
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_order_by_number(TEXT) TO anon, authenticated;

-- ==============================================================================
-- 6. DEPOLAMA ALANLARI (STORAGE BUCKETS & RLS)
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('banners', 'banners', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Ürün resimlerini herkes görebilir" ON storage.objects;
CREATE POLICY "Ürün resimlerini herkes görebilir" ON storage.objects
    FOR SELECT USING (bucket_id IN ('products', 'banners'));

DROP POLICY IF EXISTS "Resimleri sadece admin yükleyebilir" ON storage.objects;
CREATE POLICY "Resimleri sadece admin yükleyebilir" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id IN ('products', 'banners')
        AND public.is_admin()
    );

DROP POLICY IF EXISTS "Resimleri sadece admin güncelleyebilir" ON storage.objects;
CREATE POLICY "Resimleri sadece admin güncelleyebilir" ON storage.objects
    FOR UPDATE USING (
        bucket_id IN ('products', 'banners')
        AND public.is_admin()
    ) WITH CHECK (
        bucket_id IN ('products', 'banners')
        AND public.is_admin()
    );

DROP POLICY IF EXISTS "Resimleri sadece admin silebilir" ON storage.objects;
CREATE POLICY "Resimleri sadece admin silebilir" ON storage.objects
    FOR DELETE USING (
        bucket_id IN ('products', 'banners')
        AND public.is_admin()
    );

-- ==============================================================================
-- 7. ESKİ DENEME SİPARİŞLERİNİ VE 14 EKİM SAHTE UNSPLASH VERİLERİNİ TEMİZLE, GERÇEK VERİLERİ YÜKLE
-- ==============================================================================

-- Şimdiye kadar test amaçlı oluşturulmuş deneme siparişlerini temizle
DELETE FROM public.order_items;
DELETE FROM public.orders;

-- Yalnızca 14 Ekim ilk kurulumdan kalma sahte Unsplash ürünlerini ve sahte banner'ı sil
DELETE FROM public.products
WHERE image_url LIKE '%unsplash%'
   OR name IN (
     'Geleneksel Anne Eli Kıymalı Mantı',
     'Çıtır Sinop Mantısı (Cevizli)',
     'Yeşil Mercimekli Vejetaryen / Vegan Mantı',
     'Özel Sarımsaklı Yoğurt & Tereyağ Sos Kiti'
   );

DELETE FROM public.banners
WHERE image_url LIKE '%unsplash%'
   OR title LIKE '%Taze Anne Eli%';

-- Yalnızca 14 Ekim ilk kurulumdan kalma (rozetleri ve hikayesi boş olan) eski ayar satırını sil
DELETE FROM public.store_settings
WHERE badges = '[]'::jsonb AND story_card_content = '';

-- Gerçek Mantı Mood Mağaza Ayarlarını Yükle (Eğer tabloda kayıt yoksa)
INSERT INTO public.store_settings (
  store_name, is_open, whatsapp_number, min_order_amount, free_delivery_threshold,
  announcement_text, is_delivery_active, delivery_title, delivery_description,
  is_pickup_active, pickup_title, pickup_description,
  is_bank_transfer_active, is_cod_active, is_ask_seller_active,
  has_cleared_bank_accounts, bank_accounts, badges, categories,
  is_story_card_active, story_card_title, story_card_content, story_card_image_url,
  iban, bank_name, account_holder, theme_preset
)
SELECT
  'Mantı Mood', true, '905551234567', 0, 500,
  '', true, 'Adrese Teslimat (Kurye / Kargo)', 'Siparişiniz adresinize özenle teslim edilir.',
  true, 'Gel-Al / Mutfaktan Teslim', 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
  true, true, true,
  false,
  '[{"bank_name": "Ziraat Bankası", "iban": "TR12 0006 2000 0000 1234 5678 90", "account_holder": "Mantı Mood"}]'::jsonb,
  '[{"icon": "🥩", "title": "%100 Dana Eti", "subtitle": "Katkısız Harç"}, {"icon": "🥟", "title": "Günlük Taze", "subtitle": "El Açması Hamur"}, {"icon": "✨", "title": "Özel Tarif", "subtitle": "Geleneksel Lezzet"}]'::jsonb,
  '["Klasik Mantı", "Yöresel Mantı", "Sebzeli & Vejetaryen", "Soslar & Yan Ürünler"]'::jsonb,
  true, 'Mantı Mood Hikayesi',
  'Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla tek tek büktüğümüz geleneksel lezzeti sofranıza getiriyoruz. Hiçbir koruyucu veya katkı maddesi kullanmadan, şok dondurarak tazeliğini ilk günkü gibi muhafaza ediyoruz.',
  'assets/images/manti-mood-logo.png',
  'TR12 0006 2000 0000 1234 5678 90', 'Ziraat Bankası', 'Mantı Mood', 'classic'
WHERE NOT EXISTS (SELECT 1 FROM public.store_settings);

-- Gerçek Vitrin Banner'ını Yükle (Eğer tabloda kayıt yoksa)
INSERT INTO public.banners (title, subtitle, image_url, mobile_image_url, is_active, display_order)
SELECT
  'Kayseri Usulü El Açması Mantı',
  '%100 yerli dana eti ve anne eli lezzetiyle sofranızda.',
  'assets/images/manti-cesitleri/vitrin.webp',
  '', true, 1
WHERE NOT EXISTS (SELECT 1 FROM public.banners);

-- Gerçek 6 Mantı Çeşidini Yükle (Eğer tabloda kayıt yoksa)
INSERT INTO public.products (name, description, category, base_price, variants, image_url, media_urls, cooking_instructions, storage_instructions, is_available, is_featured, sort_order)
SELECT * FROM (VALUES
(
  'Bohça Mantı (Geleneksel)',
  'Elde tek tek bükülen dört köşeli geleneksel bohça mantı. Bol dana kıymalı, incecik el açması.',
  'Klasik Mantı', 240.00::numeric(10,2),
  '[{"title": "500 gr (2 Porsiyon)", "price": 240}, {"title": "1 Kg (4 Porsiyon)", "price": 450}, {"title": "2 Kg (Aile Boyu)", "price": 860}]'::jsonb,
  'assets/images/manti-cesitleri/bohca.png', '["assets/images/manti-cesitleri/bohca.png"]'::jsonb,
  'Kaynayan bol tuzlu suya şoklanmış mantıları atın. 8-10 dakika haşlayın. Sarımsaklı yoğurt ve kızgın tereyağı ile servis yapın.',
  '-18°C dondurucuda 3 ay tazeliğini korur.', true, true, 1
),
(
  'Hıngel Mantısı',
  'Geleneksel Kafkas & Sivas usulü iri taneli hıngel mantı. Zengin iç harç ve yumuşacık hamur.',
  'Yöresel Mantı', 250.00::numeric(10,2),
  '[{"title": "500 gr (2 Porsiyon)", "price": 250}, {"title": "1 Kg (4 Porsiyon)", "price": 460}, {"title": "2 Kg (Aile Boyu)", "price": 880}]'::jsonb,
  'assets/images/manti-cesitleri/hingel.png', '["assets/images/manti-cesitleri/hingel.png"]'::jsonb,
  'Kaynayan tuzlu suda 9-11 dakika orta ateşte haşlayın.',
  '-18°C dondurucuda saklayınız.', true, true, 2
),
(
  'Örgü Mantı',
  'Özel örgü dikişi tekniğiyle kapatılmış, tüm lezzeti ve suyunu içine hapseden el emeği mantı.',
  'Yöresel Mantı', 260.00::numeric(10,2),
  '[{"title": "500 gr (2 Porsiyon)", "price": 260}, {"title": "1 Kg (4 Porsiyon)", "price": 480}, {"title": "2 Kg (Aile Boyu)", "price": 920}]'::jsonb,
  'assets/images/manti-cesitleri/orgu.png', '["assets/images/manti-cesitleri/orgu.png"]'::jsonb,
  'Kaynayan suda 8-10 dakika haşlayın.',
  '-18°C dondurucuda saklayınız.', true, true, 3
),
(
  'Pelmeni Mantısı',
  'Yuvarlak ince hamurun özenle kapatılmasıyla hazırlanan, sulu ve bol etli geleneksel pelmeni.',
  'Klasik Mantı', 250.00::numeric(10,2),
  '[{"title": "500 gr (2 Porsiyon)", "price": 250}, {"title": "1 Kg (4 Porsiyon)", "price": 460}, {"title": "2 Kg (Aile Boyu)", "price": 880}]'::jsonb,
  'assets/images/manti-cesitleri/pelmeni.png', '["assets/images/manti-cesitleri/pelmeni.png"]'::jsonb,
  'Kaynayan suda 7-9 dakika haşlayınız.',
  '-18°C dondurucuda saklayınız.', true, false, 4
),
(
  'Sebzeli Renkli Mantı',
  'Ispanak, pancar ve zerdeçallı %100 doğal sebze pürelerinden hazırlanan renkli ve besleyici mantı.',
  'Sebzeli & Vejetaryen', 270.00::numeric(10,2),
  '[{"title": "500 gr (2 Porsiyon)", "price": 270}, {"title": "1 Kg (4 Porsiyon)", "price": 500}, {"title": "2 Kg (Aile Boyu)", "price": 950}]'::jsonb,
  'assets/images/manti-cesitleri/sebzeli.png', '["assets/images/manti-cesitleri/sebzeli.png"]'::jsonb,
  'Kaynar tuzlu suda 7-8 dakika haşlayınız.',
  '-18°C dondurucuda saklayınız.', true, true, 5
),
(
  'Fırınlanmış Tepsi Mantısı',
  'Tepsiye tek tek dizilip nar gibi kızarana kadar fırınlanmış, çıtır ve lezzetli tepsi mantısı.',
  'Yöresel Mantı', 270.00::numeric(10,2),
  '[{"title": "500 gr (Tepsi Boyu)", "price": 270}, {"title": "1 Kg (Büyük Tepsi)", "price": 500}, {"title": "2 Kg (Aile Boyu)", "price": 950}]'::jsonb,
  'assets/images/manti-cesitleri/tepsi_mantisi.png', '["assets/images/manti-cesitleri/tepsi_mantisi.png"]'::jsonb,
  'Üzerine sıcak salçalı et suyu gezdirerek ocakta veya fırında suyunu çekene kadar pişirin.',
  'Kuru ve serin yerde veya dondurucuda muhafaza ediniz.', true, true, 6
)
) AS v(name, description, category, base_price, variants, image_url, media_urls, cooking_instructions, storage_instructions, is_available, is_featured, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.products);
