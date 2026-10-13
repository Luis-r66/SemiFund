const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

const members = require('./routes/members');
const contributions = require('./routes/contributions');
const expenses = require('./routes/expenses');
const balance = require('./routes/balance');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Salud para verificar que el backend está vivo
app.get('/health', (req, res) => res.status(200).json({ ok: true }));

app.use('/api/members', members);
app.use('/api/contributions', contributions);
app.use('/api/expenses', expenses);
app.use('/api/balance', balance);

// 404 para rutas no definidas (siempre JSON)
app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejador centralizado de errores (siempre al final)
app.use(errorHandler);

module.exports = app;
