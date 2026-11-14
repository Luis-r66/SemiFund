// Reglas de propiedad y salida de un semillero.
// Se aíslan aquí para poder probarlas sin base de datos.

// Normaliza un nombre para comparar sin distinguir mayúsculas, tildes ni espacios extra.
function normalizarNombre(valor) {
  return String(valor || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

// Solo quien creó el semillero puede eliminarlo.
function puedeEliminar(creadoPor, userId) {
  if (!creadoPor || !userId) return false;
  return String(creadoPor) === String(userId);
}

// La confirmación debe coincidir con el nombre exacto (sin importar mayúsculas ni tildes).
function nombreConfirma(nombre, confirmacion) {
  const esperado = normalizarNombre(nombre);
  if (!esperado) return false;
  return esperado === normalizarNombre(confirmacion);
}

// Un integrante puede salir, salvo que sea el único tesorero activo.
function puedeSalir({ esTesorero, tesorerosActivos }) {
  if (!esTesorero) return true;
  return Number(tesorerosActivos) > 1;
}

module.exports = { normalizarNombre, puedeEliminar, nombreConfirma, puedeSalir };
