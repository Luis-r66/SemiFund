require('dotenv').config();
if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  console.error('JWT_SECRET es obligatorio en producción.');
  process.exit(1);
}
const app = require('./app');
const connectDB = require('./config/db');
const { marcarVencidos } = require('./utils/vencimientos');

const PORT = process.env.PORT || 3000;
const INTERVALO_VENCIDOS_MS = 60 * 60 * 1000;

// Las cuotas vencidas se recalculan fuera de las peticiones: antes cada
// lectura de aportes hacía un updateMany. Es idempotente, así que un reintento
// o una instancia extra no causan daño.
async function ejecutarJobVencidos() {
  try {
    const actualizadas = await marcarVencidos();
    if (actualizadas > 0) {
      console.log(`[job] ${actualizadas} cuotas marcadas como vencidas`);
    }
  } catch (error) {
    console.error('[job] No se pudieron marcar las cuotas vencidas:', error.message);
  }
}

connectDB(process.env.MONGODB_URI)
  .then(() => {
    ejecutarJobVencidos();
    const timer = setInterval(ejecutarJobVencidos, INTERVALO_VENCIDOS_MS);
    timer.unref();

    app.listen(PORT, () => console.log(`API lista en http://localhost:${PORT}/api`));
  })
  .catch((err) => {
    console.error('No se pudo conectar a MongoDB:', err.message);
    process.exit(1);
  });
