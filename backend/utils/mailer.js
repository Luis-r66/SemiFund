const BREVO_URL = 'https://api.brevo.com/v3/smtp/email';

function mailMode() {
  if (process.env.MAIL_MODE) return String(process.env.MAIL_MODE).toLowerCase();
  return process.env.NODE_ENV === 'production' ? 'brevo' : 'console';
}

function escapeHtml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// Envía el código de recuperación por Brevo. En desarrollo se puede usar
// MAIL_MODE=console para leer el código en la consola sin sacar correos.
async function sendResetCode({ to, nombre, code }) {
  const mode = mailMode();

  if (mode === 'console') {
    console.log(`[MAIL:console] reset_code=${code} email=${to}`);
    return { mode };
  }

  if (mode !== 'brevo') {
    throw new Error(`MAIL_MODE no soportado: ${mode}`);
  }

  const apiKey = process.env.BREVO_API_KEY;
  const from = process.env.MAIL_FROM;
  if (!apiKey || !from) {
    throw new Error('Falta BREVO_API_KEY o MAIL_FROM en las variables de entorno');
  }

  const senderName = process.env.MAIL_FROM_NAME || 'SemiFund';
  const nombreSeguro = escapeHtml(nombre || '');
  const subject = 'Código de recuperación - SemiFund';
  const textContent = [
    `Hola${nombreSeguro ? ` ${nombreSeguro}` : ''},`,
    '',
    `Tu código de recuperación de SemiFund es: ${code}`,
    '',
    'El código vence en 15 minutos y solo se puede usar una vez.',
    'Si no solicitaste este cambio, ignora este mensaje.'
  ].join('\n');
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; color: #16181A; line-height: 1.5;">
      <p>Hola${nombreSeguro ? ` ${nombreSeguro}` : ''},</p>
      <p>Tu código de recuperación de <strong>SemiFund</strong> es:</p>
      <p style="font-size: 30px; letter-spacing: 8px; font-weight: bold; margin: 18px 0;">${code}</p>
      <p>El código vence en <strong>15 minutos</strong> y solo se puede usar una vez.</p>
      <p style="color: #5D6268;">Si no solicitaste este cambio, ignora este mensaje.</p>
    </div>
  `;

  const response = await fetch(BREVO_URL, {
    method: 'POST',
    headers: {
      'api-key': apiKey,
      'Content-Type': 'application/json',
      Accept: 'application/json'
    },
    body: JSON.stringify({
      sender: { name: senderName, email: from },
      to: [{ email: to }],
      subject,
      textContent,
      htmlContent
    })
  });

  if (!response.ok) {
    const detalle = await response.text();
    throw new Error(`Brevo respondió ${response.status}: ${detalle}`);
  }

  return { mode };
}

module.exports = { sendResetCode };
