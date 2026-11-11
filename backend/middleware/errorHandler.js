// Middleware centralizado: toda respuesta de error sale en JSON { error }
// Nunca enviamos stack traces al cliente móvil.
function errorHandler(err, req, res, next) {
  // Error de validación de Mongoose (campos requeridos, min/max, enum, regex)
  if (err && err.name === 'ValidationError') {
    const details = {};
    Object.values(err.errors || {}).forEach((e) => {
      details[e.path] = e.message;
    });
    return res.status(400).json({ error: 'Datos inválidos', details });
  }

  // Archivo o cuerpo demasiado grande (express.raw / express.json)
  if (err && err.type === 'entity.too.large') {
    return res.status(413).json({ error: 'El archivo supera el límite permitido de 8 MB' });
  }

  // Id malformado que pasó algún filtro (respaldo del validateObjectId)
  if (err && err.name === 'CastError') {
    return res.status(400).json({ error: 'El id no es válido' });
  }

  // Errores con status personalizado (404, 409) lanzados desde controladores
  if (err && err.status) {
    return res.status(err.status).json({ error: err.message });
  }

  console.error(err);
  return res.status(500).json({ error: 'Error interno del servidor' });
}

module.exports = errorHandler;
