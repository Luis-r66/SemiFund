// Filtro del contador de cuotas por cobrar del inicio.
// El tesorero ve todo el semillero; el integrante solo sus propias cuotas.
// Sin integrante vinculado no hay nada que contar.
function filtroCuotasPorCobrar({ semilleroId, esTesorero = false, memberId = null }) {
  const filtro = { semilleroId, estado: { $ne: 'pagado' } };
  if (esTesorero) return filtro;
  if (!memberId) return null;
  filtro.integranteId = memberId;
  return filtro;
}

module.exports = { filtroCuotasPorCobrar };
