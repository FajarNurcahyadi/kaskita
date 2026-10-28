// Transaksi + dashboard. Semua endpoint butuh header: Authorization: Bearer <token>
const jwt = require('jsonwebtoken');

const EXPENSE_CATS = ['makanan', 'transportasi', 'tagihan', 'belanja', 'perbaikan', 'lainnya'];
const isoDate = (d) => d.toISOString().slice(0, 10);
const validIso = (s) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && isoDate(d) === s;
};
const addDays = (iso, n) => {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return isoDate(d);
};
const firstOfMonth = (iso) => `${iso.slice(0, 7)}-01`;
const num = (v) => Number(v || 0);

module.exports = function register(app, pool, JWT_SECRET, wrap) {
  const auth = (req, res, next) => {
    const h = req.headers.authorization || '';
    try {
      const p = jwt.verify(h.startsWith('Bearer ') ? h.slice(7) : '', JWT_SECRET);
      req.userId = Number(p.sub);
      next();
    } catch {
      res.status(401).json({ message: 'Sesi berakhir, silakan login lagi' });
    }
  };

  async function ensureSchema() {
    await pool.query(`CREATE TABLE IF NOT EXISTS transactions (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      type ENUM('expense','income') NOT NULL,
      category VARCHAR(30) NOT NULL,
      amount BIGINT NOT NULL,
      note VARCHAR(255) NOT NULL DEFAULT '',
      tx_date DATE NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_tx_user_date (user_id, tx_date),
      CONSTRAINT fk_tx_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
  }

  const sums = async (userId, fromIso, toIso) => {
    const [rows] = await pool.query(
      `SELECT type, SUM(amount) AS total FROM transactions
       WHERE user_id = ? AND tx_date >= ? AND tx_date < ? GROUP BY type`,
      [userId, fromIso, toIso],
    );
    const out = { income: 0, expense: 0 };
    rows.forEach((r) => { out[r.type] = num(r.total); });
    return out;
  };

  const monthEnd = (iso) => {
    const d = new Date(`${firstOfMonth(iso)}T00:00:00Z`);
    d.setUTCMonth(d.getUTCMonth() + 1);
    return isoDate(d);
  };

  // Tambah transaksi
  app.post('/transactions', auth, wrap(async (req, res) => {
    const type = req.body.type;
    const amount = Number(req.body.amount);
    const date = String(req.body.date || '');
    const note = String(req.body.note || '').trim().slice(0, 255);
    let category = String(req.body.category || '').toLowerCase();

    if (!['expense', 'income'].includes(type)) return res.status(400).json({ message: 'Jenis transaksi tidak valid' });
    if (!Number.isInteger(amount) || amount <= 0 || amount > 999999999999) {
      return res.status(400).json({ message: 'Jumlah harus lebih dari 0' });
    }
    if (!validIso(date)) return res.status(400).json({ message: 'Tanggal tidak valid' });
    if (type === 'expense' && !EXPENSE_CATS.includes(category)) {
      return res.status(400).json({ message: 'Pilih kategori pengeluaran' });
    }
    if (type === 'income') category = 'pemasukan';

    const [r] = await pool.query(
      'INSERT INTO transactions (user_id, type, category, amount, note, tx_date) VALUES (?, ?, ?, ?, ?, ?)',
      [req.userId, type, category, amount, note, date],
    );
    res.status(201).json({ id: r.insertId, message: 'Transaksi tersimpan' });
  }));

  // Riwayat per bulan: ?month=YYYY-MM&type=all|expense|income
  app.get('/transactions', auth, wrap(async (req, res) => {
    const month = String(req.query.month || '');
    if (!/^\d{4}-\d{2}$/.test(month) || !validIso(`${month}-01`)) {
      return res.status(400).json({ message: 'Format bulan harus YYYY-MM' });
    }
    const type = ['expense', 'income'].includes(req.query.type) ? req.query.type : null;
    const from = `${month}-01`;
    const to = monthEnd(from);

    const [items] = await pool.query(
      `SELECT id, type, category, amount, note, DATE_FORMAT(tx_date, '%Y-%m-%d') AS date
       FROM transactions
       WHERE user_id = ? AND tx_date >= ? AND tx_date < ? ${type ? 'AND type = ?' : ''}
       ORDER BY tx_date DESC, id DESC`,
      type ? [req.userId, from, to, type] : [req.userId, from, to],
    );
    res.json({ items: items.map((i) => ({ ...i, amount: num(i.amount) })), summary: await sums(req.userId, from, to) });
  }));

  app.delete('/transactions/:id', auth, wrap(async (req, res) => {
    await pool.query('DELETE FROM transactions WHERE id = ? AND user_id = ?', [Number(req.params.id), req.userId]);
    res.json({ message: 'Transaksi dihapus' });
  }));

  // Ringkasan dashboard. ?today=YYYY-MM-DD (tanggal di perangkat, supaya zona waktu konsisten)
  app.get('/dashboard', auth, wrap(async (req, res) => {
    const today = validIso(String(req.query.today || '')) ? req.query.today : isoDate(new Date());
    const total = await sums(req.userId, '1970-01-01', '9999-12-31');
    const month = await sums(req.userId, firstOfMonth(today), monthEnd(today));

    // 4 hari terakhir (termasuk hari ini)
    const start = addDays(today, -3);
    const [rows] = await pool.query(
      `SELECT DATE_FORMAT(tx_date, '%Y-%m-%d') AS d, type, SUM(amount) AS total
       FROM transactions WHERE user_id = ? AND tx_date >= ? AND tx_date <= ? GROUP BY d, type`,
      [req.userId, start, today],
    );
    const chart = [0, 1, 2, 3].map((i) => ({ date: addDays(start, i), income: 0, expense: 0 }));
    rows.forEach((r) => {
      const day = chart.find((c) => c.date === r.d);
      if (day) day[r.type] = num(r.total);
    });

    const [recent] = await pool.query(
      `SELECT id, type, category, amount, note, DATE_FORMAT(tx_date, '%Y-%m-%d') AS date
       FROM transactions WHERE user_id = ? ORDER BY tx_date DESC, id DESC LIMIT 3`,
      [req.userId],
    );
    res.json({
      balance: total.income - total.expense,
      income: month.income,
      expense: month.expense,
      chart,
      recent: recent.map((i) => ({ ...i, amount: num(i.amount) })),
    });
  }));

  return { ensureSchema };
};
