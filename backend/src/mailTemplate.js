// Template email OTP bermerek KasKita (table + inline CSS biar aman di Gmail/Outlook).
const TEAL = '#008B8B';
const MINT = '#D1EBE6';

const COPY = {
  register: {
    subject: (code) => `${code} adalah kode verifikasi KasKita kamu`,
    title: 'Verifikasi Akun',
    intro: 'Selamat datang di KasKita! Masukkan kode di bawah ini di aplikasi untuk menyelesaikan pendaftaran.',
  },
  login: {
    subject: (code) => `${code} adalah kode masuk KasKita kamu`,
    title: 'Verifikasi Login',
    intro: 'Ada percobaan masuk ke akun KasKita-mu. Masukkan kode di bawah ini di aplikasi untuk menyelesaikan login.',
  },
  reset: {
    subject: (code) => `${code} adalah kode reset kata sandi KasKita`,
    title: 'Reset Kata Sandi',
    intro: 'Kami menerima permintaan untuk mengatur ulang kata sandi akunmu. Masukkan kode di bawah ini di aplikasi untuk melanjutkan.',
  },
};

function otpEmail(purpose, code, ttlMinutes) {
  const c = COPY[purpose] || COPY.register;
  const digits = String(code).replace(/\D/g, '').split('');

  const boxes = digits
    .map(
      (d) =>
        `<td style="padding:0 5px;"><div style="width:52px;height:60px;line-height:60px;text-align:center;` +
        `font-size:28px;font-weight:700;color:#000000;background:#ffffff;border:1px solid ${TEAL};` +
        `border-radius:8px;font-family:Arial,Helvetica,sans-serif;">${d}</div></td>`,
    )
    .join('');

  const html = `<!DOCTYPE html>
<html lang="id">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${c.title}</title></head>
<body style="margin:0;padding:0;background:${MINT};">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;">Kode kamu: ${digits.join('')}. Berlaku ${ttlMinutes} menit.</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${MINT};padding:32px 12px;">
    <tr><td align="center">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border-radius:20px;overflow:hidden;font-family:Arial,Helvetica,sans-serif;">
        <tr><td align="center" style="background:${TEAL};padding:28px 24px;">
          <div style="display:inline-block;background:#F8F6F0;border-radius:14px;padding:10px 22px;">
            <span style="font-size:26px;font-weight:800;letter-spacing:1px;color:#1B7569;">KASKITA</span>
          </div>
          <div style="margin-top:12px;font-size:13px;color:#ffffff;opacity:.9;">Rajut keuangan &bull; Rajut komunitas</div>
        </td></tr>
        <tr><td style="padding:32px 28px 8px 28px;">
          <h1 style="margin:0 0 12px 0;font-size:24px;color:#000000;">${c.title}</h1>
          <p style="margin:0;font-size:15px;line-height:1.6;color:#333333;">${c.intro}</p>
        </td></tr>
        <tr><td align="center" style="padding:24px 28px 8px 28px;">
          <table role="presentation" cellpadding="0" cellspacing="0"><tr>${boxes}</tr></table>
        </td></tr>
        <tr><td align="center" style="padding:8px 28px 4px 28px;">
          <p style="margin:12px 0 0 0;font-size:14px;color:${TEAL};font-weight:700;">Berlaku selama ${ttlMinutes} menit</p>
        </td></tr>
        <tr><td style="padding:20px 28px 32px 28px;">
          <p style="margin:0;font-size:13px;line-height:1.6;color:#666666;">
            Demi keamanan, jangan bagikan kode ini ke siapa pun, termasuk pihak yang mengaku dari KasKita.
            Kalau kamu tidak merasa memintanya, abaikan saja email ini.
          </p>
        </td></tr>
        <tr><td align="center" style="background:#F2F8F7;padding:16px 24px;">
          <p style="margin:0;font-size:12px;color:#888888;">&copy; ${new Date().getFullYear()} KasKita. Email ini dikirim otomatis, mohon tidak dibalas.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

  const text =
    `${c.title} - KasKita\n\n${c.intro}\n\nKode kamu: ${digits.join('')}\n` +
    `Berlaku selama ${ttlMinutes} menit.\n\n` +
    `Jangan bagikan kode ini ke siapa pun. Kalau kamu tidak merasa memintanya, abaikan email ini.`;

  return { subject: c.subject(digits.join('')), html, text };
}

module.exports = { otpEmail };
