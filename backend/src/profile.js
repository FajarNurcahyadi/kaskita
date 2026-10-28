// Profil, keamanan (kata sandi, PIN, 2 langkah), riwayat login, hapus akun.
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const makeAuth = require('./auth');

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads');

const NEW_COLUMNS = {
  nik: 'VARCHAR(16) NULL',
  birth_date: 'DATE NULL',
  phone: 'VARCHAR(20) NULL',
  job_title: 'VARCHAR(50) NULL',
  business_name: 'VARCHAR(80) NULL',
  pin_hash: 'VARCHAR(100) NULL',
  biometric_enabled: 'TINYINT(1) NOT NULL DEFAULT 0',
  two_factor_enabled: 'TINYINT(1) NOT NULL DEFAULT 0',
};

const isoDate = (d) => d.toISOString().slice(0, 10);
const validIso = (s) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && isoDate(d) === s;
};

module.exports = function register(app, pool, JWT_SECRET, wrap) {
  const auth = makeAuth(JWT_SECRET);

  async function ensureSchema() {
    const [cols] = await pool.query(
      `SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'`,
    );
    const have = new Set(cols.map((c) => c.name));
    for (const [name, def] of Object.entries(NEW_COLUMNS)) {
      if (!have.has(name)) await pool.query(`ALTER TABLE users ADD COLUMN ${name} ${def}`);
    }
    // OTP untuk login dua langkah
    await pool.query(`ALTER TABLE otps MODIFY purpose ENUM('register','reset','login') NOT NULL`);
    await pool.query(`CREATE TABLE IF NOT EXISTS login_history (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      ip VARCHAR(64) NOT NULL DEFAULT '',
      user_agent VARCHAR(255) NOT NULL DEFAULT '',
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_login_user (user_id, created_at),
      CONSTRAINT fk_login_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
  }

  const PROFILE_SELECT = `SELECT id, name, email, nik, DATE_FORMAT(birth_date, '%Y-%m-%d') AS birth_date,
      phone, job_title, business_name, (pin_hash IS NOT NULL) AS has_pin,
      biometric_enabled, two_factor_enabled FROM users WHERE id = ?`;

  const shape = (u) => ({
    id: u.id,
    name: u.name,
    email: u.email,
    nik: u.nik || '',
    birthDate: u.birth_date || '',
    phone: u.phone || '',
    jobTitle: u.job_title || '',
    businessName: u.business_name || '',
    hasPin: Number(u.has_pin) === 1,
    biometric: Number(u.biometric_enabled) === 1,
    twoFactor: Number(u.two_factor_enabled) === 1,
  });

  const loadProfile = async (id) => {
    const [rows] = await pool.query(PROFILE_SELECT, [id]);
    return rows.length ? shape(rows[0]) : null;
  };

  app.get('/profile', auth, wrap(async (req, res) => {
    const p = await loadProfile(req.userId);
    if (!p) return res.status(404).json({ message: 'Akun tidak ditemukan' });
    res.json(p);
  }));

  // Ubah data diri. Kirim hanya field yang diubah. String kosong = hapus (kecuali nama).
  app.put('/profile', auth, wrap(async (req, res) => {
    const b = req.body || {};
    const set = {};

    if ('name' in b) {
      const v = String(b.name || '').trim();
      if (!v || v.length > 100) return res.status(400).json({ message: 'Nama wajib diisi (maks. 100 karakter)' });
      set.name = v;
    }
    if ('nik' in b) {
      const v = String(b.nik || '').replace(/\s+/g, '');
      if (v && !/^\d{16}$/.test(v)) return res.status(400).json({ message: 'NIK harus 16 digit angka' });
      set.nik = v || null;
    }
    if ('birthDate' in b) {
      const v = String(b.birthDate || '');
      if (v) {
        if (!validIso(v) || v < '1900-01-01' || v > isoDate(new Date())) {
          return res.status(400).json({ message: 'Tanggal lahir tidak valid' });
        }
      }
      set.birth_date = v || null;
    }
    if ('phone' in b) {
      const v = String(b.phone || '').replace(/[\s-]/g, '');
      if (v && !/^\+?\d{8,15}$/.test(v)) return res.status(400).json({ message: 'Nomor HP tidak valid' });
      set.phone = v || null;
    }
    if ('jobTitle' in b) {
      const v = String(b.jobTitle || '').trim();
      if (v.length > 50) return res.status(400).json({ message: 'Jabatan maksimal 50 karakter' });
      set.job_title = v || null;
    }
    if ('businessName' in b) {
      const v = String(b.businessName || '').trim();
      if (v.length > 80) return res.status(400).json({ message: 'Nama usaha maksimal 80 karakter' });
      set.business_name = v || null;
    }

    const keys = Object.keys(set);
    if (!keys.length) return res.status(400).json({ message: 'Tidak ada data yang diubah' });
    await pool.query(`UPDATE users SET ${keys.map((k) => `${k} = ?`).join(', ')} WHERE id = ?`, [...keys.map((k) => set[k]), req.userId]);
    res.json(await loadProfile(req.userId));
  }));

  app.post('/profile/password', auth, wrap(async (req, res) => {
    const current = String(req.body.currentPassword || '');
    const next = String(req.body.newPassword || '');
    if (next.length < 8) return res.status(400).json({ message: 'Kata sandi baru minimal 8 karakter' });
    const [rows] = await pool.query('SELECT password_hash FROM users WHERE id = ?', [req.userId]);
    if (!rows.length || !(await bcrypt.compare(current, rows[0].password_hash))) {
      return res.status(400).json({ message: 'Kata sandi saat ini salah' });
    }
    await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [await bcrypt.hash(next, 10), req.userId]);
    res.json({ message: 'Kata sandi berhasil diubah' });
  }));

  // Atur / ubah PIN 6 digit. Kalau sudah punya PIN, wajib kirim currentPin.
  app.post('/profile/pin', auth, wrap(async (req, res) => {
    const pin = String(req.body.pin || '');
    if (!/^\d{6}$/.test(pin)) return res.status(400).json({ message: 'PIN harus 6 digit angka' });
    const [rows] = await pool.query('SELECT pin_hash FROM users WHERE id = ?', [req.userId]);
    if (!rows.length) return res.status(404).json({ message: 'Akun tidak ditemukan' });
    if (rows[0].pin_hash && !(await bcrypt.compare(String(req.body.currentPin || ''), rows[0].pin_hash))) {
      return res.status(400).json({ message: 'PIN saat ini salah' });
    }
    await pool.query('UPDATE users SET pin_hash = ? WHERE id = ?', [await bcrypt.hash(pin, 10), req.userId]);
    res.json({ message: 'PIN tersimpan' });
  }));

  // Toggle keamanan. twoFactor = kode OTP lewat email setiap login.
  app.put('/profile/security', auth, wrap(async (req, res) => {
    const set = [];
    const vals = [];
    if (typeof req.body.biometric === 'boolean') { set.push('biometric_enabled = ?'); vals.push(req.body.biometric ? 1 : 0); }
    if (typeof req.body.twoFactor === 'boolean') { set.push('two_factor_enabled = ?'); vals.push(req.body.twoFactor ? 1 : 0); }
    if (!set.length) return res.status(400).json({ message: 'Tidak ada pengaturan yang diubah' });
    await pool.query(`UPDATE users SET ${set.join(', ')} WHERE id = ?`, [...vals, req.userId]);
    res.json(await loadProfile(req.userId));
  }));

  app.get('/profile/logins', auth, wrap(async (req, res) => {
    const [rows] = await pool.query(
      'SELECT id, ip, user_agent, created_at FROM login_history WHERE user_id = ? ORDER BY created_at DESC, id DESC LIMIT 20',
      [req.userId],
    );
    res.json({ items: rows.map((r) => ({ id: r.id, ip: r.ip, userAgent: r.user_agent, at: r.created_at })) });
  }));

  // Hapus akun permanen. Wajib kata sandi (+ PIN kalau sudah diatur).
  app.post('/profile/delete', auth, wrap(async (req, res) => {
    const [rows] = await pool.query('SELECT email, password_hash, pin_hash FROM users WHERE id = ?', [req.userId]);
    if (!rows.length) return res.status(404).json({ message: 'Akun tidak ditemukan' });
    const u = rows[0];
    if (!(await bcrypt.compare(String(req.body.password || ''), u.password_hash))) {
      return res.status(400).json({ message: 'Kata sandi salah' });
    }
    if (u.pin_hash && !(await bcrypt.compare(String(req.body.pin || ''), u.pin_hash))) {
      return res.status(400).json({ message: 'PIN salah' });
    }
    const [imgs] = await pool.query('SELECT image FROM posts WHERE user_id = ? AND image IS NOT NULL', [req.userId]);
    await pool.query('DELETE FROM users WHERE id = ?', [req.userId]); // transaksi, posting, like, komentar ikut terhapus
    await pool.query('DELETE FROM otps WHERE email = ?', [u.email]);
    imgs.forEach((i) => fs.unlink(path.join(UPLOAD_DIR, path.basename(i.image)), () => {}));
    res.json({ message: 'Akun dihapus' });
  }));

  return { ensureSchema };
};
