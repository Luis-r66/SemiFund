const ExcelJS = require('exceljs');
const Member = require('../models/Member');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const { getBalance } = require('../utils/balance');
const { nombreValido, hoyBogota } = require('../utils/validators');
const {
  normalizarTexto,
  normalizarEncabezado,
  mesValido,
  parseMonto,
  parseFecha,
  parseActivo,
  parseEstadoAbono,
  redondear,
  claveAporte,
  claveGasto,
  firmaAbono
} = require('../utils/importValidation');
const {
  montoPagadoDe,
  agregarAbono,
  sincronizarEstado,
  round
} = require('../utils/payments');
const { registrar } = require('../utils/audit');

const HOJAS = ['Integrantes', 'Aportes', 'Abonos', 'Gastos'];
const MAX_FILAS_HOJA = 5000;
const MAX_FILAS_VISTA_PREVIA = 250;

const ENCABEZADOS = {
  Integrantes: ['id', 'nombres', 'apellidos', 'programa', 'semestre', 'tipo_usuario', 'activo'],
  Aportes: [
    'id',
    'integrante_id',
    'integrante',
    'mes',
    'concepto',
    'monto_cuota',
    'pago_inicial',
    'fecha_pago',
    'referencia'
  ],
  Abonos: ['id', 'aporte_id', 'integrante', 'mes', 'monto', 'fecha', 'referencia', 'estado', 'motivo'],
  Gastos: ['id', 'fecha', 'descripcion', 'categoria', 'monto']
};

function errorImportacion(mensaje, status = 400) {
  const error = new Error(mensaje);
  error.status = status;
  return error;
}

function textoDe(valor) {
  if (valor === null || valor === undefined) return '';
  if (valor instanceof Date) {
    return Number.isNaN(valor.getTime()) ? '' : valor.toISOString().slice(0, 10);
  }
  if (typeof valor === 'object') {
    if (Array.isArray(valor.richText)) {
      return valor.richText.map((parte) => parte.text || '').join('').trim();
    }
    if (typeof valor.text === 'string') return valor.text.trim();
    if (valor.result !== undefined && valor.result !== null) return textoDe(valor.result);
    if (valor.hyperlink) return String(valor.hyperlink).trim();
    return '';
  }
  return String(valor).trim();
}

function numeroDe(valor) {
  if (valor && typeof valor === 'object' && valor.result !== undefined) {
    return parseMonto(valor.result);
  }
  return parseMonto(valor);
}

function fechaDeDate(valor) {
  if (!valor) return '';
  const fecha = new Date(valor);
  if (Number.isNaN(fecha.getTime())) return '';
  // Mismo criterio que la plantilla: día calendario en Colombia.
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(fecha);
}

function fechaParaGuardar(iso, hora = 12) {
  return new Date(`${iso}T${String(hora).padStart(2, '0')}:00:00-05:00`);
}

function nombreDe(member) {
  if (!member) return '';
  if (member.nombre) return member.nombre;
  return [member.nombres, member.apellidos].filter(Boolean).join(' ').trim();
}

function miembroExistente(member) {
  return {
    id: member.id,
    tempId: null,
    nombre: nombreDe(member),
    activo: member.activo !== false
  };
}

function filaVacia(fila, claves) {
  return claves.every((clave) => textoDe(fila[clave]) === '');
}

function leerHoja(workbook, nombre) {
  const sheet = workbook.getWorksheet(nombre);
  if (!sheet) throw errorImportacion(`Falta la hoja "${nombre}" en la plantilla.`);
  if (sheet.rowCount > MAX_FILAS_HOJA) {
    throw errorImportacion(`La hoja "${nombre}" supera el máximo de ${MAX_FILAS_HOJA} filas.`);
  }

  const encabezado = sheet.getRow(1);
  const mapa = new Map();
  encabezado.eachCell((cell, columna) => {
    const clave = normalizarEncabezado(textoDe(cell.value));
    if (clave) mapa.set(clave, columna);
  });

  const faltantes = ENCABEZADOS[nombre].filter((clave) => !mapa.has(clave));
  if (faltantes.length > 0) {
    throw errorImportacion(
      `La hoja "${nombre}" no tiene las columnas esperadas: ${faltantes.join(', ')}. Descarga una plantilla nueva.`
    );
  }

  const filas = [];
  for (let numero = 2; numero <= sheet.rowCount; numero += 1) {
    const row = sheet.getRow(numero);
    const fila = { _fila: numero };
    for (const [clave, columna] of mapa.entries()) {
      fila[clave] = row.getCell(columna).value;
    }
    filas.push(fila);
  }
  return filas;
}

function crearContadores() {
  const resumen = {
    integrantes: { nuevos: 0, omitidos: 0, errores: 0 },
    aportes: { nuevos: 0, omitidos: 0, errores: 0 },
    abonos: { nuevos: 0, omitidos: 0, errores: 0 },
    gastos: { nuevos: 0, omitidos: 0, errores: 0 }
  };
  const filas = [];
  let existentes = 0;

  function registrar(hoja, fila, estado, mensaje) {
    const grupo = hoja.toLowerCase();
    if (estado === 'nuevo') resumen[grupo].nuevos += 1;
    else if (estado === 'omitido') resumen[grupo].omitidos += 1;
    else if (estado === 'error') resumen[grupo].errores += 1;
    filas.push({ hoja, fila, estado, mensaje });
  }

  function marcarExistente() {
    existentes += 1;
  }

  function totales() {
    const nuevos = Object.values(resumen).reduce((total, item) => total + item.nuevos, 0);
    const omitidos = Object.values(resumen).reduce((total, item) => total + item.omitidos, 0);
    const errores = Object.values(resumen).reduce((total, item) => total + item.errores, 0);
    return { nuevos, omitidos, errores, existentes };
  }

  return { resumen, filas, registrar, marcarExistente, totales };
}

async function analizarImportacion({ buffer, semilleroId, now = new Date() }) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw errorImportacion('Envía el archivo .xlsx de la plantilla en el cuerpo de la solicitud.');
  }

  const workbook = new ExcelJS.Workbook();
  try {
    await workbook.xlsx.load(buffer);
  } catch (error) {
    throw errorImportacion(
      'No se pudo leer el archivo. Descarga una plantilla nueva y guárdala como .xlsx.'
    );
  }

  for (const hoja of HOJAS) {
    if (!workbook.getWorksheet(hoja)) {
      throw errorImportacion(
        `El archivo no parece ser la plantilla de SemiFund. Falta la hoja "${hoja}".`
      );
    }
  }

  const [members, contributions, expenses, balance] = await Promise.all([
    Member.find({ semilleroId }).sort({ nombre: 1 }),
    Contribution.find({ semilleroId }),
    Expense.find({ semilleroId }),
    getBalance(semilleroId)
  ]);

  const hoy = hoyBogota(now);
  const contadores = crearContadores();
  const plan = { members: [], contributions: [], abonos: [], expenses: [] };

  const membersById = new Map(members.map((member) => [member.id, member]));
  const membersByName = new Map();
  const nombresAmbiguos = new Set();
  for (const member of members) {
    const clave = normalizarTexto(nombreDe(member));
    if (!clave) continue;
    if (membersByName.has(clave)) nombresAmbiguos.add(clave);
    else membersByName.set(clave, member);
  }

  const plannedMembers = new Map();
  const contributionsById = new Map(contributions.map((item) => [item.id, item]));
  const contributionsByKey = new Map();
  for (const item of contributions) {
    const clave = claveAporte(item.integranteId.toString(), item.mes);
    if (!contributionsByKey.has(clave)) contributionsByKey.set(clave, item);
  }

  const plannedContributions = new Map();
  const targetPorClave = new Map();
  const firmasAbono = new Set();
  const gastosExistentes = new Set();
  const gastosPlan = new Set();

  for (const item of contributions) {
    const clave = claveAporte(item.integranteId.toString(), item.mes);
    for (const abono of item.abonos || []) {
      firmasAbono.add(
        firmaAbono(clave, {
          monto: abono.monto,
          fecha: fechaDeDate(abono.fecha),
          referencia: abono.referencia
        })
      );
    }
  }
  for (const item of expenses) {
    gastosExistentes.add(
      claveGasto({
        fecha: fechaDeDate(item.fecha),
        descripcion: item.descripcion,
        monto: item.monto
      })
    );
  }

  let ingresosPlan = 0;
  let gastosPlanTotal = 0;

  function resolverMiembro({ id, nombre }) {
    if (id) {
      const existente = membersById.get(id);
      if (!existente) {
        return { error: 'El integrante_id no existe en este semillero.' };
      }
      if (nombre && normalizarTexto(nombre) !== normalizarTexto(nombreDe(existente))) {
        return { error: 'El integrante_id y el nombre no coinciden.' };
      }
      return { member: miembroExistente(existente) };
    }

    const clave = normalizarTexto(nombre);
    if (!clave) {
      return { error: 'Falta el integrante_id o el nombre completo del integrante.' };
    }
    if (nombresAmbiguos.has(clave)) {
      return { error: 'Hay varios integrantes con ese nombre. Usa integrante_id.' };
    }
    if (membersByName.has(clave)) {
      return { member: miembroExistente(membersByName.get(clave)) };
    }
    if (plannedMembers.has(clave)) {
      return { member: plannedMembers.get(clave) };
    }
    return {
      error: 'No se encontró el integrante. Agrégalo primero en la hoja Integrantes.'
    };
  }

  function targetExistente(item) {
    const clave = claveAporte(item.integranteId.toString(), item.mes);
    if (targetPorClave.has(clave)) return targetPorClave.get(clave);
    const target = {
      id: item.id,
      clave,
      monto: round(item.monto),
      pagado: round(montoPagadoDe(item)),
      planAprobado: 0,
      tieneReportado: (item.abonos || []).some((abono) => abono.estado === 'reportado'),
      nombre: nombreDe(membersById.get(item.integranteId.toString()))
    };
    targetPorClave.set(clave, target);
    return target;
  }

  // 1. Integrantes nuevos
  for (const fila of leerHoja(workbook, 'Integrantes')) {
    if (textoDe(fila.id)) {
      contadores.marcarExistente();
      continue;
    }
    if (
      filaVacia(fila, [
        'nombres',
        'apellidos',
        'programa',
        'semestre',
        'tipo_usuario',
        'activo',
        'nombre_completo'
      ])
    ) {
      continue;
    }

    const nombres = textoDe(fila.nombres);
    const apellidos = textoDe(fila.apellidos);
    const programa = textoDe(fila.programa);
    const semestreTexto = textoDe(fila.semestre);
    const tipo = normalizarTexto(textoDe(fila.tipo_usuario)) || 'estudiante';
    const activo = parseActivo(textoDe(fila.activo));

    if (!nombreValido(nombres) || !nombreValido(apellidos)) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'error',
        'Nombres y apellidos son obligatorios y solo pueden tener letras.'
      );
      continue;
    }
    if (!programa) {
      contadores.registrar('Integrantes', fila._fila, 'error', 'El programa es obligatorio.');
      continue;
    }
    if (programa.length > 160) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'error',
        'El programa no puede superar 160 caracteres.'
      );
      continue;
    }
    if (!['estudiante', 'profesor'].includes(tipo)) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'error',
        'tipo_usuario debe ser estudiante o profesor.'
      );
      continue;
    }
    if (activo === null) {
      contadores.registrar('Integrantes', fila._fila, 'error', 'activo debe ser Sí o No.');
      continue;
    }

    let semestre = null;
    if (tipo === 'estudiante') {
      const numero = Number(semestreTexto);
      if (!semestreTexto || !Number.isInteger(numero) || numero < 1 || numero > 10) {
        contadores.registrar(
          'Integrantes',
          fila._fila,
          'error',
          'El semestre debe ser un entero entre 1 y 10 para estudiantes.'
        );
        continue;
      }
      semestre = numero;
    } else if (semestreTexto) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'error',
        'Un profesor no debe tener semestre.'
      );
      continue;
    }

    const nombre = `${nombres} ${apellidos}`;
    const clave = normalizarTexto(nombre);
    if (plannedMembers.has(clave)) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'error',
        'Este integrante está repetido en el archivo.'
      );
      continue;
    }
    if (nombresAmbiguos.has(clave) || membersByName.has(clave)) {
      contadores.registrar(
        'Integrantes',
        fila._fila,
        'omitido',
        'Ya existe un integrante con ese nombre; se omite para no duplicarlo.'
      );
      continue;
    }

    const tempId = `nuevo:${clave}`;
    plan.members.push({
      tempId,
      data: { nombres, apellidos, nombre, tipoUsuario: tipo, programa, semestre, activo }
    });
    plannedMembers.set(clave, { id: null, tempId, nombre, activo });
    contadores.registrar('Integrantes', fila._fila, 'nuevo', `${nombre} · ${programa}`);
  }

  // 2. Aportes nuevos
  for (const fila of leerHoja(workbook, 'Aportes')) {
    if (textoDe(fila.id)) {
      contadores.marcarExistente();
      continue;
    }
    if (
      filaVacia(fila, [
        'integrante_id',
        'integrante',
        'mes',
        'concepto',
        'monto_cuota',
        'pago_inicial',
        'fecha_pago',
        'referencia'
      ])
    ) {
      continue;
    }

    const integranteId = textoDe(fila.integrante_id);
    const integranteNombre = textoDe(fila.integrante);
    const mes = textoDe(fila.mes);
    const concepto = textoDe(fila.concepto);
    const monto = numeroDe(fila.monto_cuota);
    const pagoInicialTexto = textoDe(fila.pago_inicial);
    const pagoInicial = pagoInicialTexto ? numeroDe(fila.pago_inicial) : 0;
    const fechaPagoTexto = textoDe(fila.fecha_pago);
    const referencia = textoDe(fila.referencia);

    const resolucion = resolverMiembro({ id: integranteId, nombre: integranteNombre });
    if (resolucion.error) {
      contadores.registrar('Aportes', fila._fila, 'error', resolucion.error);
      continue;
    }
    const member = resolucion.member;
    if (!member.activo) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'El integrante está inactivo. Actívalo antes de importar aportes.'
      );
      continue;
    }
    if (!mesValido(mes)) {
      contadores.registrar('Aportes', fila._fila, 'error', 'El mes debe tener formato AAAA-MM.');
      continue;
    }
    if (!concepto) {
      contadores.registrar('Aportes', fila._fila, 'error', 'El concepto es obligatorio.');
      continue;
    }
    if (concepto.length > 200) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'El concepto no puede superar 200 caracteres.'
      );
      continue;
    }
    if (!Number.isFinite(monto) || redondear(monto) <= 0) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'El monto de la cuota debe ser un número mayor a 0.'
      );
      continue;
    }
    if (!Number.isFinite(pagoInicial) || redondear(pagoInicial) < 0) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'El pago inicial debe ser un número igual o mayor a 0.'
      );
      continue;
    }
    if (redondear(pagoInicial) > redondear(monto)) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'El pago inicial no puede superar el monto de la cuota.'
      );
      continue;
    }
    if (referencia.length > 120) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'La referencia no puede superar 120 caracteres.'
      );
      continue;
    }

    let fechaPago = null;
    if (fechaPagoTexto) {
      fechaPago = parseFecha(fila.fecha_pago);
      if (!fechaPago) {
        contadores.registrar(
          'Aportes',
          fila._fila,
          'error',
          'fecha_pago debe ser una fecha real en formato AAAA-MM-DD.'
        );
        continue;
      }
    } else if (redondear(pagoInicial) > 0) {
      fechaPago = hoy;
    }
    if (fechaPago && fechaPago > hoy) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'La fecha de pago no puede ser futura.'
      );
      continue;
    }

    const clave = claveAporte(member.id || member.tempId, mes);
    if (plannedContributions.has(clave)) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'error',
        'Este integrante ya tiene otra cuota para ese mes en el archivo.'
      );
      continue;
    }
    if (contributionsByKey.has(clave)) {
      contadores.registrar(
        'Aportes',
        fila._fila,
        'omitido',
        'Ya existe un aporte de este integrante en ese mes; se omite para no duplicarlo.'
      );
      continue;
    }

    const itemPlan = {
      clave,
      memberId: member.id,
      memberTempId: member.tempId,
      mes,
      concepto,
      monto: redondear(monto),
      pagoInicial: redondear(pagoInicial),
      fechaPago,
      referencia: referencia || null
    };
    plan.contributions.push(itemPlan);
    plannedContributions.set(clave, itemPlan);
    targetPorClave.set(clave, {
      id: null,
      clave,
      monto: itemPlan.monto,
      pagado: 0,
      planAprobado: itemPlan.pagoInicial,
      tieneReportado: false,
      nombre: member.nombre
    });
    ingresosPlan = round(ingresosPlan + itemPlan.pagoInicial);
    if (itemPlan.pagoInicial > 0) {
      firmasAbono.add(
        firmaAbono(clave, {
          monto: itemPlan.pagoInicial,
          fecha: itemPlan.fechaPago,
          referencia: itemPlan.referencia
        })
      );
    }

    contadores.registrar(
      'Aportes',
      fila._fila,
      'nuevo',
      `${member.nombre} · ${mes} · ${concepto}`
    );
  }

  // 3. Abonos nuevos
  for (const fila of leerHoja(workbook, 'Abonos')) {
    if (textoDe(fila.id)) {
      contadores.marcarExistente();
      continue;
    }
    if (
      filaVacia(fila, [
        'aporte_id',
        'integrante',
        'mes',
        'monto',
        'fecha',
        'referencia',
        'estado',
        'motivo'
      ])
    ) {
      continue;
    }

    const aporteId = textoDe(fila.aporte_id);
    const integranteNombre = textoDe(fila.integrante);
    const mes = textoDe(fila.mes);
    const monto = numeroDe(fila.monto);
    const fechaTexto = textoDe(fila.fecha);
    const referencia = textoDe(fila.referencia);
    const motivo = textoDe(fila.motivo);
    const estado = parseEstadoAbono(textoDe(fila.estado));

    let target = null;
    if (aporteId) {
      const existente = contributionsById.get(aporteId);
      if (!existente) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'El aporte_id no existe en este semillero.'
        );
        continue;
      }
      target = targetExistente(existente);
      if (integranteNombre && normalizarTexto(integranteNombre) !== normalizarTexto(target.nombre)) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'El aporte_id y el integrante no coinciden.'
        );
        continue;
      }
      if (mes && mes !== existente.mes) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'El aporte_id y el mes no coinciden.'
        );
        continue;
      }
    } else {
      if (!mesValido(mes)) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'Usa aporte_id o indica integrante y mes (AAAA-MM).'
        );
        continue;
      }
      const resolucion = resolverMiembro({ id: '', nombre: integranteNombre });
      if (resolucion.error) {
        contadores.registrar('Abonos', fila._fila, 'error', resolucion.error);
        continue;
      }
      const member = resolucion.member;
      const clave = claveAporte(member.id || member.tempId, mes);
      if (targetPorClave.has(clave)) {
        target = targetPorClave.get(clave);
      } else if (contributionsByKey.has(clave)) {
        target = targetExistente(contributionsByKey.get(clave));
      } else {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'No se encontró un aporte de ese integrante en ese mes.'
        );
        continue;
      }
    }

    if (!Number.isFinite(monto) || redondear(monto) <= 0) {
      contadores.registrar(
        'Abonos',
        fila._fila,
        'error',
        'El monto del abono debe ser un número mayor a 0.'
      );
      continue;
    }
    if (!estado) {
      contadores.registrar(
        'Abonos',
        fila._fila,
        'error',
        'El estado del abono debe ser aprobado o reportado.'
      );
      continue;
    }
    if (referencia.length > 120) {
      contadores.registrar(
        'Abonos',
        fila._fila,
        'error',
        'La referencia no puede superar 120 caracteres.'
      );
      continue;
    }
    if (motivo.length > 200) {
      contadores.registrar(
        'Abonos',
        fila._fila,
        'error',
        'El motivo no puede superar 200 caracteres.'
      );
      continue;
    }

    let fecha = null;
    if (fechaTexto) {
      fecha = parseFecha(fila.fecha);
      if (!fecha) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'La fecha debe ser una fecha real en formato AAAA-MM-DD.'
        );
        continue;
      }
    } else {
      fecha = hoy;
    }
    if (fecha > hoy) {
      contadores.registrar('Abonos', fila._fila, 'error', 'La fecha no puede ser futura.');
      continue;
    }

    const montoRedondeado = redondear(monto);
    const totalAprobado = round(target.pagado + target.planAprobado);
    if (estado === 'aprobado') {
      if (totalAprobado >= target.monto) {
        contadores.registrar('Abonos', fila._fila, 'error', 'El aporte ya está pagado.');
        continue;
      }
      if (round(totalAprobado + montoRedondeado) > target.monto) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'El abono supera el saldo pendiente del aporte.'
        );
        continue;
      }
    } else {
      if (target.tieneReportado) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'Ya hay un abono reportado esperando revisión para este aporte.'
        );
        continue;
      }
      if (montoRedondeado > round(target.monto - totalAprobado)) {
        contadores.registrar(
          'Abonos',
          fila._fila,
          'error',
          'El abono reportado supera el saldo pendiente del aporte.'
        );
        continue;
      }
    }

    const firma = firmaAbono(target.clave, {
      monto: montoRedondeado,
      fecha,
      referencia
    });
    if (firmasAbono.has(firma)) {
      contadores.registrar(
        'Abonos',
        fila._fila,
        'omitido',
        'Parece un abono ya registrado; se omite para no duplicarlo.'
      );
      continue;
    }

    plan.abonos.push({
      aporteId: target.id,
      clave: target.clave,
      monto: montoRedondeado,
      fecha,
      referencia: referencia || null,
      estado,
      motivo: motivo || null
    });
    firmasAbono.add(firma);

    if (estado === 'aprobado') {
      target.planAprobado = round(target.planAprobado + montoRedondeado);
      ingresosPlan = round(ingresosPlan + montoRedondeado);
    } else {
      target.tieneReportado = true;
    }

    contadores.registrar(
      'Abonos',
      fila._fila,
      'nuevo',
      `${target.nombre} · ${target.clave.split('|')[1]} · ${estado}`
    );
  }

  // 4. Gastos nuevos
  for (const fila of leerHoja(workbook, 'Gastos')) {
    if (textoDe(fila.id)) {
      contadores.marcarExistente();
      continue;
    }
    if (filaVacia(fila, ['fecha', 'descripcion', 'categoria', 'monto'])) {
      continue;
    }

    const descripcion = textoDe(fila.descripcion);
    const categoria = textoDe(fila.categoria);
    const monto = numeroDe(fila.monto);
    const fechaTexto = textoDe(fila.fecha);

    if (!descripcion) {
      contadores.registrar('Gastos', fila._fila, 'error', 'La descripción es obligatoria.');
      continue;
    }
    if (descripcion.length > 200) {
      contadores.registrar(
        'Gastos',
        fila._fila,
        'error',
        'La descripción no puede superar 200 caracteres.'
      );
      continue;
    }
    if (!categoria) {
      contadores.registrar('Gastos', fila._fila, 'error', 'La categoría es obligatoria.');
      continue;
    }
    if (categoria.length > 80) {
      contadores.registrar(
        'Gastos',
        fila._fila,
        'error',
        'La categoría no puede superar 80 caracteres.'
      );
      continue;
    }
    if (!Number.isFinite(monto) || redondear(monto) <= 0) {
      contadores.registrar(
        'Gastos',
        fila._fila,
        'error',
        'El monto del gasto debe ser un número mayor a 0.'
      );
      continue;
    }

    let fecha = null;
    if (fechaTexto) {
      fecha = parseFecha(fila.fecha);
      if (!fecha) {
        contadores.registrar(
          'Gastos',
          fila._fila,
          'error',
          'La fecha debe ser una fecha real en formato AAAA-MM-DD.'
        );
        continue;
      }
    } else {
      fecha = hoy;
    }
    if (fecha > hoy) {
      contadores.registrar('Gastos', fila._fila, 'error', 'La fecha no puede ser futura.');
      continue;
    }

    const montoRedondeado = redondear(monto);
    const clave = claveGasto({ fecha, descripcion, monto: montoRedondeado });
    if (gastosExistentes.has(clave)) {
      contadores.registrar(
        'Gastos',
        fila._fila,
        'omitido',
        'Ya existe un gasto con esa fecha, descripción y monto; se omite para no duplicarlo.'
      );
      continue;
    }
    if (gastosPlan.has(clave)) {
      contadores.registrar('Gastos', fila._fila, 'error', 'Este gasto está repetido en el archivo.');
      continue;
    }

    const disponible = round(balance.saldoDisponible + ingresosPlan - gastosPlanTotal);
    if (montoRedondeado > disponible) {
      contadores.registrar(
        'Gastos',
        fila._fila,
        'error',
        `Saldo insuficiente. Disponible: ${disponible.toFixed(2)} y el gasto es ${montoRedondeado.toFixed(2)}.`
      );
      continue;
    }

    plan.expenses.push({
      descripcion,
      categoria: categoria.toLowerCase(),
      monto: montoRedondeado,
      fecha
    });
    gastosPlan.add(clave);
    gastosPlanTotal = round(gastosPlanTotal + montoRedondeado);
    contadores.registrar(
      'Gastos',
      fila._fila,
      'nuevo',
      `${descripcion} · ${categoria} · ${montoRedondeado}`
    );
  }

  const totales = contadores.totales();
  return {
    plan,
    resumen: contadores.resumen,
    filas: contadores.filas,
    totales,
    puedeImportar: totales.errores === 0 && totales.nuevos > 0,
    hoy
  };
}

async function aplicarImportacion(plan, { semilleroId, usuarioId }) {
  const creados = { integrantes: 0, aportes: 0, abonos: 0, gastos: 0 };
  const memberIdByTemp = new Map();
  const contributionByKey = new Map();

  for (const item of plan.members) {
    const member = await Member.create({ ...item.data, semilleroId });
    memberIdByTemp.set(item.tempId, member.id);
    creados.integrantes += 1;
  }

  for (const item of plan.contributions) {
    const integranteId = item.memberId || memberIdByTemp.get(item.memberTempId);
    if (!integranteId) {
      throw errorImportacion('No se pudo resolver el integrante de un aporte.', 409);
    }
    const now = item.fechaPago ? fechaParaGuardar(item.fechaPago) : new Date();
    const doc = new Contribution({
      integranteId,
      semilleroId,
      monto: item.monto,
      mes: item.mes,
      concepto: item.concepto,
      montoPagado: 0
    });
    if (item.pagoInicial > 0) {
      agregarAbono(doc, {
        monto: item.pagoInicial,
        referencia: item.referencia,
        usuarioId,
        aprobado: true,
        now
      });
    }
    sincronizarEstado(doc, now);
    await doc.save();
    contributionByKey.set(item.clave, doc);
    creados.aportes += 1;
  }

  for (const item of plan.abonos) {
    const doc = item.aporteId
      ? await Contribution.findOne({ _id: item.aporteId, semilleroId })
      : contributionByKey.get(item.clave);
    if (!doc) {
      throw errorImportacion('No se encontró el aporte para registrar uno de los abonos.', 409);
    }
    const now = fechaParaGuardar(item.fecha);
    const abono = agregarAbono(doc, {
      monto: item.monto,
      referencia: item.referencia,
      usuarioId,
      aprobado: item.estado === 'aprobado',
      now
    });
    if (item.motivo) abono.motivo = item.motivo;
    sincronizarEstado(doc, now);
    await doc.save();
    creados.abonos += 1;
  }

  for (const item of plan.expenses) {
    await Expense.create({
      descripcion: item.descripcion,
      categoria: item.categoria,
      monto: item.monto,
      fecha: fechaParaGuardar(item.fecha),
      semilleroId
    });
    creados.gastos += 1;
  }

  await registrar({
    semilleroId,
    usuarioId,
    accion: 'importacion.confirmar',
    entidad: 'importacion',
    detalle: `${creados.integrantes} integrantes · ${creados.aportes} aportes · ${creados.abonos} abonos · ${creados.gastos} gastos`
  });

  return { creados };
}

function vistaPreviaPublica(analisis) {
  return {
    resumen: analisis.resumen,
    totales: analisis.totales,
    puedeImportar: analisis.puedeImportar,
    filas: analisis.filas.slice(0, MAX_FILAS_VISTA_PREVIA),
    filasTruncadas: analisis.filas.length > MAX_FILAS_VISTA_PREVIA
  };
}

module.exports = {
  analizarImportacion,
  aplicarImportacion,
  vistaPreviaPublica,
  MAX_FILAS_VISTA_PREVIA
};
