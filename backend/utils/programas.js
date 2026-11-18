// Catálogo de carreras y áreas que ofrece la app como lista de opciones.
// No es una restricción: el usuario puede elegir "Otro" y escribir la suya.
// El backend acepta cualquier texto sin números, así que agregar una carrera
// nueva aquí solo cambia lo que se ve en la lista.

const PROGRAMAS = [
  'Ingeniería de Software',
  'Ingeniería de Sistemas',
  'Ingeniería de Computación',
  'Ingeniería Electrónica',
  'Ingeniería Industrial',
  'Tecnología en Desarrollo de Software',
  'Licenciatura en Informática',
  'Administración de Empresas',
  'Contaduría Pública'
];

// Áreas que suele tener un profesor. Se ofrecen cuando el perfil es docente.
const AREAS_PROFESOR = [
  'Departamento de Sistemas',
  'Facultad de Ingeniería',
  'Facultad de Ciencias Administrativas',
  'Departamento de Investigación',
  'Bienestar Universitario'
];

const OTRO = 'Otro';

function esOpcionConocida(valor) {
  const texto = typeof valor === 'string' ? valor.trim() : '';
  return (
    PROGRAMAS.some((programa) => programa.toLowerCase() === texto.toLowerCase()) ||
    AREAS_PROFESOR.some((area) => area.toLowerCase() === texto.toLowerCase())
  );
}

module.exports = { PROGRAMAS, AREAS_PROFESOR, OTRO, esOpcionConocida };
