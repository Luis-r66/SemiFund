const formatoCop = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0
});

// Montos en pesos colombianos sin decimales, para avisos y correos.
function dinero(valor) {
  return formatoCop.format(Number(valor) || 0);
}

module.exports = { dinero };
