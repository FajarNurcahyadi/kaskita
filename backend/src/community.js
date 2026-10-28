// Komunitas: postingan (teks + foto opsional), like, komentar.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const makeAuth = require('./auth');

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads');
const MAX_IMAGE_BYTES = 4 * 1024 * 1024;

// Deteksi tipe gambar dari byte awal (jangan percaya ekstensi/MIME dari klien).
function sniffImage(buf) {
  if (buf.length < 12) return null;
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'jpg';
  if (buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'png';
  if (buf.subarray(0, 4).toString() === 'RIFF' && buf.subarray(8, 12).toString() === 'WEBP') return 'webp';
  return null;
}

module.exports = function register(app, pool, JWT_SECRET, wrap) {
  const auth = makeAuth(JWT_SECRET);

  async function ensureSchema() {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
    await pool.query(`CREATE TABLE IF NOT EXISTS posts (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      body TEXT NOT NULL,
      image VARCHAR(120) NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_posts_created (created_at),
      CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
    await pool.query(`CREATE TABLE IF NOT EXISTS post_likes (
      post_id INT NOT NULL,
      user_id INT NOT NULL,
      PRIMARY KEY (post_id, user_id),
      CONSTRAINT fk_likes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
      CONSTRAINT fk_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
    await pool.query(`CREATE TABLE IF NOT EXISTS post_comments (
      id INT AUTO_INCREMENT PRIMARY KEY,
      post_id INT NOT NULL,
      user_id INT NOT NULL,
      body VARCHAR(500) NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_comments_post (post_id, created_at),
      CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
      CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )`);
  }

  const POST_SELECT = `
    SELECT p.id, p.body, p.image, p.created_at, u.id AS author_id, u.name AS author_name,
      (SELECT COUNT(*) FROM post_likes l WHERE l.post_id = p.id) AS likes,
      (SELECT COUNT(*) FROM post_comments c WHERE c.post_id = p.id) AS comments,
      EXISTS(SELECT 1 FROM post_likes l WHERE l.post_id = p.id AND l.user_id = ?) AS liked
    FROM posts p JOIN users u ON u.id = p.user_id`;

  const shapePost = (r, userId) => ({
    id: r.id,
    body: r.body,
    image: r.image,
    createdAt: r.created_at,
    author: { id: r.author_id, name: r.author_name },
    likes: Number(r.likes),
    comments: Number(r.comments),
    liked: Number(r.liked) === 1,
    mine: r.author_id === userId,
  });

  // Daftar postingan, ?q= untuk cari
  app.get('/posts', auth, wrap(async (req, res) => {
    const q = String(req.query.q || '').trim().slice(0, 100);
    const [rows] = await pool.query(
      `${POST_SELECT} ${q ? 'WHERE p.body LIKE ?' : ''} ORDER BY p.created_at DESC, p.id DESC LIMIT 50`,
      q ? [req.userId, `%${q}%`] : [req.userId],
    );
    res.json({ items: rows.map((r) => shapePost(r, req.userId)) });
  }));

  // Detail satu postingan + komentar
  app.get('/posts/:id', auth, wrap(async (req, res) => {
    const [rows] = await pool.query(`${POST_SELECT} WHERE p.id = ?`, [req.userId, Number(req.params.id)]);
    if (!rows.length) return res.status(404).json({ message: 'Postingan tidak ditemukan' });
    const [comments] = await pool.query(
      `SELECT c.id, c.body, c.created_at, u.id AS author_id, u.name AS author_name
       FROM post_comments c JOIN users u ON u.id = c.user_id
       WHERE c.post_id = ? ORDER BY c.created_at ASC, c.id ASC`,
      [Number(req.params.id)],
    );
    res.json({
      post: shapePost(rows[0], req.userId),
      comments: comments.map((c) => ({
        id: c.id,
        body: c.body,
        createdAt: c.created_at,
        author: { id: c.author_id, name: c.author_name },
        mine: c.author_id === req.userId,
      })),
    });
  }));

  // Buat postingan: { body, imageBase64? }
  app.post('/posts', auth, wrap(async (req, res) => {
    const body = String(req.body.body || '').trim();
    let image = null;
    if (body.length > 1000) return res.status(400).json({ message: 'Postingan maksimal 1000 karakter' });

    if (req.body.imageBase64) {
      const b64 = String(req.body.imageBase64).replace(/^data:[^;]+;base64,/, '');
      const buf = Buffer.from(b64, 'base64');
      if (buf.length > MAX_IMAGE_BYTES) return res.status(400).json({ message: 'Ukuran foto maksimal 4 MB' });
      const ext = sniffImage(buf);
      if (!ext) return res.status(400).json({ message: 'Foto harus berformat JPG, PNG, atau WebP' });
      const name = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}.${ext}`;
      fs.mkdirSync(UPLOAD_DIR, { recursive: true });
      fs.writeFileSync(path.join(UPLOAD_DIR, name), buf);
      image = `/uploads/${name}`;
    }
    if (!body && !image) return res.status(400).json({ message: 'Tulis sesuatu atau pilih foto dulu' });

    const [r] = await pool.query('INSERT INTO posts (user_id, body, image) VALUES (?, ?, ?)', [req.userId, body, image]);
    res.status(201).json({ id: r.insertId, message: 'Postingan terkirim' });
  }));

  app.delete('/posts/:id', auth, wrap(async (req, res) => {
    const [rows] = await pool.query('SELECT image FROM posts WHERE id = ? AND user_id = ?', [Number(req.params.id), req.userId]);
    if (!rows.length) return res.status(404).json({ message: 'Postingan tidak ditemukan' });
    await pool.query('DELETE FROM posts WHERE id = ?', [Number(req.params.id)]);
    if (rows[0].image) fs.unlink(path.join(UPLOAD_DIR, path.basename(rows[0].image)), () => {});
    res.json({ message: 'Postingan dihapus' });
  }));

  // Like / batal like
  app.post('/posts/:id/like', auth, wrap(async (req, res) => {
    const id = Number(req.params.id);
    const [exists] = await pool.query('SELECT id FROM posts WHERE id = ?', [id]);
    if (!exists.length) return res.status(404).json({ message: 'Postingan tidak ditemukan' });
    const [del] = await pool.query('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [id, req.userId]);
    const liked = del.affectedRows === 0;
    if (liked) await pool.query('INSERT IGNORE INTO post_likes (post_id, user_id) VALUES (?, ?)', [id, req.userId]);
    const [[c]] = await pool.query('SELECT COUNT(*) AS n FROM post_likes WHERE post_id = ?', [id]);
    res.json({ liked, likes: Number(c.n) });
  }));

  app.post('/posts/:id/comments', auth, wrap(async (req, res) => {
    const id = Number(req.params.id);
    const body = String(req.body.body || '').trim();
    if (!body) return res.status(400).json({ message: 'Komentar tidak boleh kosong' });
    if (body.length > 500) return res.status(400).json({ message: 'Komentar maksimal 500 karakter' });
    const [exists] = await pool.query('SELECT id FROM posts WHERE id = ?', [id]);
    if (!exists.length) return res.status(404).json({ message: 'Postingan tidak ditemukan' });
    const [r] = await pool.query('INSERT INTO post_comments (post_id, user_id, body) VALUES (?, ?, ?)', [id, req.userId, body]);
    res.status(201).json({ id: r.insertId, message: 'Komentar terkirim' });
  }));

  app.delete('/comments/:id', auth, wrap(async (req, res) => {
    await pool.query('DELETE FROM post_comments WHERE id = ? AND user_id = ?', [Number(req.params.id), req.userId]);
    res.json({ message: 'Komentar dihapus' });
  }));

  return { ensureSchema, UPLOAD_DIR };
};
