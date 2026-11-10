const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');
const { marcarVencidos } = require('./contributionController');
const { montoPagadoDe, saldoPendiente } = require('../utils/payments');

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
  await marcarVencidos(req.semilleroId);

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

module.exports = { movimientos };
