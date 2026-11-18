const path = require('path');
const mongoose = require('mongoose');

const DocumentTemplate = require('../models/DocumentTemplate');
const asyncHandler = require('../middleware/asyncHandler');
const { registrar } = require('../utils/audit');
const { catalogo, leerEtiquetas, generarDocumento } = require('../services/documentEngine');
const { construirDatos } = require('../services/documentData');
const {
  estaConfigurado,
  subirPlantilla,
  borrarPlantilla,
  descargarPlantilla
} = require('../services/cloudinary');

const TIPOS = { '.docx': 'docx', '.xlsx': 'xlsx' };
const MIME = {
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
};
const MAX_NOMBRE = 80;
const CAMPOS_TEXTO = ['inicio', 'fin', 'ciudades', 'objeto', 'hora', 'lugar', 'observaciones', 'ciudad'];

function cuerpo(req) {
  return req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
}

function limpiarNombre(valor, respaldo) {
  const texto = typeof valor === 'string' ? valor.trim() : '';
  const base = texto || respaldo || 'Plantilla';
  return base.slice(0, MAX_NOMBRE);
}

function slug(texto) {
  return String(texto)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase()
    .slice(0, 60) || 'documento';
}

// GET /api/documents/tags
const etiquetas = asyncHandler(async (req, res) => {
  res.status(200).json(catalogo());
});

// GET /api/documents/templates
const listar = asyncHandler(async (req, res) => {
  const plantillas = await DocumentTemplate.find({ semilleroId: req.semilleroId }).sort({ updatedAt: -1 });
  res.status(200).json(
    plantillas.map((plantilla) => ({
      ...plantilla.toJSON(),
      puedeEliminar:
        Boolean(req.membership.esTesorero) ||
        String(plantilla.creadoPor) === String(req.userId)
    }))
  );
});

// POST /api/documents/templates  (multipart: archivo, nombre?)
const subir = asyncHandler(async (req, res) => {
  if (!req.file || !req.file.buffer || req.file.buffer.length === 0) {
    return res.status(400).json({ error: 'Adjunta el archivo de la plantilla' });
  }
  const extension = path.extname(req.file.originalname || '').toLowerCase();
  const tipo = TIPOS[extension];
  if (!tipo) {
    return res.status(415).json({ error: 'La plantilla debe ser un archivo .docx o .xlsx' });
  }
  if (!estaConfigurado()) {
    return res.status(503).json({
      error: 'El almacenamiento de plantillas no está configurado'
    });
  }

  let lectura;
  try {
    lectura = await leerEtiquetas(req.file.buffer, tipo);
  } catch (_) {
    return res.status(422).json({
      error: `No pudimos leer el archivo. ¿Está dañado o tiene contraseña? Guarda de nuevo el .${tipo} y vuelve a intentarlo.`
    });
  }
  if (lectura.desconocidas.length > 0) {
    return res.status(422).json({
      error: `Hay etiquetas que la app no puede llenar: ${lectura.desconocidas
        .map((etiqueta) => `{{${etiqueta}}}`)
        .join(', ')}`,
      desconocidas: lectura.desconocidas
    });
  }

  const nombre = limpiarNombre(
    cuerpo(req).nombre,
    path.basename(req.file.originalname || '', extension)
  );

  let subida;
  try {
    subida = await subirPlantilla(req.file.buffer, {
      publicId: new mongoose.Types.ObjectId().toString(),
      extension: tipo
    });
  } catch (error) {
    return res.status(error.status || 502).json({ error: error.message });
  }

  const plantilla = await DocumentTemplate.create({
    semilleroId: req.semilleroId,
    nombre,
    tipo,
    url: subida.url,
    publicId: subida.publicId,
    bytes: subida.bytes || req.file.size || null,
    etiquetas: lectura.etiquetas,
    creadoPor: req.userId
  });

  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'documento.plantilla_subida',
    entidad: 'plantilla',
    entidadId: plantilla.id,
    detalle: `${nombre} · ${tipo}`
  });

  res.status(201).json({
    ...plantilla.toJSON(),
    puedeEliminar: true
  });
});

// PUT /api/documents/templates/:id  (multipart: archivo, nombre?)
// Reemplaza el archivo conservando el nombre: es el caso de la profesora
// cuando le cambian el formato cada semestre.
const reemplazar = asyncHandler(async (req, res) => {
  const plantilla = await DocumentTemplate.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!plantilla) return res.status(404).json({ error: 'Plantilla no encontrada' });

  if (!req.file || !req.file.buffer || req.file.buffer.length === 0) {
    return res.status(400).json({ error: 'Adjunta el archivo nuevo' });
  }
  const extension = path.extname(req.file.originalname || '').toLowerCase();
  const tipo = TIPOS[extension];
  if (!tipo) {
    return res.status(415).json({ error: 'La plantilla debe ser un archivo .docx o .xlsx' });
  }
  if (!estaConfigurado()) {
    return res.status(503).json({ error: 'El almacenamiento de plantillas no está configurado' });
  }

  let lectura;
  try {
    lectura = await leerEtiquetas(req.file.buffer, tipo);
  } catch (_) {
    return res.status(422).json({
      error: `No pudimos leer el archivo. ¿Está dañado o tiene contraseña?`
    });
  }
  if (lectura.desconocidas.length > 0) {
    return res.status(422).json({
      error: `Hay etiquetas que la app no puede llenar: ${lectura.desconocidas
        .map((etiqueta) => `{{${etiqueta}}}`)
        .join(', ')}`,
      desconocidas: lectura.desconocidas
    });
  }

  const anterior = plantilla.publicId;
  let subida;
  try {
    subida = await subirPlantilla(req.file.buffer, {
      publicId: new mongoose.Types.ObjectId().toString(),
      extension: tipo
    });
  } catch (error) {
    return res.status(error.status || 502).json({ error: error.message });
  }

  plantilla.nombre = limpiarNombre(cuerpo(req).nombre, plantilla.nombre);
  plantilla.tipo = tipo;
  plantilla.url = subida.url;
  plantilla.publicId = subida.publicId;
  plantilla.bytes = subida.bytes || req.file.size || null;
  plantilla.etiquetas = lectura.etiquetas;
  await plantilla.save();
  await borrarPlantilla(anterior);

  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'documento.plantilla_reemplazada',
    entidad: 'plantilla',
    entidadId: plantilla.id,
    detalle: `${plantilla.nombre} · ${tipo}`
  });

  res.status(200).json({
    ...plantilla.toJSON(),
    puedeEliminar: Boolean(req.membership.esTesorero) || String(plantilla.creadoPor) === String(req.userId)
  });
});

// DELETE /api/documents/templates/:id
const eliminar = asyncHandler(async (req, res) => {
  const plantilla = await DocumentTemplate.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!plantilla) return res.status(404).json({ error: 'Plantilla no encontrada' });

  const esCreador = String(plantilla.creadoPor) === String(req.userId);
  if (!esCreador && !req.membership.esTesorero) {
    return res.status(403).json({
      error: 'Solo quien subió la plantilla o el tesorero puede eliminarla'
    });
  }

  await DocumentTemplate.deleteOne({ _id: plantilla._id });
  await borrarPlantilla(plantilla.publicId);
  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'documento.plantilla_eliminada',
    entidad: 'plantilla',
    entidadId: plantilla.id,
    detalle: plantilla.nombre
  });
  res.status(204).end();
});

function leerCampos(body) {
  const campos = {};
  for (const clave of CAMPOS_TEXTO) {
    const valor = body[clave];
    if (valor === undefined || valor === null) continue;
    if (typeof valor !== 'string') {
      return { error: `El campo ${clave} debe ser texto` };
    }
    if (valor.length > 500) {
      return { error: `El campo ${clave} no puede superar 500 caracteres` };
    }
    campos[clave] = valor.trim();
  }
  if (body.valorEntregado !== undefined && body.valorEntregado !== null && body.valorEntregado !== '') {
    const numero = Number(body.valorEntregado);
    if (!Number.isFinite(numero) || numero < 0) {
      return { error: 'El valor entregado debe ser un número mayor o igual a 0' };
    }
    campos.valorEntregado = numero;
  }
  return { campos };
}

// POST /api/documents/templates/:id/generate  { mes?, inicio?, fin?, ... }
// Devuelve el archivo lleno como descarga. No se guarda en el servidor.
const generar = asyncHandler(async (req, res) => {
  const plantilla = await DocumentTemplate.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!plantilla) return res.status(404).json({ error: 'Plantilla no encontrada' });

  const body = cuerpo(req);
  if (body.mes !== undefined && body.mes !== null && body.mes !== '') {
    if (typeof body.mes !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(body.mes)) {
      return res.status(400).json({ error: 'El mes debe tener formato YYYY-MM' });
    }
  }
  const lectura = leerCampos(body);
  if (lectura.error) return res.status(400).json({ error: lectura.error });

  let buffer;
  try {
    buffer = await descargarPlantilla(plantilla.url);
  } catch (error) {
    return res.status(error.status || 502).json({ error: error.message });
  }

  let datos;
  let archivo;
  try {
    datos = await construirDatos({
      semillero: req.semillero,
      profesor: req.user,
      mes: body.mes || null,
      campos: lectura.campos
    });
    archivo = await generarDocumento(buffer, plantilla.tipo, datos);
  } catch (error) {
    console.error('No se pudo generar el documento:', error.message);
    return res.status(500).json({
      error: 'No pudimos generar el documento con esta plantilla. Revisa las etiquetas e intenta de nuevo.'
    });
  }

  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'documento.generado',
    entidad: 'plantilla',
    entidadId: plantilla.id,
    detalle: `${plantilla.nombre}${body.mes ? ` · ${body.mes}` : ''}`
  });

  const periodo = body.mes ? `-${body.mes}` : '';
  const nombreArchivo = `${slug(plantilla.nombre)}${periodo}.${plantilla.tipo}`;
  res.setHeader('Content-Type', MIME[plantilla.tipo]);
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${nombreArchivo}"; filename*=UTF-8''${encodeURIComponent(nombreArchivo)}`
  );
  res.setHeader('Content-Length', String(archivo.length));
  res.status(200).send(archivo);
});

module.exports = { etiquetas, listar, subir, reemplazar, eliminar, generar };
