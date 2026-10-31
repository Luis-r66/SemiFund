const Member = require('../models/Member');

function academicFieldsFromUser(user) {
  const esProfesor = user.tipoUsuario === 'profesor';
  return {
    nombre: user.nombre,
    nombres: user.nombres || null,
    apellidos: user.apellidos || null,
    tipoUsuario: user.tipoUsuario || null,
    programa: user.programa || 'Sin definir',
    semestre: esProfesor ? null : (user.semestre ?? 1)
  };
}

async function syncMembersForUser(user) {
  return Member.updateMany(
    { userId: user._id },
    { $set: academicFieldsFromUser(user) }
  );
}

module.exports = { academicFieldsFromUser, syncMembersForUser };
