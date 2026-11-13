const Notification = require('../models/Notification');
const Membership = require('../models/Membership');
const Member = require('../models/Member');

const formatoCop = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0
});

function dinero(valor) {
  return formatoCop.format(Number(valor) || 0);
}

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
    return creadas.length;
  } catch (error) {
    console.error('No se pudo registrar la notificación:', error.message);
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
