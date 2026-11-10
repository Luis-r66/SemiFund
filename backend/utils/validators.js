// Solo letras, espacios, apóstrofe, punto y guion. Sin números.
const NOMBRE_REGEX = /^\p{L}[\p{L}' .-]*$/u;

function nombreValido(valor) {
  if (typeof valor !== 'string') return false;
  const texto = valor.trim();
  return texto.length > 0 && texto.length <= 60 && NOMBRE_REGEX.test(texto);
}

// Fecha de hoy en Colombia como YYYY-MM-DD, independiente de la zona del servidor.
function hoyBogota(now = new Date()) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(now);
}

module.exports = { nombreValido, hoyBogota };
