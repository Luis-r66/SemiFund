const Notification = require('../models/Notification');
const User = require('../models/User');
const Semillero = require('../models/Semillero');
const { enviarCorreo, escapeHtml } = require('./mailer');

const WEB_URL = process.env.WEB_URL || 'https://luis-r66.github.io/SemiFund/web/';

// Asunto e introducción por tipo de aviso. El detalle concreto viene del
// mensaje que ya se guardó con la notificación, así el correo y la campanita
// cuentan siempre lo mismo.
const PLANTILLAS = {
  abono_reportado: {
    asunto: 'Abono reportado',
    intro: 'Se reportó un abono que necesita tu revisión.'
  },
  abono_aprobado: {
    asunto: 'Abono aprobado',
    intro: 'Tu abono quedó aprobado.'
  },
  abono_rechazado: {
    asunto: 'Abono rechazado',
    intro: 'Tu abono no fue aprobado.'
  },
  cuota_nueva: {
    asunto: 'Nueva cuota',
    intro: 'Se registró una nueva cuota para ti.'
  },
  invitacion_aceptada: {
    asunto: 'Invitación aceptada',
    intro: 'Hay un nuevo integrante activo en el semillero.'
  }
};

function nombreSemillero(valor) {
  const nombre = String(valor || '').trim();
  return nombre || 'tu semillero';
}

// Arma el correo de un aviso. Devuelve null si el tipo no tiene plantilla.
function plantillaDeAviso({ tipo, nombre, semilleroNombre, mensaje }) {
  const plantilla = PLANTILLAS[tipo];
  if (!plantilla) return null;

  const semillero = nombreSemillero(semilleroNombre);
  const saludo = nombre ? `Hola ${nombre},` : 'Hola,';
  const asunto = `${plantilla.asunto} · ${semillero}`;
  const detalle = String(mensaje || '').trim();

  const lineas = [saludo, '', plantilla.intro];
  if (detalle) lineas.push(detalle);
  lineas.push(
    '',
    `Abre SemiFund para ver el detalle: ${WEB_URL}`,
    '',
    `Recibes este aviso porque participas en ${semillero}.`,
    'Puedes desactivar los correos desde la campanita de SemiFund.'
  );
  const textContent = lineas.join('\n');

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; background: #F4F2EE; padding: 28px 16px; color: #16181A;">
      <div style="max-width: 520px; margin: 0 auto; background: #FFFFFF; border: 1px solid #E4E2DE; border-radius: 14px; padding: 30px;">
        <p style="margin: 0 0 4px; font-size: 12px; letter-spacing: 1px; text-transform: uppercase; color: #8A8F94;">SemiFund</p>
        <h1 style="margin: 0 0 18px; font-size: 21px; line-height: 1.3; color: #16181A;">${escapeHtml(plantilla.asunto)}</h1>
        <p style="margin: 0 0 8px; font-size: 15px; line-height: 1.5;">${escapeHtml(saludo)}</p>
        <p style="margin: 0 0 16px; font-size: 15px; line-height: 1.5;">${escapeHtml(plantilla.intro)}</p>
        <p style="margin: 0 0 22px; padding: 14px 16px; background: #F4F2EE; border-radius: 10px; font-size: 15px; line-height: 1.5;">
          ${escapeHtml(detalle)}
        </p>
        <p style="margin: 0 0 24px;">
          <a href="${escapeHtml(WEB_URL)}" style="display: inline-block; background: #16181A; color: #FFFFFF; text-decoration: none; font-size: 14px; padding: 12px 20px; border-radius: 10px;">
            Abrir SemiFund
          </a>
        </p>
        <p style="margin: 0; font-size: 12px; line-height: 1.6; color: #5D6268;">
          Recibes este aviso porque participas en ${escapeHtml(semillero)}.<br />
          Puedes desactivar los correos desde la campanita de SemiFund.
        </p>
      </div>
    </div>
  `;

  return { subject: asunto, textContent, htmlContent };
}

async function marcar(id, estado, detalle = null) {
  try {
    const cambios = { 'correo.estado': estado };
    if (estado === 'enviado') cambios['correo.enviadoEn'] = new Date();
    if (detalle) cambios['correo.detalle'] = String(detalle).slice(0, 300);
    await Notification.updateOne({ _id: id }, { $set: cambios });
  } catch (error) {
    console.error('No se pudo actualizar el estado del correo:', error.message);
  }
}

// Envía los correos de los avisos indicados. El estado se reclama de forma
// atómica antes de enviar, así dos procesos nunca mandan el mismo correo.
async function enviarAvisos(ids = []) {
  if (!ids.length) return 0;

  const avisos = await Notification.find({
    _id: { $in: ids },
    'correo.estado': 'pendiente'
  }).lean();
  if (avisos.length === 0) return 0;

  const userIds = [...new Set(avisos.map((aviso) => String(aviso.userId)))];
  const semilleroIds = [...new Set(avisos.map((aviso) => String(aviso.semilleroId)))];
  const [usuarios, semilleros] = await Promise.all([
    User.find({ _id: { $in: userIds } }).select('nombre email avisosPorCorreo').lean(),
    Semillero.find({ _id: { $in: semilleroIds } }).select('nombre').lean()
  ]);
  const usuarioPorId = new Map(usuarios.map((u) => [String(u._id), u]));
  const semilleroPorId = new Map(semilleros.map((s) => [String(s._id), s.nombre]));

  let enviados = 0;
  for (const aviso of avisos) {
    const usuario = usuarioPorId.get(String(aviso.userId));

    // Fichas sin cuenta no tienen usuario; sin correo o con la preferencia
    // apagada no se envía nada.
    if (!usuario || !usuario.email || usuario.avisosPorCorreo === false) {
      await marcar(aviso._id, 'omitido', usuario ? 'Preferencia desactivada' : 'Sin cuenta');
      continue;
    }

    const reclamado = await Notification.findOneAndUpdate(
      { _id: aviso._id, 'correo.estado': 'pendiente' },
      { $set: { 'correo.estado': 'enviando' } },
      { new: true }
    ).lean();
    if (!reclamado) continue;

    const plantilla = plantillaDeAviso({
      tipo: aviso.tipo,
      nombre: usuario.nombre,
      semilleroNombre: semilleroPorId.get(String(aviso.semilleroId)),
      mensaje: aviso.mensaje
    });
    if (!plantilla) {
      await marcar(aviso._id, 'omitido', 'Sin plantilla');
      continue;
    }

    try {
      await enviarCorreo({
        to: usuario.email,
        subject: plantilla.subject,
        textContent: plantilla.textContent,
        htmlContent: plantilla.htmlContent,
        etiqueta: `aviso_${aviso.tipo}`
      });
      await marcar(aviso._id, 'enviado');
      enviados++;
    } catch (error) {
      console.error('No se pudo enviar el aviso por correo:', error.message);
      await marcar(aviso._id, 'fallido', error.message);
    }
  }

  return enviados;
}

// Los correos salen fuera de la petición: si Brevo tarda o falla, la acción
// del usuario igual queda guardada.
function programarCorreos(ids = []) {
  const limpios = (ids || []).filter(Boolean);
  if (limpios.length === 0) return;
  setImmediate(() => {
    enviarAvisos(limpios).catch((error) => {
      console.error('No se pudieron enviar los avisos por correo:', error.message);
    });
  });
}

module.exports = {
  plantillaDeAviso,
  programarCorreos,
  enviarAvisos,
  PLANTILLAS
};
