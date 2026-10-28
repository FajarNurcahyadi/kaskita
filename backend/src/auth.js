const jwt = require('jsonwebtoken');

// Middleware: baca "Authorization: Bearer <token>", isi req.userId.
module.exports = function makeAuth(JWT_SECRET) {
  return (req, res, next) => {
    const h = req.headers.authorization || '';
    try {
      const p = jwt.verify(h.startsWith('Bearer ') ? h.slice(7) : '', JWT_SECRET);
      req.userId = Number(p.sub);
      next();
    } catch {
      res.status(401).json({ message: 'Sesi berakhir, silakan login lagi' });
    }
  };
};
