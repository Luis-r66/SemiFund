const test = require('node:test');
const assert = require('node:assert/strict');

const authController = require('../controllers/authController');

function respuestaFalsa() {
  return {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    }
  };
}

async function llamar(body) {
  const res = respuestaFalsa();
  await authController.loginWithGoogle({ body }, res);
  return res;
}

test('Google: sin idToken responde 400', async () => {
  const res = await llamar({});
  assert.equal(res.statusCode, 400);
  assert.match(res.body.error, /token de Google/);
});

test('Google: idToken de tipo inválido responde 400', async () => {
  const res = await llamar({ idToken: 12345 });
  assert.equal(res.statusCode, 400);
});

test('Google: sin GOOGLE_CLIENT_ID configurado responde 503', async () => {
  const original = process.env.GOOGLE_CLIENT_ID;
  delete process.env.GOOGLE_CLIENT_ID;

  try {
    const res = await llamar({ idToken: 'token-de-prueba' });
    assert.equal(res.statusCode, 503);
    assert.match(res.body.error, /no está configurado/);
  } finally {
    if (original !== undefined) process.env.GOOGLE_CLIENT_ID = original;
  }
});

test('Google: el controlador está exportado para la ruta', () => {
  assert.equal(typeof authController.loginWithGoogle, 'function');
});
