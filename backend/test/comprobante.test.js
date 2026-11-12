const test = require('node:test');
const assert = require('node:assert/strict');

const cloudinaryService = require('../services/cloudinary');
const errorHandler = require('../middleware/errorHandler');

async function ejecutarErrorHandler(error) {
  return new Promise((resolve) => {
    const res = {
      statusCode: null,
      body: null,
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(payload) {
        this.body = payload;
        resolve(this);
        return this;
      }
    };
    errorHandler(error, {}, res, () => resolve(res));
  });
}

test('Cloudinary no configurado: subirComprobante responde 503', () => {
  const original = {
    name: process.env.CLOUDINARY_CLOUD_NAME,
    key: process.env.CLOUDINARY_API_KEY,
    secret: process.env.CLOUDINARY_API_SECRET
  };
  delete process.env.CLOUDINARY_CLOUD_NAME;
  delete process.env.CLOUDINARY_API_KEY;
  delete process.env.CLOUDINARY_API_SECRET;

  try {
    assert.equal(cloudinaryService.estaConfigurado(), false);
    assert.throws(
      () => cloudinaryService.subirComprobante(Buffer.from('x'), {}),
      (error) => error.status === 503
    );
  } finally {
    if (original.name !== undefined) process.env.CLOUDINARY_CLOUD_NAME = original.name;
    if (original.key !== undefined) process.env.CLOUDINARY_API_KEY = original.key;
    if (original.secret !== undefined) process.env.CLOUDINARY_API_SECRET = original.secret;
  }
});

test('Cloudinary configurado: estaConfigurado es true', () => {
  const original = {
    name: process.env.CLOUDINARY_CLOUD_NAME,
    key: process.env.CLOUDINARY_API_KEY,
    secret: process.env.CLOUDINARY_API_SECRET
  };
  process.env.CLOUDINARY_CLOUD_NAME = 'demo';
  process.env.CLOUDINARY_API_KEY = '123';
  process.env.CLOUDINARY_API_SECRET = 'secreto';

  try {
    assert.equal(cloudinaryService.estaConfigurado(), true);
  } finally {
    if (original.name === undefined) delete process.env.CLOUDINARY_CLOUD_NAME;
    else process.env.CLOUDINARY_CLOUD_NAME = original.name;
    if (original.key === undefined) delete process.env.CLOUDINARY_API_KEY;
    else process.env.CLOUDINARY_API_KEY = original.key;
    if (original.secret === undefined) delete process.env.CLOUDINARY_API_SECRET;
    else process.env.CLOUDINARY_API_SECRET = original.secret;
  }
});

test('borrarComprobante no falla sin publicId', async () => {
  assert.equal(await cloudinaryService.borrarComprobante(null), false);
  assert.equal(await cloudinaryService.borrarComprobante(''), false);
});

test('Multer: archivo mayor a 5 MB responde 413 con mensaje claro', async () => {
  const error = new Error('File too large');
  error.name = 'MulterError';
  error.code = 'LIMIT_FILE_SIZE';

  const res = await ejecutarErrorHandler(error);
  assert.equal(res.statusCode, 413);
  assert.match(res.body.error, /5 MB/);
});

test('Multer: otros errores de subida responden 400', async () => {
  const error = new Error('Unexpected field');
  error.name = 'MulterError';
  error.code = 'LIMIT_UNEXPECTED_FILE';

  const res = await ejecutarErrorHandler(error);
  assert.equal(res.statusCode, 400);
  assert.match(res.body.error, /archivo adjunto/);
});
