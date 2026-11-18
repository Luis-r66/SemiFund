// Solo letras, espacios, apóstrofe, punto y guion. Sin números.
const NOMBRE_REGEX = /^\p{L}[\p{L}' .-]*$/u;
// Nombre del semillero: admite además & y coma, pero tampoco números.
const NOMBRE_SEMILLERO_REGEX = /^\p{L}[\p{L}' .,&\-]*$/u;
// Texto libre para carrera, área, ciudad o centro de costos: letras y signos
// habituales, sin dígitos. Evita que un campo de texto termine con "2026".
const TEXTO_REGEX = /^\p{L}[\p{L}' .,&\-()/]*$/u;

function nombreValido(valor) {
  if (typeof valor !== 'string') return false;
  const texto = valor.trim();
  return texto.length > 0 && texto.length <= 60 && NOMBRE_REGEX.test(texto);
}

function nombreSemilleroValido(valor) {
  if (typeof valor !== 'string') return false;
  const texto = valor.trim();
  return (
    texto.length > 0 &&
    texto.length <= 60 &&
    NOMBRE_SEMILLERO_REGEX.test(texto)
  );
}

// Texto que no debe aceptar números (carrera, ciudad, centro de costos).
// Devuelve { valor } con el texto recortado o { error } con el motivo.
function textoValido(valor, { campo = 'El texto', maximo = 80, minimo = 2 } = {}) {
  if (typeof valor !== 'string') {
    return { error: `${campo} debe ser texto` };
  }
  const texto = valor.trim();
  if (texto.length < minimo) {
    return { error: `${campo} es demasiado corto` };
  }
  if (texto.length > maximo) {
    return { error: `${campo} no puede superar ${maximo} caracteres` };
  }
  if (/\d/.test(texto) || !TEXTO_REGEX.test(texto)) {
    return { error: `${campo} solo puede tener letras y signos, sin números` };
  }
  return { valor: texto };
}

// Documento de identidad: dígitos con puntos o guiones opcionales.
function identificacionValida(valor) {
  if (typeof valor !== 'string') return false;
  const texto = valor.trim();
  return /^[0-9][0-9.\- ]{4,19}$/.test(texto);
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

module.exports = {
  nombreValido,
  nombreSemilleroValido,
  textoValido,
  identificacionValida,
  hoyBogota
};
