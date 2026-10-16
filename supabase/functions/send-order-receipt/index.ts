import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import nodemailer from "npm:nodemailer@6.9.10";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface OrderItem {
  productName: string;
  variantTitle?: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

interface OrderReceiptRequest {
  orderNumber: string;
  orderDate?: string;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  deliveryCity?: string;
  deliveryDistrict?: string;
  deliveryAddress?: string;
  paymentMethod?: string;
  paymentLabel?: string;
  codType?: string;
  carrierCompany?: string;
  trackingCode?: string;
  totalAmount: number;
  customerNote?: string;
  items: OrderItem[];
  receiptImageBase64?: string;
}

serve(async (req) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: OrderReceiptRequest = await req.json();

    const {
      orderNumber,
      orderDate = "",
      customerName,
      customerEmail,
      customerPhone = "",
      deliveryAddress = "",
      paymentMethod = "",
      paymentLabel = "",
      codType = "",
      carrierCompany = "",
      trackingCode = "",
      totalAmount,
      customerNote = "",
      items = [],
      receiptImageBase64,
    } = body;

    if (!customerEmail || !customerEmail.includes("@")) {
      return new Response(
        JSON.stringify({ error: "Geçerli bir müşteri e-posta adresi bulunamadı." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Ödeme Yöntemini Dinamik Olarak Belirle
    let resolvedPaymentMethod = paymentLabel;
    if (!resolvedPaymentMethod) {
      if (paymentMethod === "cod" || paymentMethod.toLowerCase().includes("kapı")) {
        if (codType === "pos" || codType === "card") {
          resolvedPaymentMethod = "Kapıda Ödeme (Kredi Kartı / POS)";
        } else if (codType === "instant_eft") {
          resolvedPaymentMethod = "Kapıda Ödeme (Anlık Havale / EFT)";
        } else {
          resolvedPaymentMethod = "Kapıda Ödeme (Nakit)";
        }
      } else if (paymentMethod === "bank_transfer" || paymentMethod.toLowerCase().includes("havale")) {
        resolvedPaymentMethod = "Havale / EFT";
      } else {
        resolvedPaymentMethod = paymentMethod || "Belirtilmedi";
      }
    }

    // Siparişin asıl oluşturulma tarihi
    const resolvedDate = orderDate || new Date().toLocaleDateString("tr-TR");

    // SMTP Ayarlarını Oku
    const host = Deno.env.get("SMTP_HOST") || "smtp.gmail.com";
    const port = Number(Deno.env.get("SMTP_PORT") || "465");
    const user = Deno.env.get("SMTP_USER");
    const pass = Deno.env.get("SMTP_PASS");

    if (!user || !pass) {
      return new Response(
        JSON.stringify({ error: "SMTP_USER veya SMTP_PASS tanımlı değil." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });

    // Ürün Satırları
    const itemsHtml = items
      .map(
        (item) => `
        <tr>
          <td style="padding: 12px 0; border-bottom: 1px solid #f1f5f9;">
            <strong style="color: #1e293b; font-size: 13px;">${item.productName}</strong><br>
            <span style="font-size: 11px; color: #64748b;">${item.variantTitle || "Standart"}</span>
          </td>
          <td style="padding: 12px 0; border-bottom: 1px solid #f1f5f9; text-align: center; font-size: 13px; color: #475569;">
            ${item.quantity} adet
          </td>
          <td style="padding: 12px 0; border-bottom: 1px solid #f1f5f9; text-align: right; font-weight: 600; font-size: 13px; color: #1e293b;">
            ${Number(item.subtotal).toFixed(0)} ₺
          </td>
        </tr>
      `
      )
      .join("");

    // Eklenecek Dosyalar (Attachments) ve Görsel Bilgi Fişi
    const attachments: any[] = [];
    let imageSlipHtml = "";

    if (receiptImageBase64 && receiptImageBase64.length > 50) {
      const cleanBase64 = receiptImageBase64.replace(/^data:image\/[a-z]+;base64,/, "");
      attachments.push({
        filename: `manti_mood_bilgi_fisi_${orderNumber}.png`,
        content: cleanBase64,
        encoding: "base64",
        cid: "receipt_png_slip",
      });

      imageSlipHtml = `
      <div style="text-align: center; margin-bottom: 24px; padding: 12px; background: #f8fafc; border-radius: 14px; border: 1px dashed #cbd5e1;">
        <img src="cid:receipt_png_slip" alt="Mantı Mood Bilgi Fişi" style="max-width: 100%; height: auto; border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.08); display: block; margin: 0 auto; border: 1px solid #e2e8f0;" />
        <div style="margin-top: 12px; font-size: 12px; color: #64748b; font-weight: 500;">
          📎 <strong>Bilgi fişi görseli ayrıca e-postanın ekinde (.png) yer almaktadır.</strong> Dilediğiniz zaman cihazınıza indirebilirsiniz.
        </div>
      </div>
      `;
    }

    // HTML E-Posta Şablonu (Esnaf Muafiyeti ve Bilgi Fişi Standardı)
    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Mantı Mood - Sipariş Bilgi Fişi</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 20px; color: #1e293b;">
  <div style="max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
    
    <!-- Üst Başlık & Marka -->
    <div style="background: #991b1b; color: #ffffff; padding: 24px; text-align: center;">
      <h1 style="margin: 0; font-size: 22px; letter-spacing: 1.5px; font-weight: 800;">MANTI MOOD</h1>
      <p style="margin: 6px 0 0; font-size: 12px; opacity: 0.9;">El Açması Butik Ev Mantısı & Lezzetleri</p>
      <div style="display: inline-block; background: rgba(255,255,255,0.2); padding: 4px 14px; border-radius: 20px; font-size: 11px; font-weight: bold; margin-top: 10px; letter-spacing: 0.5px;">
        BİLGİ FİŞİ
      </div>
    </div>
    
    <div style="padding: 24px;">
      <!-- Sipariş No ve Tarih -->
      <table style="width: 100%; margin-bottom: 14px;">
        <tr>
          <td style="font-weight: 800; font-size: 14px; color: #991b1b;">Sipariş No: #${orderNumber}</td>
          <td style="text-align: right; font-size: 12px; color: #64748b;">${resolvedDate}</td>
        </tr>
      </table>

      ${imageSlipHtml}

      <!-- Müşteri & Teslimat Kartı -->
      <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px; margin-bottom: 20px; font-size: 12px; line-height: 1.7;">
        <div><strong style="color: #475569;">Alıcı Müşteri:</strong> <span style="font-weight: 600; color: #1e293b;">${customerName}</span></div>
        ${customerPhone ? `<div><strong style="color: #475569;">Telefon:</strong> ${customerPhone}</div>` : ""}
        ${deliveryAddress ? `<div><strong style="color: #475569;">Teslimat Adresi:</strong> ${deliveryAddress}</div>` : ""}
        <div><strong style="color: #475569;">Ödeme Şekli:</strong> <span style="font-weight: 600; color: #1e293b;">${resolvedPaymentMethod}</span></div>
        ${carrierCompany || trackingCode ? `<div><strong style="color: #475569;">Kargo / Kurye:</strong> ${carrierCompany || "Kurye"} ${trackingCode ? `(Takip: ${trackingCode})` : ""}</div>` : ""}
        ${customerNote ? `<div><strong style="color: #475569;">Müşteri Notu:</strong> <em>${customerNote}</em></div>` : ""}
      </div>

      <!-- Ürün Tablosu -->
      <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
        <thead>
          <tr>
            <th style="text-align: left; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px;">ÜRÜN & SEÇENEK</th>
            <th style="text-align: center; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px;">ADET</th>
            <th style="text-align: right; font-size: 11px; text-transform: uppercase; color: #64748b; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px;">TUTAR</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml}
        </tbody>
      </table>

      <!-- Toplam ve Ödeme Özeti -->
      <div style="margin-top: 20px; border-top: 2px dashed #cbd5e1; padding-top: 14px;">
        <table style="width: 100%; margin-bottom: 6px;">
          <tr>
            <td style="font-size: 12px; color: #64748b;">Ödeme Yöntemi:</td>
            <td style="font-size: 12px; font-weight: 600; text-align: right; color: #334155;">${resolvedPaymentMethod}</td>
          </tr>
        </table>
        <table style="width: 100%;">
          <tr>
            <td style="font-size: 15px; font-weight: 900; color: #991b1b;">GENEL TOPLAM:</td>
            <td style="font-size: 18px; font-weight: 900; color: #991b1b; text-align: right;">${Number(totalAmount).toFixed(0)} ₺</td>
          </tr>
        </table>
      </div>

      <!-- Yasal Esnaf Muafiyeti Uyarısı -->
      <div style="margin-top: 18px; padding: 10px 14px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 8px; font-size: 11px; color: #92400e; text-align: center; line-height: 1.4; font-weight: 500;">
        <strong>Önemli Uyarı!</strong> Esnaf Muafiyeti kapsamında olduğumuzdan bu belge fatura yerine geçmez. Sadece bilgilendirme amaçlıdır.
      </div>
    </div>

    <!-- Alt Teşekkür Mesajı -->
    <div style="text-align: center; font-size: 11px; color: #94a3b8; padding: 16px; background: #f8fafc; border-top: 1px solid #e2e8f0; line-height: 1.5; font-style: italic;">
      Mantı Mood butik ev lezzetlerini tercih ettiğiniz için teşekkür ederiz.<br>
      Afiyet olsun!
    </div>
  </div>
</body>
</html>
    `;

    await transporter.sendMail({
      from: `"Mantı Mood Sipariş" <${user}>`,
      to: customerEmail,
      subject: `Mantı Mood Sipariş Bilgi Fişiniz (#${orderNumber})`,
      html: htmlContent,
      attachments,
    });

    return new Response(
      JSON.stringify({ success: true, message: "Bilgi fişi e-postası başarıyla gönderildi." }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "E-posta gönderilirken bir hata oluştu." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
