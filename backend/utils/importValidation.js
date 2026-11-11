// Utilidades puras para leer y validar la plantilla Excel de SemiFund.
// No dependen de MongoDB ni de Express: se pueden probar por separado.

const MES_REGEX = /^\d{4}-(0[1-9]|1[0-2])$/;
const FECHA_REGEX = /^\d{4}-\d{2}-\d{2}$/;

function normalizarTexto(valor) {
  return String(valor ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

function normalizarEncabezado(valor) {
  return normalizarTexto(valor)
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function mesValido(valor) {
  return typeof valor === 'string' && MES_REGEX.test(valor.trim());
}

function fechaISOValida(valor) {
  if (typeof valor !== 'string' || !FECHA_REGEX.test(valor)) return false;
  const [anio, mes, dia] = valor.split('-').map(Number);
  const fecha = new Date(Date.UTC(anio, mes - 1, dia));
  return (
    fecha.getUTCFullYear() === anio &&
    fecha.getUTCMonth() === mes - 1 &&
    fecha.getUTCDate() === dia
  );
}

/**
 * Convierte un número o un texto escrito por el usuario a número.
 * Acepta "30000", "30.000", "30.000,50", "$ 30.000" y números de Excel.
 * Devuelve NaN cuando el valor no es un número.
 */
function parseMonto(valor) {
  if (typeof valor === 'number') return Number.isFinite(valor) ? valor : NaN;
  if (valor === null || valor === undefined) return NaN;
  let texto = String(valor).trim();
  if (!texto) return NaN;
  texto = texto.replace(/[^\d.,-]/g, '');
  if (!texto || texto === '-' || texto === '.' || texto === ',') return NaN;

  const ultimaComa = texto.lastIndexOf(',');
  const ultimoPunto = texto.lastIndexOf('.');
  const tieneComa = ultimaComa >= 0;
  const tienePunto = ultimoPunto >= 0;

  if (tieneComa && tienePunto) {
    if (ultimaComa > ultimoPunto) {
      texto = texto.replace(/\./g, '').replace(',', '.');
    } else {
      texto = texto.replace(/,/g, '');
    }
  } else if (tienePunto) {
    const partes = texto.split('.');
    const esMiles =
      partes.length > 2 ||
      (partes.length === 2 && partes[0].length > 0 && partes[1].length === 3);
    if (esMiles) texto = texto.replace(/\./g, '');
  } else if (tieneComa) {
    const partes = texto.split(',');
    const esMiles =
      partes.length > 2 ||
      (partes.length === 2 && partes[0].length > 0 && partes[1].length === 3);
    texto = esMiles ? texto.replace(/,/g, '') : texto.replace(',', '.');
  }
  const numero = Number(texto);
  return Number.isFinite(numero) ? numero : NaN;
}

/**
 * Convierte fechas de Excel o textos AAAA-MM-DD / DD/MM/AAAA a AAAA-MM-DD.
 * Devuelve null si no es una fecha real.
 */
function parseFecha(valor) {
  if (valor instanceof Date && !Number.isNaN(valor.getTime())) {
    // ExcelJS entrega las fechas de celda como UTC medianoche.
    return valor.toISOString().slice(0, 10);
  }
  if (valor === null || valor === undefined) return null;
  const texto = String(valor).trim();
  if (!texto) return null;

  if (FECHA_REGEX.test(texto)) {
    return fechaISOValida(texto) ? texto : null;
  }

  const partes = /^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$/.exec(texto);
  if (partes) {
    const dia = partes[1].padStart(2, '0');
    const mes = partes[2].padStart(2, '0');
    const anio = partes[3];
    const iso = `${anio}-${mes}-${dia}`;
    return fechaISOValida(iso) ? iso : null;
  }
  return null;
}

function fechaNoFutura(fecha, hoy) {
  return typeof fecha === 'string' && fechaISOValida(fecha) && fecha <= hoy;
}

function parseActivo(valor) {
  if (typeof valor === 'boolean') return valor;
  if (valor === null || valor === undefined) return true;
  const texto = normalizarTexto(valor);
  if (!texto) return true;
  if (texto === 'si' || texto === 'sí' || texto === 'true' || texto === '1') return true;
  if (texto === 'no' || texto === 'false' || texto === '0') return false;
  return null;
}

function parseEstadoAbono(valor) {
  const texto = normalizarTexto(valor);
  if (!texto) return 'aprobado';
  if (texto === 'aprobado' || texto === 'reportado') return texto;
  return null;
}

function redondear(valor) {
  return Math.round(Number(valor) * 100) / 100;
}

function claveAporte(integranteClave, mes) {
  return `${integranteClave}|${mes}`;
}

function claveGasto({ fecha, descripcion, monto }) {
  return `${fecha}|${normalizarTexto(descripcion)}|${redondear(monto).toFixed(2)}`;
}

function firmaAbono(clave, { monto, fecha, referencia }) {
  return `${clave}|${redondear(monto).toFixed(2)}|${fecha}|${normalizarTexto(referencia)}`;
}

module.exports = {
  normalizarTexto,
  normalizarEncabezado,
  mesValido,
  fechaISOValida,
  parseMonto,
  parseFecha,
  fechaNoFutura,
  parseActivo,
  parseEstadoAbono,
  redondear,
  claveAporte,
  claveGasto,
  firmaAbono
};
