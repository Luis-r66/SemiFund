const mongoose = require('mongoose');

// Valida que :id sea un ObjectId antes de llegar al controlador.
// Así devolvemos 400 comprensible en vez de un CastError crudo.
function validateObjectId(req, res, next) {
  const { id } = req.params;
  if (id && !mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: 'El id no es válido' });
  }
  next();
}

module.exports = validateObjectId;
