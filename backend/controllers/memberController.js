const mongoose = require('mongoose');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

function extraerNombre(body) {
  const recibioPartes = body.nombres !== undefined || body.apellidos !== undefined;
  if (recibioPartes) {
    if (
      typeof body.nombres !== 'string' ||
      typeof body.apellidos !== 'string' ||
      !body.nombres.trim() ||
      !body.apellidos.trim()
    ) {
      return null;
    }
    const nombres = body.nombres.trim();
    const apellidos = body.apellidos.trim();
    return { nombres, apellidos, nombre: `${nombres} ${apellidos}` };
  }
  if (typeof body.nombre === 'string' && body.nombre.trim()) {
    return { nombres: null, apellidos: null, nombre: body.nombre.trim() };
  }
  return null;
}

// GET /api/members?activo=true|false  (filtrado por semillero activo)
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

// POST /api/members  { nombres, apellidos, programa, semestre }
const create = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { programa, semestre } = body;
  const nombre = extraerNombre(body);
  if (!nombre || !programa || semestre === undefined) {
    return res.status(400).json({ error: 'nombres, apellidos, programa y semestre son requeridos' });
  }
  const member = await Member.create({
    ...nombre,
    programa,
    semestre,
    activo: true,
    semilleroId: req.semilleroId
  });
  res.status(201).json(member);
});

// PUT /api/members/:id  (solo si pertenece al semillero activo)
// Solo estos campos son editables; evita asignación masiva (semilleroId, _id, etc.)
const CAMPOS_EDITABLES = ['nombre', 'nombres', 'apellidos', 'programa', 'semestre', 'activo'];

const update = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const cambios = {};
  for (const campo of CAMPOS_EDITABLES) {
    if (body[campo] !== undefined) cambios[campo] = body[campo];
  }
  if (Object.keys(cambios).length === 0) {
    return res.status(400).json({ error: 'No hay campos editables en la solicitud' });
  }

  const recibioPartes = body.nombres !== undefined || body.apellidos !== undefined;
  if (recibioPartes) {
    const nombre = extraerNombre(body);
    if (!nombre) return res.status(400).json({ error: 'nombres y apellidos no pueden estar vacíos' });
    cambios.nombres = nombre.nombres;
    cambios.apellidos = nombre.apellidos;
    cambios.nombre = nombre.nombre;
  } else if (cambios.nombre !== undefined && (typeof cambios.nombre !== 'string' || !cambios.nombre.trim())) {
    return res.status(400).json({ error: 'El nombre no puede estar vacío' });
  }

  if (cambios.programa !== undefined && (typeof cambios.programa !== 'string' || !cambios.programa.trim())) {
    return res.status(400).json({ error: 'El programa no puede estar vacío' });
  }
  if (cambios.semestre !== undefined) {
    const semestre = Number(cambios.semestre);
    if (!Number.isInteger(semestre) || semestre < 1 || semestre > 10) {
      return res.status(400).json({ error: 'El semestre debe ser un entero entre 1 y 10' });
    }
    cambios.semestre = semestre;
  }
  if (cambios.activo !== undefined && typeof cambios.activo !== 'boolean') {
    return res.status(400).json({ error: 'activo debe ser true o false' });
  }

  const member = await Member.findOneAndUpdate(
    { _id: req.params.id, semilleroId: req.semilleroId },
    { $set: cambios },
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
