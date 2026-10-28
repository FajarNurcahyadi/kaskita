const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');
const { otpEmail } = require('./mailTemplate');

const {
  PORT = 3000, DB_HOST = 'localhost', DB_PORT = 3306, DB_USER = 'root',
  DB_PASSWORD = '', DB_NAME = 'kaskita', JWT_SECRET = 'dev-secret',
  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM,
} = process.env;

const pool = mysql.createPool({
  host: DB_HOST, port: Number(DB_PORT), user: DB_USER, password: DB_PASSWORD,
  database: DB_NAME, waitForConnections: true, connectionLimit: 10,
});

const mailer = SMTP_HOST
  ? nodemailer.createTransport({
      host: SMTP_HOST, port: Number(SMTP_PORT || 587),
      auth: SMTP_USER ? { user: SMTP_USER, pass: SMTP_PASS } : undefined,
    })
  : null;

const OTP_TTL_MIN = 5;
const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const normEmail = (e) => String(e || '').trim().toLowerCase();

async function sendOtp(email, purpose) {
  const code = String(Math.floor(1000 + Math.random() * 9000));
  await pool.query('UPDATE otps SET used = 1 WHERE email = ? AND purpose = ? AND used = 0', [email, purpose]);
  await pool.query(
    'INSERT INTO otps (email, code, purpose, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))',
    [email, code, purpose, OTP_TTL_MIN],
  );
  if (mailer) {
    const { subject, html, text } = otpEmail(purpose, code, OTP_TTL_MIN);
    await mailer.sendMail({ from: SMTP_FROM, to: email, subject, html, text });
  } else {
    console.log(`[DEV OTP] ${purpose} -> ${email}: ${code}`);
  }
}

async function checkOtp(email, code, purpose) {
  const [rows] = await pool.query(
    'SELECT id FROM otps WHERE email = ? AND purpose = ? AND code = ? AND used = 0 AND expires_at > NOW() ORDER BY id DESC LIMIT 1',
    [email, purpose, String(code || '')],
  );
  if (!rows.length) return false;
  await pool.query('UPDATE otps SET used = 1 WHERE id = ?', [rows[0].id]);
  return true;
}

const signAuth = (u) => jwt.sign({ sub: u.id, email: u.email }, JWT_SECRET, { expiresIn: '7d' });
const wrap = (fn) => (req, res) => fn(req, res).catch((e) => {
  console.error(e);
  res.status(500).json({ message: 'Terjadi kesalahan pada server' });
});

const app = express();
app.use(cors());
app.use(express.json({ limit: '8mb' }));

const UPLOAD_DIR = process.env.UPLOAD_DIR || require('path').join(__dirname, '..', 'uploads');
require('fs').mkdirSync(UPLOAD_DIR, { recursive: true });
app.use('/uploads', express.static(UPLOAD_DIR));

async function recordLogin(userId, req) {
  try {
    await pool.query('INSERT INTO login_history (user_id, ip, user_agent) VALUES (?, ?, ?)', [
      userId, String(req.ip || '').slice(0, 64), String(req.headers['user-agent'] || '').slice(0, 255),
    ]);
  } catch (e) {
    console.error('Gagal mencatat riwayat login:', e.message);
  }
}

app.get('/health', (_, res) => res.json({ ok: true }));

// 1) Daftar -> kirim OTP
app.post('/auth/register', wrap(async (req, res) => {
  const name = String(req.body.name || '').trim();
  const email = normEmail(req.body.email);
  const password = String(req.body.password || '');
  if (!name) return res.status(400).json({ message: 'Nama wajib diisi' });
  if (!emailRe.test(email)) return res.status(400).json({ message: 'Format email tidak valid' });
  if (password.length < 8) return res.status(400).json({ message: 'Kata sandi minimal 8 karakter' });

  const [rows] = await pool.query('SELECT id, is_verified FROM users WHERE email = ?', [email]);
  const hash = await bcrypt.hash(password, 10);
  if (rows.length && rows[0].is_verified) return res.status(409).json({ message: 'Email sudah terdaftar' });
  if (rows.length) {
    await pool.query('UPDATE users SET name = ?, password_hash = ? WHERE id = ?', [name, hash, rows[0].id]);
  } else {
    await pool.query('INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)', [name, email, hash]);
  }
  await sendOtp(email, 'register');
  res.status(201).json({ message: 'Kode verifikasi dikirim', email });
}));

// 2) Verifikasi OTP pendaftaran
app.post('/auth/verify-otp', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  if (!(await checkOtp(email, req.body.code, 'register'))) {
    return res.status(400).json({ message: 'Kode salah atau sudah kedaluwarsa' });
  }
  await pool.query('UPDATE users SET is_verified = 1 WHERE email = ?', [email]);
  const [rows] = await pool.query('SELECT id, name, email FROM users WHERE email = ?', [email]);
  res.json({ message: 'Akun berhasil dibuat', token: signAuth(rows[0]), user: rows[0] });
}));

// 3) Kirim ulang OTP (register / reset)
app.post('/auth/resend-otp', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  const purpose = ['reset', 'login'].includes(req.body.purpose) ? req.body.purpose : 'register';
  const [rows] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (rows.length) await sendOtp(email, purpose);
  res.json({ message: 'Kode baru dikirim' });
}));

// 4) Login
app.post('/auth/login', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  const password = String(req.body.password || '');
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  if (!rows.length || !(await bcrypt.compare(password, rows[0].password_hash))) {
    return res.status(401).json({ message: 'Email atau kata sandi salah' });
  }
  if (!rows[0].is_verified) {
    await sendOtp(email, 'register');
    return res.status(403).json({ message: 'Akun belum diverifikasi', needsVerification: true, email });
  }
  if (rows[0].two_factor_enabled) {
    await sendOtp(email, 'login');
    return res.status(403).json({
      message: 'Masukkan kode verifikasi dua langkah yang dikirim ke email',
      needsTwoFactor: true,
      email,
    });
  }
  const u = { id: rows[0].id, name: rows[0].name, email: rows[0].email };
  await recordLogin(u.id, req);
  res.json({ token: signAuth(u), user: u });
}));

// 4b) Verifikasi OTP login dua langkah
app.post('/auth/verify-login-otp', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  if (!(await checkOtp(email, req.body.code, 'login'))) {
    return res.status(400).json({ message: 'Kode salah atau sudah kedaluwarsa' });
  }
  const [rows] = await pool.query('SELECT id, name, email FROM users WHERE email = ?', [email]);
  if (!rows.length) return res.status(404).json({ message: 'Akun tidak ditemukan' });
  await recordLogin(rows[0].id, req);
  res.json({ token: signAuth(rows[0]), user: rows[0] });
}));

// 5) Lupa password -> kirim OTP (selalu 200 supaya email tidak bisa ditebak)
app.post('/auth/forgot-password', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  if (!emailRe.test(email)) return res.status(400).json({ message: 'Format email tidak valid' });
  const [rows] = await pool.query('SELECT id FROM users WHERE email = ? AND is_verified = 1', [email]);
  if (rows.length) await sendOtp(email, 'reset');
  res.json({ message: 'Jika email terdaftar, kode sudah dikirim', email });
}));

// 6) Verifikasi OTP reset -> resetToken
app.post('/auth/verify-reset-otp', wrap(async (req, res) => {
  const email = normEmail(req.body.email);
  if (!(await checkOtp(email, req.body.code, 'reset'))) {
    return res.status(400).json({ message: 'Kode salah atau sudah kedaluwarsa' });
  }
  const resetToken = jwt.sign({ email, purpose: 'reset' }, JWT_SECRET, { expiresIn: '10m' });
  res.json({ resetToken });
}));

// 7) Set password baru
app.post('/auth/reset-password', wrap(async (req, res) => {
  const password = String(req.body.newPassword || '');
  if (password.length < 8) return res.status(400).json({ message: 'Kata sandi minimal 8 karakter' });
  let payload;
  try {
    payload = jwt.verify(String(req.body.resetToken || ''), JWT_SECRET);
    if (payload.purpose !== 'reset') throw new Error('bad purpose');
  } catch {
    return res.status(401).json({ message: 'Sesi reset kedaluwarsa, ulangi dari awal' });
  }
  await pool.query('UPDATE users SET password_hash = ? WHERE email = ?', [await bcrypt.hash(password, 10), payload.email]);
  res.json({ message: 'Kata sandi berhasil diubah' });
}));

const tx = require('./transactions')(app, pool, JWT_SECRET, wrap);
const community = require('./community')(app, pool, JWT_SECRET, wrap);
const profile = require('./profile')(app, pool, JWT_SECRET, wrap);
const targets = require('./targets')(app, pool, JWT_SECRET, wrap);

(async () => {
  await tx.ensureSchema();
  await community.ensureSchema();
  await profile.ensureSchema();
  await targets.ensureSchema();
  app.listen(Number(PORT), () => console.log(`KasKita API jalan di port ${PORT}`));
})().catch((e) => {
  console.error('Gagal menyiapkan skema database', e);
  process.exit(1);
});
