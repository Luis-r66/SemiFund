const mongoose = require('mongoose');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

// GET /api/members?activo=true|false  (filtrado por semillero activo vía X-Semillero-Id)
const list = asyncHandler(async (req, res) => {
  const filter = { semilleroId: req.semilleroId };
  if (req.query.activo !== undefined) {
    if (req.query.activo === 'true') filter.activo = true;
    else if (req.query.activo === 'false') filter.activo = false;
    else return res.status(400).json({ error: 'El filtro activo debe ser true o false' });
  }
  const members = await Member.find(filter).sort({ fechaIngreso: -1 });
  res.status(200).json(members);
});

// GET /api/members/:id  (solo si pertenece al semillero activo)
const getById = asyncHandler(async (req, res) => {
  const member = await Member.findOne({ _id: req.params.id, semilleroId: req.semilleroId });
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(200).json(member);
});

// POST /api/members  { nombre, programa, semestre }
const create = asyncHandler(async (req, res) => {
  const { nombre, programa, semestre } = req.body;
  if (!nombre || !programa || semestre === undefined) {
    return res.status(400).json({ error: 'nombre, programa y semestre son requeridos' });
  }
  const member = await Member.create({
    nombre,
    programa,
    semestre,
    activo: true,
    semilleroId: req.semilleroId
  });
  res.status(201).json(member);
});

// PUT /api/members/:id  (solo si pertenece al semillero activo)
const update = asyncHandler(async (req, res) => {
  const member = await Member.findOneAndUpdate(
    { _id: req.params.id, semilleroId: req.semilleroId },
    req.body,
    { returnDocument: 'after', runValidators: true }
  );
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(200).json(member);
});

// DELETE /api/members/:id -> soft delete (activo=false), 204 sin body
const remove = asyncHandler(async (req, res) => {
  const member = await Member.findOneAndUpdate(
    { _id: req.params.id, semilleroId: req.semilleroId },
    { activo: false },
    { returnDocument: 'after' }
  );
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(204).end();
});

module.exports = { list, getById, create, update, remove };
