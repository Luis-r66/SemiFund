const MESES = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre'
];

// Convierte '2026-11' en 'noviembre de 2026'. Si el formato no coincide,
// devuelve el valor original para no romper el mensaje.
function mesLegible(valor) {
  const texto = String(valor || '').trim();
  const partes = /^(\d{4})-(\d{2})$/.exec(texto);
  if (!partes) return texto;
  const indice = Number(partes[2]) - 1;
  if (indice < 0 || indice > 11) return texto;
  return `${MESES[indice]} de ${partes[1]}`;
}

module.exports = { mesLegible };
