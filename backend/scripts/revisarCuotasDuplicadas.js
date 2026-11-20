const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Lista las cuotas duplicadas por semillero, integrante y mes. El índice
// único de `contributions` no se puede crear si ya existen duplicados, y
// borrarlos automáticamente perdería abonos y auditoría: este script solo
// informa para que se resuelva a mano.
// Uso: node scripts/revisarCuotasDuplicadas.js
async function main() {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI no está configurada.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const coleccion = mongoose.connection.collection('contributions');

  const grupos = await coleccion
    .aggregate([
      { $match: { $or: [{ tipo: 'cuota' }, { tipo: { $exists: false } }] } },
      {
        $group: {
          _id: {
            semilleroId: '$semilleroId',
            integranteId: '$integranteId',
            mes: '$mes'
          },
          total: { $sum: 1 },
          ids: { $push: '$_id' }
        }
      },
      { $match: { total: { $gt: 1 } } },
      { $sort: { total: -1 } }
    ])
    .toArray();

  if (grupos.length === 0) {
    console.log('Sin cuotas duplicadas.');
  } else {
    console.log(`${grupos.length} grupo(s) con cuotas duplicadas:`);
    for (const grupo of grupos) {
      console.log(
        `  semillero ${grupo._id.semilleroId} · integrante ${grupo._id.integranteId} · ${grupo._id.mes} -> ${grupo.total} cuotas`
      );
      console.log(`    ids: ${grupo.ids.join(', ')}`);
    }
    console.log('');
    console.log('Deja una cuota por grupo y elimina el sobrante desde la app o con la API.');
  }

  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error('Error:', error.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
