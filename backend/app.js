const express = require('express');
const path = require('path');
const cors = require('cors');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');
const { requireAuth, requireSemillero, requireTesorero } = require('./middleware/auth');

const members = require('./routes/members');
const contributions = require('./routes/contributions');
const expenses = require('./routes/expenses');
const balance = require('./routes/balance');
const summary = require('./routes/summary');
const notifications = require('./routes/notifications');
const auth = require('./routes/auth');
const semilleros = require('./routes/semilleros');
const reports = require('./routes/reports');
const audit = require('./routes/audit');
const imports = require('./routes/imports');

const app = express();

// Render está detrás de un proxy; esto permite rate limiting por IP real.
app.set('trust proxy', 1);

// Solo la web publicada y el desarrollo local. La app Android no envía
// Origin, así que se permite la petición sin ese encabezado.
const origenesPermitidos = String(
  process.env.CORS_ORIGINS ||
    'https://luis-r66.github.io,http://localhost:8081,http://127.0.0.1:8081,http://localhost:8080,http://127.0.0.1:8080'
)
  .split(',')
  .map((origen) => origen.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origen, callback) {
      if (!origen || origenesPermitidos.includes(origen)) {
        return callback(null, true);
      }
      return callback(null, false);
    }
  })
);
app.use(express.json());
app.use(morgan('dev'));

// Salud para verificar que el backend está vivo
app.get('/health', (req, res) => res.status(200).json({ ok: true }));

// Páginas públicas que pide la pantalla de consentimiento de Google.
// La app Android consume /api/*; estas dos rutas solo son informativas.
app.get('/', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));
app.get('/privacidad', (req, res) => res.sendFile(path.join(__dirname, 'public', 'privacidad.html')));

// Rutas de autenticación (públicas, sin token previo)
app.use('/api/auth', auth);

// Rutas de semilleros (requieren token, pero no X-Semillero-Id para crear/unirse/listar)
app.use('/api/semilleros', semilleros);

// Rutas protegidas que requieren autenticación Y membresía activa en un semillero
app.use('/api/members', requireAuth, requireSemillero, members);
app.use('/api/contributions', requireAuth, requireSemillero, contributions);
app.use('/api/expenses', requireAuth, requireSemillero, expenses);
app.use('/api/balance', requireAuth, requireSemillero, balance);
app.use('/api/summary', requireAuth, requireSemillero, summary);
app.use('/api/notifications', requireAuth, requireSemillero, notifications);
app.use('/api/reports', reports);
app.use('/api/audit', requireAuth, requireSemillero, requireTesorero, audit);
app.use('/api/import', requireAuth, requireSemillero, requireTesorero, imports);

// 404 para rutas no definidas (siempre JSON)
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejador centralizado de errores (siempre al final)
app.use(errorHandler);

module.exports = app;
