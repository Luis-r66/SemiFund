const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');
const { requireAuth, requireSemillero } = require('./middleware/auth');

const members = require('./routes/members');
const contributions = require('./routes/contributions');
const expenses = require('./routes/expenses');
const balance = require('./routes/balance');
const auth = require('./routes/auth');
const semilleros = require('./routes/semilleros');

const app = express();

// Render está detrás de un proxy; esto permite rate limiting por IP real.
app.set('trust proxy', 1);

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Salud para verificar que el backend está vivo
app.get('/health', (req, res) => res.status(200).json({ ok: true }));

// Rutas de autenticación (públicas, sin token previo)
app.use('/api/auth', auth);

// Rutas de semilleros (requieren token, pero no X-Semillero-Id para crear/unirse/listar)
app.use('/api/semilleros', semilleros);

// Rutas protegidas que requieren autenticación Y membresía activa en un semillero
app.use('/api/members', requireAuth, requireSemillero, members);
app.use('/api/contributions', requireAuth, requireSemillero, contributions);
app.use('/api/expenses', requireAuth, requireSemillero, expenses);
app.use('/api/balance', requireAuth, requireSemillero, balance);

// 404 para rutas no definidas (siempre JSON)
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejador centralizado de errores (siempre al final)
app.use(errorHandler);

module.exports = app;
