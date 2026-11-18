// Arma el objeto de datos que recibe una plantilla. Todo sale de la base del
// semillero; los campos del formulario (viaje, hora, observaciones) llegan
// desde la app y se validan antes de llamar aquí.

const Member = require('../models/Member');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const { getBalance } = require('../utils/balance');
const { montoPagadoDe, saldoPendiente, round } = require('../utils/payments');
const { hoyBogota } = require('../utils/validators');

const MESES = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

const moneda = new Intl.NumberFormat('es-CO', { maximumFractionDigits: 0 });

function fechaLarga(fecha) {
  return `${fecha.getDate()} de ${MESES[fecha.getMonth()]} de ${fecha.getFullYear()}`;
}

function fechaCorta(fecha) {
  const dia = String(fecha.getDate()).padStart(2, '0');
  const mes = String(fecha.getMonth() + 1).padStart(2, '0');
  return `${dia}/${mes}/${fecha.getFullYear()}`;
}

// La fecha del gasto se guarda al mediodía de Colombia: se toma tal cual para
// que no se corra un día al convertir a UTC.
function fechaDeGasto(fecha) {
  if (!fecha) return '';
  return fechaCorta(new Date(fecha));
}

function mesTexto(mes) {
  if (typeof mes === 'string' && /^\d{4}-\d{2}$/.test(mes)) {
    const [anio, numero] = mes.split('-').map(Number);
    return `${MESES[numero - 1]} de ${anio}`;
  }
  const hoy = new Date();
  return `${MESES[hoy.getMonth()]} de ${hoy.getFullYear()}`;
}

// Etiqueta para la diferencia: en contabilidad, un negativo va entre paréntesis.
function diferenciaFormateada(valor) {
  const numero = round(valor);
  if (numero < 0) return `(${moneda.format(Math.abs(numero))})`;
  return moneda.format(numero);
}

function rangoMes(mes) {
  if (typeof mes !== 'string' || !/^\d{4}-\d{2}$/.test(mes)) return null;
  const [anio, numero] = mes.split('-').map(Number);
  return {
    $gte: new Date(anio, numero - 1, 1),
    $lt: new Date(anio, numero, 1)
  };
}

async function construirDatos({ semillero, profesor, mes, campos = {} }) {
  const filtroMes = rangoMes(mes);

  const [miembros, cuotas, gastos, balance] = await Promise.all([
    Member.find({ semilleroId: semillero._id, activo: true }).sort({ fechaIngreso: 1 }),
    Contribution.find({
      semilleroId: semillero._id,
      ...(filtroMes ? { mes } : {})
    }).sort({ mes: 1 }),
    Expense.find({
      semilleroId: semillero._id,
      ...(filtroMes ? { fecha: filtroMes } : {})
    }).sort({ fecha: 1 }),
    getBalance(semillero._id)
  ]);

  const nombres = new Map(miembros.map((m) => [m.id, m.nombre]));
  const porIntegrante = new Map();
  for (const cuota of cuotas) {
    const clave = String(cuota.integranteId);
    const actual = porIntegrante.get(clave) || {
      pagadas: 0,
      pendientes: 0,
      aportado: 0,
      pendiente: 0
    };
    if (cuota.estado === 'pagado') actual.pagadas += 1;
    else actual.pendientes += 1;
    actual.aportado += montoPagadoDe(cuota);
    actual.pendiente += saldoPendiente(cuota);
    porIntegrante.set(clave, actual);
  }

  const integrantes = miembros.map((member) => {
    const datos = porIntegrante.get(member.id) || {
      pagadas: 0,
      pendientes: 0,
      aportado: 0,
      pendiente: 0
    };
    return {
      nombre: member.nombre,
      nombres: member.nombres || member.nombre,
      apellidos: member.apellidos || '',
      identificacion: member.identificacion || '',
      programa: member.programa || '',
      semestre: member.semestre ?? '',
      tipo: member.tipoUsuario || 'estudiante',
      estado: member.activo ? 'Activo' : 'Inactivo',
      cuotasPagadas: datos.pagadas,
      cuotasPendientes: datos.pendientes,
      totalAportado: moneda.format(datos.aportado),
      saldoPendiente: moneda.format(datos.pendiente)
    };
  });

  const listaGastos = gastos.map((gasto) => ({
    fecha: fechaDeGasto(gasto.fecha),
    proveedor: gasto.proveedor || '',
    nit: gasto.nit || '',
    factura: gasto.numeroFactura || '',
    concepto: gasto.descripcion,
    categoria: gasto.categoria,
    tasa: gasto.tasaCambio ? moneda.format(gasto.tasaCambio) : 'NA',
    valor: moneda.format(gasto.monto),
    monto: gasto.monto
  }));

  const listaMovimientos = cuotas.map((cuota) => ({
    fecha: fechaDeGasto(cuota.createdAt || cuota.fechaPago),
    tipo: cuota.tipo === 'aporte' ? 'Aporte' : 'Cuota',
    concepto: cuota.concepto || '',
    mes: mesTexto(cuota.mes),
    monto: moneda.format(cuota.monto),
    abonado: moneda.format(montoPagadoDe(cuota)),
    saldo: moneda.format(saldoPendiente(cuota)),
    estado: cuota.estado,
    integrante: nombres.get(String(cuota.integranteId)) || ''
  }));

  const totalFacturas = round(listaGastos.reduce((suma, gasto) => suma + Number(gasto.monto || 0), 0));
  const valorEntregado = Number(campos.valorEntregado) || 0;

  const hoy = new Date(`${hoyBogota()}T12:00:00-05:00`);
  const viaje = {
    inicio: campos.inicio || '',
    fin: campos.fin || '',
    ciudades: campos.ciudades || '',
    objeto: campos.objeto || '',
    valorEntregado: moneda.format(valorEntregado)
  };

  return {
    semillero: {
      nombre: semillero.nombre,
      codigo: semillero.codigo || '',
      ciudad: semillero.ciudad || '',
      centroCostos: semillero.centroCostos || '',
      saldoInicial: moneda.format(balance.saldoInicial),
      saldoDisponible: moneda.format(balance.saldoDisponible),
      totalAportado: moneda.format(balance.totalAportado),
      totalGastado: moneda.format(balance.totalGastado),
      miembros: integrantes.length
    },
    profesor: {
      nombre: profesor.nombre,
      nombres: profesor.nombres || profesor.nombre,
      apellidos: profesor.apellidos || '',
      identificacion: profesor.identificacion || '',
      cargo: profesor.cargo || '',
      programa: profesor.programa || '',
      email: profesor.email || ''
    },
    periodo: {
      mes: mes || hoyBogota().slice(0, 7),
      mesTexto: mesTexto(mes),
      fecha: fechaLarga(hoy),
      fechaCorta: hoyBogota(),
      ciudad: campos.ciudad || semillero.ciudad || '',
      anio: String(hoy.getFullYear())
    },
    viaje,
    documento: {
      hora: campos.hora || '',
      lugar: campos.lugar || campos.ciudad || semillero.ciudad || '',
      observaciones: campos.observaciones || ''
    },
    firma: {
      nombre: profesor.nombre,
      documento: profesor.identificacion || '',
      cargo: profesor.cargo || (profesor.tipoUsuario === 'profesor' ? 'Docente' : '')
    },
    integrantes,
    gastos: listaGastos,
    movimientos: listaMovimientos,
    totales: {
      facturas: moneda.format(totalFacturas),
      aportes: moneda.format(balance.totalAportado),
      gastos: moneda.format(balance.totalGastado),
      saldo: moneda.format(balance.saldoDisponible),
      diferencia: diferenciaFormateada(valorEntregado - totalFacturas),
      integrantes: integrantes.length
    }
  };
}

module.exports = { construirDatos, mesTexto, fechaLarga, fechaCorta, MESES };
