const Notification = require('../models/Notification');
const Membership = require('../models/Membership');
const Member = require('../models/Member');
const { dinero } = require('./dinero');
const { programarCorreos } = require('./emailAvisos');

// Quita repetidos y nulos antes de insertar.
function destinatariosUnicos(lista = []) {
  return [...new Set(lista.filter(Boolean).map(String))];
}

// Usuarios con cuenta activa que administran el semillero.
async function tesorerosDe(semilleroId, { excluirUserId = null } = {}) {
  const filtro = { semilleroId, esTesorero: true, estado: 'activo' };
  if (excluirUserId) filtro.userId = { $ne: excluirUserId };
  const membresias = await Membership.find(filtro).select('userId');
  return destinatariosUnicos(membresias.map((m) => m.userId));
}

// Cuenta vinculada al integrante. Las fichas sin cuenta no reciben avisos.
async function cuentaDeIntegrante(memberId, semilleroId) {
  if (!memberId) return null;
  const member = await Member.findOne({ _id: memberId, semilleroId }).select('userId nombre');
  if (!member || !member.userId) return null;
  return { userId: String(member.userId), nombre: member.nombre };
}

// Inserta las notificaciones. Nunca lanza: un aviso fallido no debe tumbar
// la operación que lo originó.
async function notificar({
  semilleroId,
  destinatarios,
  tipo,
  titulo,
  mensaje,
  contributionId = null,
  memberId = null,
  actorNombre = null
}) {
  const ids = destinatariosUnicos(destinatarios);
  if (ids.length === 0) return 0;

  try {
    const docs = ids.map((userId) => ({
      userId,
      semilleroId,
      tipo,
      titulo,
      mensaje,
      contributionId,
      memberId,
      actorNombre
    }));
    const creadas = await Notification.insertMany(docs, { ordered: false });
    // El correo se envía en segundo plano y sin duplicados.
    programarCorreos(creadas.map((doc) => doc._id));
    return creadas.length;
  } catch (error) {
    console.error('No se pudo registrar la notificación:', error.message);
    // insertMany puede insertar parte del lote antes de fallar.
    if (error.insertedDocs && error.insertedDocs.length > 0) {
      programarCorreos(error.insertedDocs.map((doc) => doc._id));
      return error.insertedDocs.length;
    }
    return 0;
  }
}

module.exports = {
  notificar,
  tesorerosDe,
  cuentaDeIntegrante,
  destinatariosUnicos,
  dinero
};
