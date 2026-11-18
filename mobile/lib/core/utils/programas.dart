/// Carreras y áreas que la app propone como lista. No es una restricción:
/// el usuario puede elegir "Otro" y escribir la suya. El backend acepta
/// cualquier texto sin números.
const List<String> programasAcademicos = <String>[
  'Ingeniería de Software',
  'Ingeniería de Sistemas',
  'Ingeniería de Computación',
  'Ingeniería Electrónica',
  'Ingeniería Industrial',
  'Tecnología en Desarrollo de Software',
  'Licenciatura en Informática',
  'Administración de Empresas',
  'Contaduría Pública',
];

/// Áreas que suele tener un profesor. Se ofrecen cuando el perfil es docente.
const List<String> areasProfesor = <String>[
  'Departamento de Sistemas',
  'Facultad de Ingeniería',
  'Facultad de Ciencias Administrativas',
  'Departamento de Investigación',
  'Bienestar Universitario',
];

const String otroPrograma = 'Otro';

/// Lista según el rol elegido.
List<String> programasPara({required bool esProfesor}) =>
    esProfesor ? areasProfesor : programasAcademicos;

/// Verdadero cuando el texto guardado no está en el catálogo (caso "Otro").
bool esProgramaPersonalizado(String? programa, {required bool esProfesor}) {
  final String valor = (programa ?? '').trim();
  if (valor.isEmpty) return false;
  return !programasPara(esProfesor: esProfesor).any(
    (String item) => item.toLowerCase() == valor.toLowerCase(),
  );
}
