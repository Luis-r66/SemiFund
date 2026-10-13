const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

// GET /api/members?activo=true|false
const list = asyncHandler(async (req, res) => {
  const filter = {};
  if (req.query.activo !== undefined) {
    if (req.query.activo === 'true') filter.activo = true;
    else if (req.query.activo === 'false') filter.activo = false;
    else return res.status(400).json({ error: 'El filtro activo debe ser true o false' });
  }
  const members = await Member.find(filter).sort({ fechaIngreso: -1 });
  res.status(200).json(members);
});

// GET /api/members/:id
const getById = asyncHandler(async (req, res) => {
  const member = await Member.findById(req.params.id);
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(200).json(member);
});

// POST /api/members  { nombre, programa, semestre }
const create = asyncHandler(async (req, res) => {
  const { nombre, programa, semestre } = req.body;
  if (!nombre || !programa || semestre === undefined) {
    return res.status(400).json({ error: 'nombre, programa y semestre son requeridos' });
  }
  const member = await Member.create({ nombre, programa, semestre });
  res.status(201).json(member);
});

// PUT /api/members/:id
const update = asyncHandler(async (req, res) => {
  const member = await Member.findByIdAndUpdate(req.params.id, req.body, {
    returnDocument: 'after',
    runValidators: true
  });
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(200).json(member);
});

// DELETE /api/members/:id -> soft delete (activo=false), 204 sin body
const remove = asyncHandler(async (req, res) => {
  const member = await Member.findByIdAndUpdate(
    req.params.id,
    { activo: false },
    { returnDocument: 'after' }
  );
  if (!member) return res.status(404).json({ error: 'Integrante no encontrado' });
  res.status(204).end();
});

module.exports = { list, getById, create, update, remove };
