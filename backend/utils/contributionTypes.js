// Tipo de registro de un aporte: la cuota mensual es única por integrante y
// mes; los aportes (viajes, materiales, etc.) pueden repetirse en el mismo mes.
const TIPOS = ['cuota', 'aporte'];

function normalizarTipo(valor, defecto = 'cuota') {
  if (valor === undefined || valor === null || valor === '') return defecto;
  if (typeof valor !== 'string') return null;
  const texto = valor.trim().toLowerCase();
  return TIPOS.includes(texto) ? texto : null;
}

// Los registros anteriores a la 1.5.2 no tienen tipo: se tratan como cuota
// para conservar la regla de una mensualidad por integrante y mes.
function tipoDe(contribucion) {
  return contribucion && contribucion.tipo === 'aporte' ? 'aporte' : 'cuota';
}

// Clave para comparar conceptos al repetir un aporte grupal sin duplicarlo.
function claveConcepto(texto) {
  return String(texto || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ');
}

module.exports = {
  TIPOS,
  normalizarTipo,
  tipoDe,
  claveConcepto
};
