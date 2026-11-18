// Motor de documentos: toma una plantilla .docx o .xlsx con etiquetas
// {{campo}} y devuelve el archivo lleno, sin guardarlo en el servidor.
//
// Convenciones de la plantilla:
//   {{semillero.nombre}}            dato de la app
//   {{#gastos}} ... {{/gastos}}     bloque repetible
// Los marcadores de bloque se borran al generar.

const PizZip = require('pizzip');
const Docxtemplater = require('docxtemplater');
const ExcelJS = require('exceljs');

const ETIQUETAS_SIMPLES = {
  'semillero.nombre': 'Nombre del semillero',
  'semillero.codigo': 'Código del semillero',
  'semillero.ciudad': 'Ciudad del semillero',
  'semillero.centroCostos': 'Centro de costos',
  'semillero.saldoInicial': 'Saldo inicial',
  'semillero.saldoDisponible': 'Saldo disponible',
  'semillero.totalAportado': 'Total recaudado',
  'semillero.totalGastado': 'Total gastado',
  'semillero.miembros': 'Número de integrantes activos',
  'profesor.nombre': 'Nombre completo del profesor',
  'profesor.nombres': 'Nombres del profesor',
  'profesor.apellidos': 'Apellidos del profesor',
  'profesor.identificacion': 'Documento de identidad del profesor',
  'profesor.cargo': 'Cargo del profesor',
  'profesor.programa': 'Área o departamento del profesor',
  'profesor.email': 'Correo del profesor',
  'periodo.mes': 'Mes en formato AAAA-MM',
  'periodo.mesTexto': 'Mes en palabras',
  'periodo.fecha': 'Fecha de hoy en palabras',
  'periodo.fechaCorta': 'Fecha de hoy AAAA-MM-DD',
  'periodo.ciudad': 'Ciudad para el documento',
  'periodo.anio': 'Año',
  'totales.facturas': 'Suma de los gastos listados',
  'totales.aportes': 'Suma de los aportes cobrados',
  'totales.gastos': 'Suma de todos los gastos del semillero',
  'totales.saldo': 'Saldo disponible',
  'totales.diferencia': 'Valor entregado menos total de facturas',
  'totales.integrantes': 'Cantidad de integrantes en el documento',
  // Datos que se preguntan al generar el documento (fechas del viaje, objeto…).
  'viaje.inicio': 'Fecha de inicio del viaje',
  'viaje.fin': 'Fecha de fin del viaje',
  'viaje.ciudades': 'Ciudades y países del viaje',
  'viaje.objeto': 'Objeto o motivo del viaje',
  'viaje.valorEntregado': 'Valor entregado para el viaje',
  'documento.hora': 'Hora del documento',
  'documento.lugar': 'Lugar del documento',
  'documento.observaciones': 'Observaciones escritas al generar',
  'firma.nombre': 'Nombre de quien firma',
  'firma.documento': 'Documento de quien firma',
  'firma.cargo': 'Cargo de quien firma'
};

const CAMPOS_BLOQUES = {
  integrantes: {
    nombre: 'Nombre completo',
    nombres: 'Nombres',
    apellidos: 'Apellidos',
    identificacion: 'Documento de identidad',
    programa: 'Carrera o área',
    semestre: 'Semestre',
    tipo: 'Estudiante o profesor',
    estado: 'Activo o inactivo',
    cuotasPagadas: 'Cuotas pagadas',
    cuotasPendientes: 'Cuotas pendientes',
    totalAportado: 'Total aportado',
    saldoPendiente: 'Saldo pendiente'
  },
  gastos: {
    fecha: 'Fecha del gasto',
    proveedor: 'Proveedor',
    nit: 'NIT del proveedor',
    factura: 'Número de factura',
    concepto: 'Concepto o descripción',
    categoria: 'Categoría',
    tasa: 'Tasa de cambio',
    valor: 'Valor del gasto',
    monto: 'Valor del gasto (número)'
  },
  movimientos: {
    fecha: 'Fecha del movimiento',
    tipo: 'Cuota o aporte',
    concepto: 'Concepto',
    mes: 'Mes',
    monto: 'Monto',
    abonado: 'Valor abonado',
    saldo: 'Saldo pendiente',
    estado: 'Estado',
    integrante: 'Integrante'
  }
};

const BLOQUES = ['integrantes', 'gastos', 'movimientos'];

function catalogo() {
  return {
    simples: Object.entries(ETIQUETAS_SIMPLES).map(([clave, descripcion]) => ({ clave, descripcion })),
    bloques: Object.entries(CAMPOS_BLOQUES).map(([nombre, campos]) => ({
      nombre,
      descripcion: `Se repite por cada ${nombre === 'movimientos' ? 'movimiento' : nombre === 'gastos' ? 'gasto' : 'integrante'}`,
      campos: Object.entries(campos).map(([clave, descripcion]) => ({ clave, descripcion }))
    }))
  };
}

function normalizarEtiqueta(etiqueta) {
  return String(etiqueta || '').replace(/\s+/g, '').replace(/^#|^\/|^\./, '').replace(/^\$/, '');
}

// Revisa las etiquetas encontradas contra el catálogo. Devuelve las que la app
// no sabe llenar para avisarle al profesor antes de guardar la plantilla.
function revisarEtiquetas(etiquetas) {
  const desconocidas = [];
  const pila = [];
  for (const etiqueta of etiquetas) {
    const limpia = String(etiqueta).trim();
    if (limpia.startsWith('#')) {
      const nombre = normalizarEtiqueta(limpia);
      if (!BLOQUES.includes(nombre)) {
        desconocidas.push(limpia);
      } else {
        pila.push(nombre);
      }
      continue;
    }
    if (limpia.startsWith('/')) {
      const nombre = normalizarEtiqueta(limpia);
      if (pila[pila.length - 1] !== nombre) {
        desconocidas.push(limpia);
      } else {
        pila.pop();
      }
      continue;
    }
    const ruta = limpia.replace(/\s+/g, '');
    if (ETIQUETAS_SIMPLES[ruta]) continue;
    const [bloque, campo] = ruta.split('.');
    if (campo && CAMPOS_BLOQUES[bloque] && CAMPOS_BLOQUES[bloque][campo]) continue;
    // Dentro de un bloque también se puede escribir el campo solo
    // ({{concepto}}), que es lo natural en Word y en Excel.
    const abierto = pila[pila.length - 1];
    if (!campo && abierto && CAMPOS_BLOQUES[abierto][ruta]) continue;
    desconocidas.push(limpia);
  }
  // Un bloque que se abre y no se cierra deja el documento inservible.
  for (const nombre of pila) desconocidas.push(`/${nombre}`);
  return desconocidas;
}

// ---------------------------------------------------------------------------
// Lectura de etiquetas
// ---------------------------------------------------------------------------

function textoPlanoXml(xml) {
  // Deja el texto de todos los <w:t>, sin etiquetas XML: así una etiqueta
  // partida en varios "runs" de Word se lee completa.
  return xml
    .replace(/<w:t(?:\s[^>]*)?>/g, '')
    .replace(/<\/w:t>/g, '')
    .replace(/<[^>]+>/g, '');
}

function etiquetasDeDocx(buffer) {
  const zip = new PizZip(buffer);
  const partes = Object.keys(zip.files).filter((nombre) =>
    /^word\/(document|header\d*|footer\d*)\.xml$/.test(nombre)
  );
  const encontradas = new Set();
  for (const parte of partes) {
    const xml = zip.file(parte).asText();
    const texto = textoPlanoXml(xml);
    for (const coincidencia of texto.matchAll(/\{\{([\s\S]{1,120}?)\}\}/g)) {
      encontradas.add(coincidencia[1].trim());
    }
  }
  return [...encontradas];
}

function etiquetasDeXlsx(buffer) {
  const libro = new ExcelJS.Workbook();
  return libro.xlsx.load(buffer).then(() => {
    const encontradas = new Set();
    libro.eachSheet((hoja) => {
      hoja.eachRow({ includeEmpty: false }, (fila) => {
        fila.eachCell({ includeEmpty: false }, (celda) => {
          if (typeof celda.text !== 'string') return;
          for (const coincidencia of celda.text.matchAll(/\{\{([\s\S]{1,120}?)\}\}/g)) {
            encontradas.add(coincidencia[1].trim());
          }
        });
      });
    });
    return [...encontradas];
  });
}

async function leerEtiquetas(buffer, tipo) {
  const etiquetas = tipo === 'xlsx' ? await etiquetasDeXlsx(buffer) : etiquetasDeDocx(buffer);
  return { etiquetas, desconocidas: revisarEtiquetas(etiquetas) };
}

// ---------------------------------------------------------------------------
// Valores
// ---------------------------------------------------------------------------

const formatoMoneda = new Intl.NumberFormat('es-CO', { maximumFractionDigits: 2 });

function esMoneda(clave) {
  return /monto|valor|total|saldo|factura|aportado|abonado|pendiente|diferencia/i.test(clave) &&
    !/numeroFactura/i.test(clave);
}

function formatearValor(valor, clave = '') {
  if (valor === null || valor === undefined) return '';
  if (typeof valor === 'number') {
    return esMoneda(clave) ? formatoMoneda.format(valor) : String(valor);
  }
  return String(valor);
}

function buscar(datos, ruta) {
  const partes = String(ruta).trim().split('.');
  let valor = datos;
  for (const parte of partes) {
    if (valor === null || valor === undefined) return undefined;
    valor = valor[parte];
  }
  return valor;
}

// Resuelve una etiqueta dentro del elemento actual del bloque y, si no está
// ahí, en la raíz del documento. Así {{profesor.nombre}} funciona también
// dentro de un bloque repetible, y {{gastos.concepto}} apunta al elemento
// actual en vez de al primer gasto del semillero.
function resolverEtiqueta(ruta, ambito, raiz) {
  const limpia = String(ruta).trim();
  if (ambito && ambito !== raiz && typeof ambito === 'object') {
    const [primero, ...resto] = limpia.split('.');
    if (resto.length > 0 && Array.isArray(raiz[primero]) && raiz[primero].includes(ambito)) {
      const interno = buscar(ambito, resto.join('.'));
      if (interno !== undefined) return interno;
    }
  }
  const valor = buscar(ambito, limpia);
  if (valor !== undefined) return valor;
  return buscar(raiz, limpia);
}

// ---------------------------------------------------------------------------
// DOCX
// ---------------------------------------------------------------------------

function generarDocx(buffer, datos) {
  const zip = new PizZip(buffer);
  const documento = new Docxtemplater(zip, {
    paragraphLoop: true,
    linebreaks: true,
    delimiters: { start: '{{', end: '}}' },
    nullGetter: () => '',
    // docxtemplater no resuelve rutas con punto por sí solo: hay que darle
    // un parser propio o {{profesor.nombre}} sale como texto vacío.
    parser: (etiqueta) => ({
      get(ambito) {
        const valor = resolverEtiqueta(etiqueta, ambito, datos);
        return valor === undefined ? '' : valor;
      }
    })
  });
  documento.render(datos);
  return documento.getZip().generate({ type: 'nodebuffer', compression: 'DEFLATE' });
}

// ---------------------------------------------------------------------------
// XLSX
// ---------------------------------------------------------------------------

function reemplazarEnTexto(texto, ambito, raiz) {
  return texto.replace(/\{\{([\s\S]{1,120}?)\}\}/g, (_, etiqueta) => {
    const limpia = etiqueta.trim();
    if (limpia.startsWith('#') || limpia.startsWith('/')) return '';
    return formatearValor(resolverEtiqueta(limpia, ambito, raiz), limpia);
  });
}

function copiarEstilo(origen, destino) {
  destino.style = JSON.parse(JSON.stringify(origen.style || {}));
  if (origen.numFmt) destino.numFmt = origen.numFmt;
}

// Reemplaza las etiquetas simples y expande los bloques {{#x}}...{{/x}}.
// El bloque debe ocupar filas completas: la fila de apertura, una o más filas
// de modelo y la de cierre. Al terminar, las filas marcadas desaparecen.
function generarXlsx(buffer, datos) {
  const libro = new ExcelJS.Workbook();
  return libro.xlsx.load(buffer).then(async () => {
    for (const hoja of libro.worksheets) {
      expandirBloques(hoja, datos);
      hoja.eachRow({ includeEmpty: false }, (fila) => {
        fila.eachCell({ includeEmpty: false }, (celda) => {
          if (typeof celda.value === 'string' && celda.value.includes('{{')) {
            celda.value = reemplazarEnTexto(celda.value, datos, datos);
          }
        });
      });
    }
    return libro.xlsx.writeBuffer();
  });
}

function expandirBloques(hoja, datos) {
  // Se repite hasta que no queden marcas: permite bloques anidados por filas.
  for (let vuelta = 0; vuelta < 10; vuelta += 1) {
    let encontrado = false;
    hoja.eachRow({ includeEmpty: false }, (fila) => {
      if (encontrado) return;
      let nombre = null;
      fila.eachCell({ includeEmpty: false }, (celda) => {
        if (nombre || typeof celda.value !== 'string') return;
        const apertura = celda.value.match(/\{\{#\s*([\w.]+)\s*\}\}/);
        if (apertura) nombre = apertura[1];
      });
      if (!nombre) return;
      encontrado = true;
      expandirBloque(hoja, fila.number, nombre, datos);
    });
    if (!encontrado) return;
  }
}

function expandirBloque(hoja, filaInicio, nombre, datos) {
  let filaFin = null;
  hoja.eachRow({ includeEmpty: false }, (fila) => {
    if (filaFin || fila.number <= filaInicio) return;
    fila.eachCell({ includeEmpty: false }, (celda) => {
      if (filaFin || typeof celda.value !== 'string') return;
      if (new RegExp(`\\{\\{\\s*/\\s*${nombre}\\s*\\}\\}`).test(celda.value)) filaFin = fila.number;
    });
  });
  if (filaFin === null) return;

  const elementos = Array.isArray(datos[nombre]) ? datos[nombre] : [];
  const columnas = Math.max(hoja.columnCount, 1);
  const filasModelo = [];
  for (let numero = filaInicio + 1; numero < filaFin; numero += 1) {
    const fila = hoja.getRow(numero);
    const celdas = [];
    for (let columna = 1; columna <= columnas; columna += 1) {
      const celda = fila.getCell(columna);
      celdas.push({
        valor: celda.value,
        estilo: JSON.parse(JSON.stringify(celda.style || {})),
        numFmt: celda.numFmt
      });
    }
    filasModelo.push({ alto: fila.height, celdas });
  }
  if (filasModelo.length === 0) {
    filasModelo.push({ alto: null, celdas: [] });
  }

  const filasABorrar = filaFin - filaInicio + 1;
  const filasOriginales = hoja.rowCount;
  hoja.spliceRows(filaInicio, filasABorrar);
  // Se insertan filas en blanco para que lo que está debajo (totales, firmas)
  // baje tantas filas como elementos tenga el bloque.
  const totalFilas = elementos.length * filasModelo.length;
  if (totalFilas > 0) {
    hoja.spliceRows(filaInicio, 0, ...Array.from({ length: totalFilas }, () => []));
  }

  let cursor = filaInicio;
  for (const elemento of elementos) {
    for (const modelo of filasModelo) {
      const fila = hoja.getRow(cursor);
      if (modelo.alto) fila.height = modelo.alto;
      for (let columna = 1; columna <= columnas; columna += 1) {
        const origen = modelo.celdas[columna - 1];
        const celda = fila.getCell(columna);
        if (origen) {
          if (origen.valor !== null && origen.valor !== undefined && origen.valor !== '') {
            if (typeof origen.valor === 'string') {
              const soloEtiqueta = origen.valor.trim().match(/^\{\{([\s\S]{1,120}?)\}\}$/);
              if (soloEtiqueta) {
                const limpia = soloEtiqueta[1].trim();
                const valor = resolverEtiqueta(limpia, elemento, datos);
                celda.value = valor === undefined || valor === null ? '' : valor;
              } else {
                celda.value = reemplazarEnTexto(origen.valor, elemento, datos);
              }
            } else {
              celda.value = origen.valor;
            }
          } else {
            celda.value = null;
          }
          celda.style = JSON.parse(JSON.stringify(origen.estilo || {}));
          if (origen.numFmt) celda.numFmt = origen.numFmt;
        }
      }
      cursor += 1;
    }
  }

  // ExcelJS deja copias vacías de las filas desplazadas al final de la hoja;
  // se limpian para que no aparezcan filas sueltas bajo el documento.
  const nuevaUltima = filasOriginales - filasABorrar + totalFilas;
  for (let numero = nuevaUltima + 1; numero <= hoja.rowCount; numero += 1) {
    hoja.getRow(numero).eachCell({ includeEmpty: false }, (celda) => {
      celda.value = null;
    });
  }
}

// ---------------------------------------------------------------------------
// Punto de entrada
// ---------------------------------------------------------------------------

async function generarDocumento(buffer, tipo, datos) {
  if (tipo === 'xlsx') return Buffer.from(await generarXlsx(buffer, datos));
  return generarDocx(buffer, datos);
}

module.exports = {
  catalogo,
  leerEtiquetas,
  revisarEtiquetas,
  generarDocumento,
  formatearValor,
  ETIQUETAS_SIMPLES,
  CAMPOS_BLOQUES
};
