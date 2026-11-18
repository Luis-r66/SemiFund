const test = require('node:test');
const assert = require('node:assert/strict');
const PizZip = require('pizzip');
const ExcelJS = require('exceljs');

const {
  catalogo,
  leerEtiquetas,
  revisarEtiquetas,
  generarDocumento,
  formatearValor
} = require('../services/documentEngine');

// --- Utilidades de prueba ---------------------------------------------------

// DOCX mínimo válido: docxtemplater solo necesita el documento principal y sus
// relaciones para renderizar etiquetas.
function docxMinimo(texto) {
  const zip = new PizZip();
  zip.file(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
      '</Types>'
  );
  zip.file(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
      '</Relationships>'
  );
  zip.file(
    'word/document.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' +
      `<w:p><w:r><w:t>${texto}</w:t></w:r></w:p>` +
      '</w:body></w:document>'
  );
  return zip.generate({ type: 'nodebuffer' });
}

function textoDeDocx(buffer) {
  const zip = new PizZip(buffer);
  return zip
    .file('word/document.xml')
    .asText()
    .replace(/<w:t(?:\s[^>]*)?>/g, '')
    .replace(/<\/w:t>/g, '')
    .replace(/<[^>]+>/g, '');
}

// --- Catálogo y etiquetas ---------------------------------------------------

test('el catálogo ofrece etiquetas simples y bloques repetibles', () => {
  const lista = catalogo();
  assert.ok(lista.simples.some((item) => item.clave === 'semillero.nombre'));
  assert.ok(lista.simples.some((item) => item.clave === 'profesor.identificacion'));
  const gastos = lista.bloques.find((bloque) => bloque.nombre === 'gastos');
  assert.ok(gastos.campos.some((campo) => campo.clave === 'factura'));
  assert.ok(gastos.campos.some((campo) => campo.clave === 'nit'));
});

test('acepta etiquetas conocidas y rechaza las que la app no llena', () => {
  assert.deepEqual(
    revisarEtiquetas(['semillero.nombre', 'profesor.identificacion', '#gastos', 'gastos.valor', '/gastos']),
    []
  );
  assert.deepEqual(revisarEtiquetas(['semillero.inventada']), ['semillero.inventada']);
  assert.deepEqual(revisarEtiquetas(['#facturas', '/facturas']), ['#facturas', '/facturas']);
  assert.deepEqual(revisarEtiquetas(['#gastos']), ['/gastos']);
});

test('lee etiquetas aunque estén partidas en varios tramos de Word', async () => {
  // Word separa {{nombre}} en tres <w:t>; hay que unir el texto antes de buscar.
  const zip = new PizZip();
  zip.file(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'
  );
  zip.file('_rels/.rels', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>');
  zip.file(
    'word/document.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p>' +
      '<w:r><w:t>{{semillero.</w:t></w:r>' +
      '<w:r><w:t>nombre}}</w:t></w:r>' +
      '</w:p></w:body></w:document>'
  );
  const { etiquetas, desconocidas } = await leerEtiquetas(zip.generate({ type: 'nodebuffer' }), 'docx');
  assert.deepEqual(etiquetas, ['semillero.nombre']);
  assert.deepEqual(desconocidas, []);
});

test('lee etiquetas de un libro de Excel', async () => {
  const libro = new ExcelJS.Workbook();
  const hoja = libro.addWorksheet('Acta');
  hoja.getCell('A1').value = 'Semillero: {{semillero.nombre}}';
  hoja.getCell('A2').value = '{{#integrantes}}';
  hoja.getCell('A3').value = '{{integrantes.nombre}}';
  hoja.getCell('A4').value = '{{/integrantes}}';
  const buffer = await libro.xlsx.writeBuffer();

  const { etiquetas, desconocidas } = await leerEtiquetas(Buffer.from(buffer), 'xlsx');
  assert.deepEqual(
    etiquetas.sort(),
    ['#integrantes', '/integrantes', 'integrantes.nombre', 'semillero.nombre'].sort()
  );
  assert.deepEqual(desconocidas, []);
});

// --- Formato de valores -----------------------------------------------------

test('formatea dinero con separador de miles y deja vacío lo que falta', () => {
  assert.equal(formatearValor(1500000, 'totales.facturas'), '1.500.000');
  assert.equal(formatearValor(null, 'gastos.valor'), '');
  assert.equal(formatearValor(7, 'integrantes.semestre'), '7');
  assert.equal(formatearValor('NIT 900', 'gastos.nit'), 'NIT 900');
});

// --- Generación DOCX --------------------------------------------------------

test('genera DOCX reemplazando etiquetas simples y borrando bloques vacíos', async () => {
  const plantilla = docxMinimo(
    'Semillero {{semillero.nombre}} - {{profesor.nombre}}{{#gastos}} {{gastos.concepto}}{{/gastos}}.'
  );
  const salida = await generarDocumento(plantilla, 'docx', {
    semillero: { nombre: 'Semillero de Software' },
    profesor: { nombre: 'Ana Pérez' },
    gastos: []
  });
  const texto = textoDeDocx(salida);
  assert.match(texto, /Semillero de Software/);
  assert.match(texto, /Ana Pérez/);
  assert.doesNotMatch(texto, /\{\{|\}\}|undefined|null/);
});

test('genera DOCX repitiendo el bloque por cada elemento', async () => {
  const plantilla = docxMinimo(
    '{{#gastos}}[{{gastos.concepto}}: {{gastos.valor}}]{{/gastos}}'
  );
  const salida = await generarDocumento(plantilla, 'docx', {
    gastos: [
      { concepto: 'Taxi', valor: '50.000' },
      { concepto: 'Hotel', valor: '300.000' }
    ]
  });
  const texto = textoDeDocx(salida);
  assert.match(texto, /Taxi: 50\.000/);
  assert.match(texto, /Hotel: 300\.000/);
  assert.equal(texto.match(/Taxi/g).length, 1);
});

// --- Generación XLSX --------------------------------------------------------

test('genera XLSX reemplazando etiquetas y expandiendo el bloque', async () => {
  const libro = new ExcelJS.Workbook();
  const hoja = libro.addWorksheet('Viáticos');
  hoja.getCell('A1').value = 'Centro de costos: {{semillero.centroCostos}}';
  hoja.getCell('A3').value = 'Proveedor';
  hoja.getCell('B3').value = 'Valor';
  hoja.getCell('A4').value = '{{#gastos}}';
  hoja.getCell('A5').value = '{{gastos.proveedor}}';
  hoja.getCell('B5').value = '{{gastos.valor}}';
  hoja.getCell('A6').value = '{{/gastos}}';
  hoja.getCell('A8').value = 'Total: {{totales.facturas}}';
  const plantilla = Buffer.from(await libro.xlsx.writeBuffer());

  const salida = await generarDocumento(plantilla, 'xlsx', {
    semillero: { centroCostos: 'CC-101' },
    gastos: [
      { proveedor: 'Hotel Central', valor: '300.000' },
      { proveedor: 'Taxi', valor: '50.000' }
    ],
    totales: { facturas: '350.000' }
  });

  const resultado = new ExcelJS.Workbook();
  await resultado.xlsx.load(salida);
  const salidaHoja = resultado.getWorksheet('Viáticos');
  const valores = [];
  salidaHoja.eachRow({ includeEmpty: false }, (fila) => {
    fila.eachCell({ includeEmpty: false }, (celda) => valores.push(String(celda.value)));
  });

  assert.ok(valores.includes('Centro de costos: CC-101'));
  assert.ok(valores.includes('Hotel Central'));
  assert.ok(valores.includes('Taxi'));
  assert.ok(valores.includes('300.000'));
  assert.ok(valores.includes('Total: 350.000'));
  assert.ok(!valores.some((valor) => valor.includes('{{')));
  assert.equal(valores.filter((valor) => valor === 'Hotel Central').length, 1);
});

test('el bloque de Excel desaparece cuando no hay datos', async () => {
  const libro = new ExcelJS.Workbook();
  const hoja = libro.addWorksheet('Hoja');
  hoja.getCell('A1').value = 'Inicio';
  hoja.getCell('A2').value = '{{#integrantes}}';
  hoja.getCell('A3').value = '{{integrantes.nombre}}';
  hoja.getCell('A4').value = '{{/integrantes}}';
  hoja.getCell('A5').value = 'Fin';
  const plantilla = Buffer.from(await libro.xlsx.writeBuffer());

  const salida = await generarDocumento(plantilla, 'xlsx', { integrantes: [] });
  const resultado = new ExcelJS.Workbook();
  await resultado.xlsx.load(salida);
  const valores = [];
  resultado.getWorksheet('Hoja').eachRow({ includeEmpty: false }, (fila) => {
    fila.eachCell({ includeEmpty: false }, (celda) => valores.push(String(celda.value)));
  });
  assert.deepEqual(valores, ['Inicio', 'Fin']);
});
