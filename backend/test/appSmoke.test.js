const test = require('node:test');
const assert = require('node:assert/strict');

// app.js crea un secreto de emergencia si falta, pero definirlo evita ruido.
process.env.JWT_SECRET = process.env.JWT_SECRET || 'secreto-de-prueba';

// Montar la app recorre todas las rutas: si un controlador no existe, Express
// lanza "argument handler must be a function" y el servidor no arranca.
test('la app se monta con todas las rutas y controladores', () => {
  assert.doesNotThrow(() => require('../app'));
});

test('el aporte propio del integrante está exportado y registrado', () => {
  const controller = require('../controllers/contributionController');
  assert.equal(typeof controller.createSelf, 'function');

  const router = require('../routes/contributions');
  const capa = router.stack.find(
    (item) => item.route && item.route.path === '/self'
  );

  assert.ok(capa, 'la ruta POST /self debe existir');
  assert.deepEqual(Object.keys(capa.route.methods), ['post']);

  for (const handler of capa.route.stack) {
    assert.equal(
      typeof handler.handle,
      'function',
      'ningún handler de /self puede quedar indefinido'
    );
  }
});
