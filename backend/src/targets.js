const makeAuth = require('./auth');

const MAX_AMOUNT = 999999999999;
const validIsoDate = (value) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
};
const amountValue = (value) => {
  if (typeof value !== 'number' && (typeof value !== 'string' || !/^\d+$/.test(value))) return null;
  const amount = Number(value);
  return Number.isSafeInteger(amount) && amount >= 0 && amount <= MAX_AMOUNT ? amount : null;
};
const idValue = (value) => {
  if (!/^\d+$/.test(String(value))) return null;
  const id = Number(value);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
};
const numberValue = (value) => Number(value || 0);

module.exports = function registerTargets(app, pool, JWT_SECRET, wrap) {
  const auth = makeAuth(JWT_SECRET);

  async function ensureSchema() {
    await pool.query(`CREATE TABLE IF NOT EXISTS savings_targets (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      name VARCHAR(100) NOT NULL,
      target_amount BIGINT NOT NULL,
      deadline DATE NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_savings_targets_user (user_id, id),
      CONSTRAINT fk_savings_targets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
    await pool.query(`CREATE TABLE IF NOT EXISTS savings_target_movements (
      id INT AUTO_INCREMENT PRIMARY KEY,
      target_id INT NOT NULL,
      user_id INT NOT NULL,
      type ENUM('deposit','withdrawal') NOT NULL,
      amount BIGINT NOT NULL,
      note VARCHAR(255) NOT NULL DEFAULT '',
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_target_movements_target (target_id, created_at),
      INDEX idx_target_movements_user (user_id, created_at),
      CONSTRAINT fk_target_movements_target FOREIGN KEY (target_id) REFERENCES savings_targets(id) ON DELETE CASCADE,
      CONSTRAINT fk_target_movements_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
  }

  async function targetById(db, userId, targetId) {
    const [rows] = await db.query(
      `SELECT t.id, t.name, t.target_amount AS targetAmount,
              DATE_FORMAT(t.deadline, '%Y-%m-%d') AS deadline,
              COALESCE(SUM(CASE WHEN m.type = 'deposit' THEN m.amount ELSE -m.amount END), 0) AS currentAmount
       FROM savings_targets t
       LEFT JOIN savings_target_movements m ON m.target_id = t.id
       WHERE t.user_id = ? AND t.id = ?
       GROUP BY t.id`,
      [userId, targetId],
    );
    if (!rows.length) return null;
    return formatTarget(rows[0]);
  }

  function formatTarget(row) {
    const targetAmount = numberValue(row.targetAmount);
    const currentAmount = numberValue(row.currentAmount);
    return {
      id: Number(row.id),
      name: row.name,
      targetAmount,
      currentAmount,
      remainingAmount: Math.max(0, targetAmount - currentAmount),
      progress: targetAmount > 0 ? Math.min(currentAmount / targetAmount, 1) : 0,
      deadline: row.deadline,
    };
  }

  async function walletBalance(db, userId) {
    const [rows] = await db.query(
      `SELECT COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) AS balance
       FROM transactions WHERE user_id = ?`,
      [userId],
    );
    return numberValue(rows[0].balance);
  }

  async function lockUser(db, userId) {
    const [rows] = await db.query('SELECT id FROM users WHERE id = ? FOR UPDATE', [userId]);
    return rows.length > 0;
  }

  async function recordMovement(db, { targetId, userId, type, amount, note }) {
    await db.query(
      'INSERT INTO savings_target_movements (target_id, user_id, type, amount, note) VALUES (?, ?, ?, ?, ?)',
      [targetId, userId, type, amount, note],
    );
    const transactionType = type === 'deposit' ? 'expense' : 'income';
    const transactionNote = `${type === 'deposit' ? 'Setoran' : 'Penarikan'} KasTarget: ${note || 'KasTarget'}`.slice(0, 255);
    await db.query(
      'INSERT INTO transactions (user_id, type, category, amount, note, tx_date) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, transactionType, transactionType === 'expense' ? 'lainnya' : 'pemasukan', amount, transactionNote, new Date().toISOString().slice(0, 10)],
    );
  }

  app.get('/targets', auth, wrap(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT t.id, t.name, t.target_amount AS targetAmount,
              DATE_FORMAT(t.deadline, '%Y-%m-%d') AS deadline,
              COALESCE(SUM(CASE WHEN m.type = 'deposit' THEN m.amount ELSE -m.amount END), 0) AS currentAmount
       FROM savings_targets t
       LEFT JOIN savings_target_movements m ON m.target_id = t.id
       WHERE t.user_id = ?
       GROUP BY t.id
       ORDER BY t.created_at DESC, t.id DESC`,
      [req.userId],
    );
    res.json({ items: rows.map(formatTarget) });
  }));

  app.post('/targets', auth, wrap(async (req, res) => {
    const name = String(req.body.name || '').trim();
    const targetAmount = amountValue(req.body.targetAmount);
    const initialAmount = amountValue(req.body.initialAmount ?? 0);
    const deadline = String(req.body.deadline || '');
    if (!name || name.length > 100) return res.status(400).json({ message: 'Nama KasTarget wajib diisi (maksimal 100 karakter)' });
    if (targetAmount === null || targetAmount < 1) return res.status(400).json({ message: 'Target tabungan harus lebih dari 0' });
    if (initialAmount === null) return res.status(400).json({ message: 'Setoran awal tidak valid' });
    if (initialAmount > targetAmount) return res.status(400).json({ message: 'Setoran awal tidak boleh melebihi target' });
    if (!validIsoDate(deadline)) return res.status(400).json({ message: 'Tanggal pencapaian tidak valid' });

    const connection = await pool.getConnection();
    let transactionOpen = false;
    try {
      await connection.beginTransaction();
      transactionOpen = true;
      if (initialAmount > 0) {
        if (!(await lockUser(connection, req.userId))) {
          await connection.rollback();
          transactionOpen = false;
          return res.status(401).json({ message: 'Akun tidak ditemukan' });
        }
        if ((await walletBalance(connection, req.userId)) < initialAmount) {
          await connection.rollback();
          transactionOpen = false;
          return res.status(400).json({ message: 'Saldo KasKita tidak mencukupi' });
        }
      }

      const [result] = await connection.query(
        'INSERT INTO savings_targets (user_id, name, target_amount, deadline) VALUES (?, ?, ?, ?)',
        [req.userId, name, targetAmount, deadline],
      );
      if (initialAmount > 0) {
        await recordMovement(connection, {
          targetId: result.insertId,
          userId: req.userId,
          type: 'deposit',
          amount: initialAmount,
          note: `Setoran awal ${name}`,
        });
      }
      await connection.commit();
      transactionOpen = false;
      res.status(201).json({
        target: await targetById(pool, req.userId, result.insertId),
        message: 'KasTarget berhasil dibuat',
      });
    } catch (error) {
      if (transactionOpen) await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }));

  app.get('/targets/:id', auth, wrap(async (req, res) => {
    const targetId = idValue(req.params.id);
    if (targetId === null) return res.status(400).json({ message: 'ID KasTarget tidak valid' });
    const target = await targetById(pool, req.userId, targetId);
    if (!target) return res.status(404).json({ message: 'KasTarget tidak ditemukan' });
    const [movements] = await pool.query(
      `SELECT id, type, amount, note,
              DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS createdAt
       FROM savings_target_movements
       WHERE target_id = ? AND user_id = ?
       ORDER BY created_at DESC, id DESC`,
      [targetId, req.userId],
    );
    res.json({
      target,
      movements: movements.map((movement) => ({ ...movement, id: Number(movement.id), amount: numberValue(movement.amount) })),
    });
  }));

  async function transfer(req, res, type) {
    const targetId = idValue(req.params.id);
    const amount = amountValue(req.body.amount);
    const note = String(req.body.note || '').trim().slice(0, 255);
    if (targetId === null) return res.status(400).json({ message: 'ID KasTarget tidak valid' });
    if (amount === null || amount < 1) return res.status(400).json({ message: 'Jumlah harus lebih dari 0' });

    const connection = await pool.getConnection();
    let transactionOpen = false;
    try {
      await connection.beginTransaction();
      transactionOpen = true;
      if (!(await lockUser(connection, req.userId))) {
        await connection.rollback();
        transactionOpen = false;
        return res.status(401).json({ message: 'Akun tidak ditemukan' });
      }
      const [targets] = await connection.query(
        'SELECT id FROM savings_targets WHERE user_id = ? AND id = ? FOR UPDATE',
        [req.userId, targetId],
      );
      if (!targets.length) {
        await connection.rollback();
        transactionOpen = false;
        return res.status(404).json({ message: 'KasTarget tidak ditemukan' });
      }
      const target = await targetById(connection, req.userId, targetId);
      if (type === 'deposit' && (await walletBalance(connection, req.userId)) < amount) {
        await connection.rollback();
        transactionOpen = false;
        return res.status(400).json({ message: 'Saldo KasKita tidak mencukupi' });
      }
      if (type === 'withdrawal' && target.currentAmount < amount) {
        await connection.rollback();
        transactionOpen = false;
        return res.status(400).json({ message: 'Saldo KasTarget tidak mencukupi' });
      }
      await recordMovement(connection, { targetId, userId: req.userId, type, amount, note });
      await connection.commit();
      transactionOpen = false;
      res.json({
        target: await targetById(pool, req.userId, targetId),
        message: type === 'deposit' ? 'Dana berhasil ditambahkan' : 'Dana berhasil ditarik',
      });
    } catch (error) {
      if (transactionOpen) await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  app.post('/targets/:id/deposits', auth, wrap(async (req, res) => transfer(req, res, 'deposit')));
  app.post('/targets/:id/withdrawals', auth, wrap(async (req, res) => transfer(req, res, 'withdrawal')));

  return { ensureSchema };
};
