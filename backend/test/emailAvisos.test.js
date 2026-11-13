const test = require('node:test');
const assert = require('node:assert/strict');

const { plantillaDeAviso, PLANTILLAS } = require('../utils/emailAvisos');

test('cada evento tiene asunto y saludo en español', () => {
  for (const tipo of Object.keys(PLANTILLAS)) {
    const correo = plantillaDeAviso({
      tipo,
      nombre: 'Valentina',
      semilleroNombre: 'Semillero de Software',
      mensaje: 'Detalle del aviso.'
    });
    assert.ok(correo, `falta la plantilla de ${tipo}`);
    assert.match(correo.subject, /^[A-ZÁÉÍÓÚ][^·]+· Semillero de Software$/);
    assert.match(correo.textContent, /^Hola Valentina,/);
    assert.match(correo.textContent, /Detalle del aviso\./);
    assert.match(correo.htmlContent, /Abrir SemiFund/);
  }
});

test('sin nombre conocido se usa un saludo neutro', () => {
  const correo = plantillaDeAviso({
    tipo: 'cuota_nueva',
    semilleroNombre: null,
    mensaje: 'Se registró la cuota de 2026-11.'
  });
  assert.match(correo.subject, /tu semillero$/);
  assert.match(correo.textContent, /^Hola,/);
});

test('el detalle se escapa en HTML y se conserva en texto plano', () => {
  const mensaje = 'Ana <b>reportó</b> $ 50.000';
  const correo = plantillaDeAviso({
    tipo: 'abono_reportado',
    nombre: 'Luis',
    semilleroNombre: 'Semillero',
    mensaje
  });
  assert.ok(correo.htmlContent.includes('Ana &lt;b&gt;reportó&lt;/b&gt;'));
  assert.ok(!correo.htmlContent.includes('<b>reportó</b>'));
  assert.ok(correo.textContent.includes(mensaje));
});

test('un tipo desconocido no genera correo', () => {
  assert.equal(
    plantillaDeAviso({ tipo: 'otro', nombre: 'Ana', mensaje: 'x' }),
    null
  );
});
