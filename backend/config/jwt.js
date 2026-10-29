const crypto = require('crypto');

if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET es obligatorio en producción.');
}

if (!process.env.JWT_SECRET && process.env.NODE_ENV !== 'production') {
  console.warn('JWT_SECRET no está definido; se usará un secreto aleatorio solo para esta ejecución.');
}

module.exports = process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex');
