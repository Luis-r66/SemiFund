// Lógica de cobro de aportes con abonos parciales.
// estado: ciclo del aporte (pendiente | reportado | pagado | vencido), se sincroniza con sincronizarEstado.
// montoPagado: suma de abonos aprobados. Los aportes anteriores a este modelo no lo tienen:
// si estaban pagados, cubren la cuota completa.

const round = (value) => Math.round(Number(value) * 100) / 100;

function mesActual(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

function montoPagadoDe(contribucion) {
  if (typeof contribucion.montoPagado === 'number') return round(contribucion.montoPagado);
  return contribucion.estado === 'pagado' ? round(contribucion.monto) : 0;
}

function saldoPendiente(contribucion) {
  return Math.max(0, round(contribucion.monto - montoPagadoDe(contribucion)));
}

function estadoCobro(contribucion) {
  if (saldoPendiente(contribucion) === 0) return 'completo';
  return montoPagadoDe(contribucion) > 0 ? 'parcial' : 'sin_pago';
}

function abonoReportado(contribucion) {
  return (contribucion.abonos || []).find((abono) => abono.estado === 'reportado') || null;
}

function estadoEsperado(contribucion, now = new Date()) {
  if (saldoPendiente(contribucion) === 0) return 'pagado';
  if (abonoReportado(contribucion)) return 'reportado';
  return contribucion.mes < mesActual(now) ? 'vencido' : 'pendiente';
}

function sincronizarEstado(contribucion, now = new Date()) {
  const estado = estadoEsperado(contribucion, now);
  contribucion.estado = estado;
  if (estado !== 'pagado') {
    contribucion.fechaPago = null;
  } else if (!contribucion.fechaPago) {
    contribucion.fechaPago = now;
  }
  return contribucion;
}

function agregarAbono(contribucion, { monto, referencia = null, usuarioId, aprobado, now = new Date() }) {
  const valor = round(monto);
  contribucion.abonos.push({
    monto: valor,
    referencia,
    fecha: now,
    estado: aprobado ? 'aprobado' : 'reportado',
    reportadoPor: usuarioId,
    revisadoPor: aprobado ? usuarioId : null,
    fechaRevision: aprobado ? now : null,
    motivo: null
  });
  const abono = contribucion.abonos[contribucion.abonos.length - 1];

  if (aprobado) {
    contribucion.montoPagado = round(montoPagadoDe(contribucion) + valor);
    contribucion.revisadoPor = usuarioId;
    contribucion.fechaRevision = now;
  } else {
    contribucion.reportadoPor = usuarioId;
    contribucion.fechaReporte = now;
    contribucion.referencia = referencia;
    contribucion.revisadoPor = null;
    contribucion.fechaRevision = null;
  }
  contribucion.motivoRechazo = null;
  return abono;
}

function aprobarAbono(contribucion, abono, usuarioId, now = new Date()) {
  abono.estado = 'aprobado';
  abono.revisadoPor = usuarioId;
  abono.fechaRevision = now;
  abono.motivo = null;
  contribucion.montoPagado = round(montoPagadoDe(contribucion) + abono.monto);
  contribucion.revisadoPor = usuarioId;
  contribucion.fechaRevision = now;
  contribucion.motivoRechazo = null;
  return sincronizarEstado(contribucion, now);
}

function rechazarAbono(contribucion, abono, usuarioId, motivo = null, now = new Date()) {
  abono.estado = 'rechazado';
  abono.revisadoPor = usuarioId;
  abono.fechaRevision = now;
  abono.motivo = motivo;
  contribucion.revisadoPor = usuarioId;
  contribucion.fechaRevision = now;
  contribucion.motivoRechazo = motivo;
  return sincronizarEstado(contribucion, now);
}

function anularAbono(contribucion, abono, usuarioId, motivo = null, now = new Date()) {
  abono.estado = 'anulado';
  abono.revisadoPor = usuarioId;
  abono.fechaRevision = now;
  abono.motivo = motivo;
  contribucion.montoPagado = Math.max(0, round(montoPagadoDe(contribucion) - abono.monto));
  return sincronizarEstado(contribucion, now);
}

module.exports = {
  round,
  montoPagadoDe,
  saldoPendiente,
  estadoCobro,
  abonoReportado,
  estadoEsperado,
  sincronizarEstado,
  agregarAbono,
  aprobarAbono,
  rechazarAbono,
  anularAbono
};
