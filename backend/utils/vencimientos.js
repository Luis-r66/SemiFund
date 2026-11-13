const Contribution = require('../models/Contribution');
const { hoyBogota } = require('./validators');

// Mes actual (YYYY-MM) en Colombia. El mes de una cuota es de calendario, no
// de zona horaria del servidor.
function mesActual(now = new Date()) {
  return hoyBogota(now).slice(0, 7);
}

// Marca como vencidas las cuotas pendientes de meses anteriores.
// Idempotente: se puede ejecutar tantas veces como haga falta.
async function marcarVencidos(semilleroId) {
  const filtro = { estado: 'pendiente', mes: { $lt: mesActual() } };
  if (semilleroId) filtro.semilleroId = semilleroId;
  const resultado = await Contribution.updateMany(filtro, { $set: { estado: 'vencido' } });
  return resultado.modifiedCount || 0;
}

module.exports = { marcarVencidos, mesActual };
