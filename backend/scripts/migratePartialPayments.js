const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const dryRun = process.argv.includes('--dry-run');

// Convierte aportes anteriores a abonos parciales:
// - montoPagado = cuota si estaba pagado, 0 en otro caso.
// - pagado sin abonos -> un abono aprobado por la cuota completa (historial).
// - reportado sin abono -> un abono reportado por el saldo (para aprobar/rechazar desde la nueva API).
async function main() {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI no está configurada.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const coleccion = mongoose.connection.collection('contributions');

  const cursor = coleccion.find({});
  let actualizados = 0;
  let omitidos = 0;

  for await (const raw of cursor) {
    const tieneAbonos = Array.isArray(raw.abonos) && raw.abonos.length > 0;
    const pagadoSinAbono = raw.estado === 'pagado' && !tieneAbonos;
    const reportadoSinAbono = raw.estado === 'reportado' && !(raw.abonos || []).some((a) => a.estado === 'reportado');
    const montoPagado = raw.montoPagado !== undefined ? raw.montoPagado : (raw.estado === 'pagado' ? raw.monto : 0);

    const cambios = {};
    if (raw.montoPagado === undefined) cambios.montoPagado = montoPagado;

    if (pagadoSinAbono) {
      cambios.abonos = [{
        _id: new mongoose.Types.ObjectId(),
        monto: raw.monto,
        fecha: raw.fechaPago || raw.createdAt || new Date(),
        referencia: raw.referencia || null,
        estado: 'aprobado',
        reportadoPor: raw.reportadoPor || null,
        revisadoPor: raw.revisadoPor || null,
        fechaRevision: raw.fechaRevision || raw.fechaPago || null,
        motivo: null
      }];
    } else if (reportadoSinAbono) {
      const saldo = Math.max(0, Math.round((raw.monto - montoPagado) * 100) / 100);
      cambios.abonos = [...(raw.abonos || []), {
        _id: new mongoose.Types.ObjectId(),
        monto: saldo,
        fecha: raw.fechaReporte || raw.createdAt || new Date(),
        referencia: raw.referencia || null,
        estado: 'reportado',
        reportadoPor: raw.reportadoPor || null,
        revisadoPor: null,
        fechaRevision: null,
        motivo: null
      }];
    }

    if (Object.keys(cambios).length === 0) {
      omitidos++;
      continue;
    }

    if (dryRun) {
      console.log('[dry-run]', String(raw._id), raw.mes, raw.estado, Object.keys(cambios).join(','));
    } else {
      await coleccion.updateOne({ _id: raw._id }, { $set: cambios });
    }
    actualizados++;
  }

  console.log(dryRun ? 'Simulación terminada.' : 'Migración terminada.');
  console.log('Actualizados:', actualizados, 'Omitidos:', omitidos);
  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error('Error en la migración:', error.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
