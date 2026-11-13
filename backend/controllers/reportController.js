const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');
const { montoPagadoDe, saldoPendiente } = require('../utils/payments');
const { getBalance } = require('../utils/balance');
const { buildTemplate } = require('../services/excelTemplate');
const ExcelJS = require('exceljs');

const HEADERS = [
  'tipo_registro',
  'semillero_codigo',
  'semillero_nombre',
  'periodo',
  'fecha',
  'fecha_pago',
  'integrante_nombre',
  'integrante_email',
  'programa',
  'semestre',
  'descripcion',
  'categoria',
  'monto',
  'moneda',
  'estado',
  'referencia',
  'id_origen'
];

function cell(value) {
  if (value === null || value === undefined) return '';
  let text = String(value);
  if (/^[=+\-@]/.test(text)) text = `'${text}`;
  if (/[",\r\n]/.test(text)) {
    text = `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

function fecha(value) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString().slice(0, 10);
}

function dinero(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return '0.00';
  return number.toFixed(2);
}

const movimientos = asyncHandler(async (req, res) => {

  const [members, contributions, expenses] = await Promise.all([
    Member.find({ semilleroId: req.semilleroId }).populate('userId', 'email'),
    Contribution.find({ semilleroId: req.semilleroId }),
    Expense.find({ semilleroId: req.semilleroId })
  ]);

  const memberById = new Map(members.map((member) => [member._id.toString(), member]));
  const rows = [];

  const filaAporte = ({ item, member, tipo, fechaValor, monto, estado, referencia }) => [
    tipo,
    req.semillero.codigo,
    req.semillero.nombre,
    item.mes,
    fecha(fechaValor),
    tipo === 'aporte' ? fecha(fechaValor) : '',
    member ? member.nombre : '',
    member && member.userId ? member.userId.email : '',
    member ? member.programa : '',
    member && member.semestre != null ? member.semestre : '',
    item.concepto,
    '',
    dinero(monto),
    'COP',
    estado,
    referencia || '',
    item.id
  ];

  for (const item of contributions) {
    const member = memberById.get(item.integranteId.toString());
    const aprobados = item.abonos.filter((abono) => abono.estado === 'aprobado');
    const pagos = aprobados.length > 0
      ? aprobados
      : montoPagadoDe(item) > 0
        ? [{ monto: montoPagadoDe(item), fecha: item.fechaPago || item.createdAt, referencia: item.referencia }]
        : [];

    for (const pago of pagos) {
      rows.push({
        orden: pago.fecha,
        values: filaAporte({ item, member, tipo: 'aporte', fechaValor: pago.fecha, monto: pago.monto, estado: 'aprobado', referencia: pago.referencia })
      });
    }

    const saldo = saldoPendiente(item);
    if (saldo > 0) {
      rows.push({
        orden: item.fechaReporte || item.createdAt,
        values: filaAporte({ item, member, tipo: 'cuota_pendiente', fechaValor: item.createdAt, monto: saldo, estado: item.estado, referencia: item.referencia })
      });
    }
  }

  for (const item of expenses) {
    rows.push({
      orden: item.fecha || item.createdAt,
      values: [
        'gasto',
        req.semillero.codigo,
        req.semillero.nombre,
        '',
        fecha(item.fecha),
        '',
        '',
        '',
        '',
        '',
        item.descripcion,
        item.categoria,
        dinero(item.monto),
        'COP',
        '',
        '',
        item.id
      ]
    });
  }

  rows.sort((a, b) => new Date(a.orden).getTime() - new Date(b.orden).getTime());

  const lines = [
    HEADERS.map(cell).join(','),
    ...rows.map((row) => row.values.map(cell).join(','))
  ];
  const csv = `\uFEFF${lines.join('\r\n')}\r\n`;
  const codigo = String(req.semillero.codigo || 'semillero').replace(/[^A-Za-z0-9_-]/g, '');
  const nombre = `movimientos_${codigo}_${fecha(new Date())}.csv`;

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="${nombre}"`);
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).send(csv);
});

// GET /api/reports/libro.xlsx  (tesorero)
const libro = asyncHandler(async (req, res) => {
  const [members, contributions, expenses, balance] = await Promise.all([
    Member.find({ semilleroId: req.semilleroId }).populate('userId', 'email').sort({ nombre: 1 }),
    Contribution.find({ semilleroId: req.semilleroId }).sort({ mes: 1 }),
    Expense.find({ semilleroId: req.semilleroId }).sort({ fecha: -1 }),
    getBalance(req.semilleroId)
  ]);
  const memberById = new Map(members.map((member) => [member.id, member]));

  const workbook = new ExcelJS.Workbook();
  workbook.created = new Date();

  const integrantes = workbook.addWorksheet('Integrantes');
  integrantes.columns = [
    { header: 'Nombre', key: 'nombre', width: 32 },
    { header: 'Email', key: 'email', width: 30 },
    { header: 'Programa', key: 'programa', width: 30 },
    { header: 'Semestre', key: 'semestre', width: 10 },
    { header: 'Activo', key: 'activo', width: 10 }
  ];
  for (const member of members) {
    integrantes.addRow({
      nombre: member.nombre,
      email: member.userId ? member.userId.email : '',
      programa: member.programa,
      semestre: member.semestre ?? '',
      activo: member.activo ? 'Sí' : 'No'
    });
  }

  const aportes = workbook.addWorksheet('Aportes');
  aportes.columns = [
    { header: 'Integrante', key: 'integrante', width: 32 },
    { header: 'Mes', key: 'mes', width: 10 },
    { header: 'Concepto', key: 'concepto', width: 30 },
    { header: 'Cuota', key: 'monto', width: 14 },
    { header: 'Cobrado', key: 'cobrado', width: 14 },
    { header: 'Saldo', key: 'saldo', width: 14 },
    { header: 'Estado', key: 'estado', width: 14 }
  ];
  for (const item of contributions) {
    const member = memberById.get(item.integranteId.toString());
    aportes.addRow({
      integrante: member ? member.nombre : 'Integrante no disponible',
      mes: item.mes,
      concepto: item.concepto,
      monto: item.monto,
      cobrado: montoPagadoDe(item),
      saldo: saldoPendiente(item),
      estado: item.estado
    });
  }

  const gastos = workbook.addWorksheet('Gastos');
  gastos.columns = [
    { header: 'Fecha', key: 'fecha', width: 14 },
    { header: 'Descripción', key: 'descripcion', width: 36 },
    { header: 'Categoría', key: 'categoria', width: 18 },
    { header: 'Monto', key: 'monto', width: 14 }
  ];
  for (const item of expenses) {
    gastos.addRow({
      fecha: fecha(item.fecha),
      descripcion: item.descripcion,
      categoria: item.categoria,
      monto: item.monto
    });
  }

  const resumen = workbook.addWorksheet('Balance');
  resumen.columns = [
    { header: 'Concepto', key: 'concepto', width: 24 },
    { header: 'Valor', key: 'valor', width: 16 }
  ];
  resumen.addRow({ concepto: 'Total aportado', valor: balance.totalAportado });
  resumen.addRow({ concepto: 'Total gastado', valor: balance.totalGastado });
  resumen.addRow({ concepto: 'Saldo disponible', valor: balance.saldoDisponible });

  for (const sheet of [integrantes, aportes, gastos, resumen]) {
    sheet.getRow(1).font = { bold: true };
  }

  const codigo = String(req.semillero.codigo || 'semillero').replace(/[^A-Za-z0-9_-]/g, '');
  const nombre = `libro_${codigo}_${fecha(new Date())}.xlsx`;
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', `attachment; filename="${nombre}"`);
  res.setHeader('Cache-Control', 'no-store');
  await workbook.xlsx.write(res);
  res.end();
});

// GET /api/reports/plantilla.xlsx  (tesorero)
// Plantilla para importar datos: incluye instrucciones, listas, validaciones
// y los registros actuales del semillero (con ID, para no duplicarlos).
const plantilla = asyncHandler(async (req, res) => {
  const [members, contributions, expenses, balance] = await Promise.all([
    Member.find({ semilleroId: req.semilleroId }).sort({ nombre: 1 }),
    Contribution.find({ semilleroId: req.semilleroId }).sort({ mes: 1 }),
    Expense.find({ semilleroId: req.semilleroId }).sort({ fecha: -1 }),
    getBalance(req.semilleroId)
  ]);

  const { workbook } = buildTemplate({
    semillero: req.semillero,
    members,
    contributions,
    expenses,
    balance
  });

  const codigo = String(req.semillero.codigo || 'semillero').replace(/[^A-Za-z0-9_-]/g, '');
  const nombre = `plantilla_${codigo}_${fecha(new Date())}.xlsx`;
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', `attachment; filename="${nombre}"`);
  res.setHeader('Cache-Control', 'no-store');
  await workbook.xlsx.write(res);
  res.end();
});

module.exports = { movimientos, libro, plantilla };
