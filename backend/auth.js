const crypto = require('crypto');

const sessions = new Map();

function createSession(user) {
  const token = crypto.randomBytes(32).toString('hex');
  sessions.set(token, user);
  return token;
}

function requireLogin(req, res, next) {
  const token = (req.get('authorization') || '').replace(/^Bearer\s+/i, '');
  const user = sessions.get(token);

  if (!user) {
    return res.status(401).json({ error: 'Please log in to continue.' });
  }

  req.user = user;
  req.sessionToken = token;
  next();
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'This action is for administrators only.' });
  }

  next();
}

function removeSession(token) {
  sessions.delete(token);
}

module.exports = { createSession, requireLogin, requireAdmin, removeSession };