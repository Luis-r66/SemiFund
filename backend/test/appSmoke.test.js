const test = require('node:test');
const assert = require('node:assert/strict');

// app.js crea un secreto de emergencia si falta, pero definirlo evita ruido.
process.env.JWT_SECRET = process.env.JWT_SECRET || 'secreto-de-prueba';

// Montar la app recorre todas las rutas: si un controlador no existe, Express
// lanza "argument handler must be a function" y el servidor no arranca.
test('la app se monta con todas las rutas y controladores', () => {
  assert.doesNotThrow(() => require('../app'));
});

test('las rutas de documentos están montadas y protegidas para profesores', () => {
  const controller = require('../controllers/documentController');
  for (const nombre of ['etiquetas', 'listar', 'subir', 'reemplazar', 'eliminar', 'generar']) {
    assert.equal(typeof controller[nombre], 'function', `documentController.${nombre}`);
  }

  const router = require('../routes/documents');
  const rutas = router.stack
    .filter((item) => item.route)
    .map((item) => `${Object.keys(item.route.methods).join(',')} ${item.route.path}`);
  assert.ok(rutas.includes('get /tags'));
  assert.ok(rutas.includes('get /templates'));
  assert.ok(rutas.includes('post /templates'));
  assert.ok(rutas.includes('put /templates/:id'));
  assert.ok(rutas.includes('delete /templates/:id'));
  assert.ok(rutas.includes('post /templates/:id/generate'));

  for (const capa of router.stack.filter((item) => item.route)) {
    for (const handler of capa.route.stack) {
      assert.equal(typeof handler.handle, 'function');
    }
  }
});
