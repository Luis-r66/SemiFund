const ExcelJS = require('exceljs');
const { montoPagadoDe, saldoPendiente, round } = require('../utils/payments');

const PLANTILLA_VERSION = 1;

const COLOR = {
  ink: 'FF26282B',
  ink2: 'FF5D6268',
  ink3: 'FF93989E',
  line: 'FFE6E7E9',
  header: 'FF333638',
  existing: 'FFF2F2F0',
  paper: 'FFFFFFFF'
};

const CATEGORIAS = [
  'Infraestructura',
  'Eventos',
  'Difusión',
  'Software',
  'Materiales',
  'Otros'
];

const TIPOS_USUARIO = ['estudiante', 'profesor'];
const ESTADOS_ABONO = ['aprobado', 'reportado'];
const OPCIONES_ACTIVO = ['Sí', 'No'];

function fechaTexto(valor) {
  if (!valor) return '';
  const fecha = new Date(valor);
  if (Number.isNaN(fecha.getTime())) return '';
  // Día calendario en Colombia: un abono de las 11 p. m. no debe saltar al día siguiente.
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(fecha);
}

function fechaHoraBogota(now = new Date()) {
  return new Intl.DateTimeFormat('es-CO', {
    timeZone: 'America/Bogota',
    dateStyle: 'medium',
    timeStyle: 'short'
  }).format(now);
}

function nombreDe(member) {
  if (!member) return 'Integrante no disponible';
  if (member.nombre) return member.nombre;
  return [member.nombres, member.apellidos].filter(Boolean).join(' ').trim();
}

function aplicarEncabezado(sheet, columnas) {
  const row = sheet.getRow(1);
  row.height = 24;
  for (let columna = 1; columna <= columnas; columna += 1) {
    const cell = row.getCell(columna);
    cell.font = {
      bold: true,
      size: 11,
      color: { argb: COLOR.paper },
      name: 'Calibri'
    };
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: COLOR.header }
    };
    cell.alignment = { vertical: 'middle', horizontal: 'left', wrapText: false };
    cell.border = {
      bottom: { style: 'thin', color: { argb: COLOR.ink } }
    };
  }
  sheet.views = [{ state: 'frozen', ySplit: 1 }];
}

function marcarFilaExistente(row, columnas, { idConTexto = false } = {}) {
  for (let columna = 1; columna <= columnas; columna += 1) {
    const cell = row.getCell(columna);
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: COLOR.existing }
    };
    cell.font = {
      size: 11,
      color: { argb: COLOR.ink2 },
      bold: idConTexto && columna === 1
    };
  }
}

function agregarNota(cell, texto) {
  cell.note = {
    texts: [{ text: texto }],
    margins: { insetmode: 'custom', inset: 0.35 }
  };
}

function agregarValidacion(sheet, rango, validacion) {
  if (!rango) return;
  sheet.dataValidations.add(rango, {
    allowBlank: true,
    showErrorMessage: true,
    errorStyle: 'stop',
    ...validacion
  });
}

function escribirInstrucciones(workbook, semillero, now) {
  const sheet = workbook.addWorksheet('Instrucciones', {
    properties: { tabColor: { argb: COLOR.header } },
    views: [{ showGridLines: false }]
  });
  sheet.getColumn(1).width = 112;
  sheet.getColumn(2).width = 4;

  const titulo = sheet.getCell('A1');
  titulo.value = 'Plantilla de importación · SemiFund';
  titulo.font = { size: 17, bold: true, color: { argb: COLOR.paper } };
  titulo.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLOR.header }
  };
  titulo.alignment = { vertical: 'middle', indent: 1 };
  sheet.mergeCells('A1:B1');
  sheet.getRow(1).height = 34;

  const subtitulo = sheet.getCell('A2');
  subtitulo.value = `${semillero.nombre} (${semillero.codigo}) · generada el ${fechaHoraBogota(now)}`;
  subtitulo.font = { size: 11, color: { argb: COLOR.ink2 } };
  subtitulo.alignment = { vertical: 'middle', indent: 1 };
  sheet.mergeCells('A2:B2');
  sheet.getRow(2).height = 24;

  const lineas = [
    { texto: '', alto: 8 },
    { texto: 'Cómo usar la plantilla', seccion: true },
    {
      texto:
        '1. Descarga una plantilla nueva cada vez que vayas a importar. Así incluye los datos actuales y evita duplicados.'
    },
    {
      texto:
        '2. Las filas que ya tienen un ID son registros existentes: se muestran en gris y se ignoran al importar. No las edites.'
    },
    {
      texto:
        '3. Para agregar datos, escribe en las filas siguientes y deja la columna ID vacía. Puedes agregar integrantes, aportes, abonos y gastos en el mismo archivo.'
    },
    {
      texto:
        '4. Guarda el archivo en formato .xlsx y cárgalo desde Aportes → menú de Excel → Importar Excel. La app muestra una vista previa antes de guardar.'
    },
    {
      texto:
        '5. Si hay errores, la importación no guarda nada. Corrige las filas que indica la vista previa y vuelve a cargar el archivo.'
    },
    { texto: '', alto: 8 },
    { texto: 'Convenciones', seccion: true },
    { texto: '· Mes: AAAA-MM, por ejemplo 2026-11.' },
    { texto: '· Fecha: AAAA-MM-DD, por ejemplo 2026-11-09. No se permiten fechas futuras.' },
    { texto: '· Montos: solo números mayores a 0, sin puntos de miles ni símbolos. Ejemplo: 30000.' },
    { texto: '· Nombres y apellidos: solo letras, espacios, apóstrofe, punto y guion. Sin números.' },
    { texto: '· Semestre: entero entre 1 y 10. Los profesores no llevan semestre.' },
    { texto: '· Activo: Sí o No.' },
    { texto: '', alto: 8 },
    { texto: 'Hojas del libro', seccion: true },
    {
      texto:
        'Integrantes · Agrega personas nuevas. Si el integrante ya existe, se omite para no duplicarlo.'
    },
    {
      texto:
        'Aportes · Agrega cuotas. Elige integrante_id de la hoja Listas o escribe el nombre completo en Integrante. No puede haber dos cuotas del mismo integrante en el mismo mes.'
    },
    {
      texto:
        'Abonos · Registra pagos parciales o totales. Usa aporte_id de la hoja Listas o escribe Integrante + Mes. Estado aprobado suma al dinero cobrado; reportado queda pendiente de revisión.'
    },
    {
      texto:
        'Gastos · Agrega salidas de dinero. La fecha no puede ser futura y el gasto no puede superar el saldo disponible del semillero.'
    },
    {
      texto:
        'Listas · Contiene los catálogos y los IDs que usan las listas desplegables. No la edites.'
    },
    {
      texto:
        'Resumen · Muestra el balance actual y las cifras del semillero al momento de generar la plantilla.'
    },
    { texto: '', alto: 8 },
    { texto: 'Duplicados', seccion: true },
    {
      texto:
        'Un integrante se reconoce por su nombre completo sin tildes ni mayúsculas. Un aporte se reconoce por integrante + mes. Un gasto se reconoce por fecha + descripción + monto. Si vuelves a cargar el mismo archivo, esas filas se omiten automáticamente.'
    },
    {
      texto:
        'Si dos integrantes tienen exactamente el mismo nombre completo, la plantilla no puede distinguirlos por nombre: usa el ID en la hoja Aportes y revisa manualmente el caso.'
    }
  ];

  let fila = 3;
  for (const linea of lineas) {
    const row = sheet.getRow(fila);
    const cell = row.getCell(1);
    cell.value = linea.texto;
    cell.alignment = { wrapText: true, vertical: 'top' };
    if (linea.seccion) {
      cell.font = { bold: true, size: 11, color: { argb: COLOR.ink } };
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: COLOR.existing }
      };
      row.height = 22;
    } else {
      cell.font = { size: 10.5, color: { argb: COLOR.ink2 } };
      const largo = Math.max(1, Math.ceil((linea.texto || '').length / 108));
      row.height = Math.max(linea.alto || 16, largo * 15);
    }
    fila += 1;
  }
}

function escribirIntegrantes(workbook, members, maxFila) {
  const sheet = workbook.addWorksheet('Integrantes');
  sheet.columns = [
    { header: 'id', key: 'id', width: 27 },
    { header: 'nombres', key: 'nombres', width: 24 },
    { header: 'apellidos', key: 'apellidos', width: 24 },
    { header: 'programa', key: 'programa', width: 32 },
    { header: 'semestre', key: 'semestre', width: 10 },
    { header: 'tipo_usuario', key: 'tipoUsuario', width: 14 },
    { header: 'activo', key: 'activo', width: 9 },
    { header: 'nombre_completo', key: 'nombreCompleto', width: 34 }
  ];

  for (const member of members) {
    const row = sheet.addRow({
      id: member.id,
      nombres: member.nombres || '',
      apellidos: member.apellidos || '',
      programa: member.programa || '',
      semestre: member.semestre ?? '',
      tipoUsuario: member.tipoUsuario || '',
      activo: member.activo ? 'Sí' : 'No',
      nombreCompleto: nombreDe(member)
    });
    marcarFilaExistente(row, 8, { idConTexto: true });
  }

  aplicarEncabezado(sheet, 8);
  sheet.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: 8 } };
  agregarNota(
    sheet.getCell('A1'),
    'Déjalo vacío para agregar un integrante nuevo. Si tiene ID, la fila ya existe y no se importa.'
  );
  agregarNota(sheet.getCell('E1'), 'Entero entre 1 y 10. Un profesor no lleva semestre.');
  agregarNota(sheet.getCell('F1'), 'estudiante o profesor.');
  agregarNota(sheet.getCell('G1'), 'Sí o No.');

  agregarValidacion(sheet, 'E2:E' + maxFila, {
    type: 'whole',
    operator: 'between',
    formulae: [1, 10],
    errorTitle: 'Semestre inválido',
    error: 'El semestre debe ser un entero entre 1 y 10.'
  });
  agregarValidacion(sheet, 'F2:F' + maxFila, {
    type: 'list',
    formulae: ['"estudiante,profesor"'],
    errorTitle: 'Tipo de usuario inválido',
    error: 'Elige estudiante o profesor.'
  });
  agregarValidacion(sheet, 'G2:G' + maxFila, {
    type: 'list',
    formulae: ['"' + OPCIONES_ACTIVO.join(',') + '"'],
    errorTitle: 'Valor inválido',
    error: 'Elige Sí o No.'
  });

  for (let fila = 2; fila <= maxFila; fila += 1) {
    sheet.getCell(`E${fila}`).numFmt = '0';
  }
  return sheet;
}

function escribirAportes(workbook, contributions, memberById, maxFila, lastMemberRow) {
  const sheet = workbook.addWorksheet('Aportes');
  sheet.columns = [
    { header: 'id', key: 'id', width: 27 },
    { header: 'integrante_id', key: 'integranteId', width: 27 },
    { header: 'integrante', key: 'integrante', width: 32 },
    { header: 'mes', key: 'mes', width: 10 },
    { header: 'concepto', key: 'concepto', width: 30 },
    { header: 'monto_cuota', key: 'monto', width: 14 },
    { header: 'pago_inicial', key: 'pagoInicial', width: 14 },
    { header: 'fecha_pago', key: 'fechaPago', width: 13 },
    { header: 'referencia', key: 'referencia', width: 24 },
    { header: 'estado_actual', key: 'estado', width: 14 },
    { header: 'cobrado_actual', key: 'cobrado', width: 15 },
    { header: 'saldo_actual', key: 'saldo', width: 15 }
  ];

  for (const item of contributions) {
    const member = memberById.get(item.integranteId.toString());
    const row = sheet.addRow({
      id: item.id,
      integranteId: item.integranteId.toString(),
      integrante: nombreDe(member),
      mes: item.mes,
      concepto: item.concepto,
      monto: item.monto,
      pagoInicial: '',
      fechaPago: '',
      referencia: item.referencia || '',
      estado: item.estado,
      cobrado: montoPagadoDe(item),
      saldo: saldoPendiente(item)
    });
    marcarFilaExistente(row, 12, { idConTexto: true });
  }

  aplicarEncabezado(sheet, 12);
  sheet.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: 12 } };
  agregarNota(
    sheet.getCell('A1'),
    'Déjalo vacío para agregar un aporte nuevo. Si tiene ID, la fila ya existe y no se importa.'
  );
  agregarNota(
    sheet.getCell('B1'),
    'Elige un ID de Listas. También puedes dejar esta columna vacía y escribir el nombre completo en Integrante.'
  );
  agregarNota(sheet.getCell('C1'), 'Nombre completo. Solo se usa si no eliges integrante_id.');
  agregarNota(sheet.getCell('D1'), 'Formato AAAA-MM. Ejemplo: 2026-11.');
  agregarNota(sheet.getCell('F1'), 'Monto de la cuota. Número mayor a 0.');
  agregarNota(
    sheet.getCell('G1'),
    'Opcional. Dinero ya recibido de esta cuota. Se guarda como abono aprobado.'
  );
  agregarNota(sheet.getCell('H1'), 'AAAA-MM-DD. No puede ser futura. Si se omite, se usa hoy.');
  agregarNota(sheet.getCell('J1'), 'Solo lectura para filas existentes. Se calcula al importar.');

  agregarValidacion(sheet, 'D2:D' + maxFila, {
    type: 'custom',
    formulae: [
      'AND(LEN($D2)=7,ISNUMBER(VALUE(LEFT($D2,4))),MID($D2,5,1)="-",ISNUMBER(VALUE(RIGHT($D2,2))),VALUE(RIGHT($D2,2))>=1,VALUE(RIGHT($D2,2))<=12)'
    ],
    errorTitle: 'Mes inválido',
    error: 'Escribe el mes en formato AAAA-MM, por ejemplo 2026-11.'
  });
  agregarValidacion(sheet, 'F2:F' + maxFila, {
    type: 'decimal',
    operator: 'greaterThan',
    formulae: [0],
    errorTitle: 'Monto inválido',
    error: 'El monto de la cuota debe ser mayor a 0.'
  });
  agregarValidacion(sheet, 'G2:G' + maxFila, {
    type: 'decimal',
    operator: 'between',
    formulae: [0, 999999999999],
    errorTitle: 'Pago inicial inválido',
    error: 'El pago inicial debe ser 0 o un valor positivo.'
  });
  agregarValidacion(sheet, 'H2:H' + maxFila, {
    type: 'date',
    operator: 'lessThanOrEqual',
    formulae: ['TODAY()'],
    errorTitle: 'Fecha inválida',
    error: 'La fecha de pago no puede ser futura.'
  });
  if (lastMemberRow >= 2) {
    agregarValidacion(sheet, 'B2:B' + maxFila, {
      type: 'list',
      formulae: [`Listas!$A$2:$A$${lastMemberRow}`],
      errorTitle: 'Integrante inválido',
      error: 'Elige un integrante de la hoja Listas o escribe el nombre en Integrante.'
    });
  }

  for (let fila = 2; fila <= maxFila; fila += 1) {
    sheet.getCell(`F${fila}`).numFmt = '#,##0.00';
    sheet.getCell(`G${fila}`).numFmt = '#,##0.00';
    sheet.getCell(`K${fila}`).numFmt = '#,##0.00';
    sheet.getCell(`L${fila}`).numFmt = '#,##0.00';
    if (fila > contributions.length + 1) {
      sheet.getCell(`C${fila}`).value = {
        formula: `IF($B${fila}="","",IFERROR(VLOOKUP($B${fila},Listas!$A$2:$B$${Math.max(lastMemberRow, 2)},2,FALSE),""))`
      };
    }
  }
  return sheet;
}

function escribirAbonos(workbook, contributions, memberById, maxFila, lastContributionRow) {
  const sheet = workbook.addWorksheet('Abonos');
  sheet.columns = [
    { header: 'id', key: 'id', width: 27 },
    { header: 'aporte_id', key: 'aporteId', width: 27 },
    { header: 'integrante', key: 'integrante', width: 32 },
    { header: 'mes', key: 'mes', width: 10 },
    { header: 'monto', key: 'monto', width: 14 },
    { header: 'fecha', key: 'fecha', width: 13 },
    { header: 'referencia', key: 'referencia', width: 24 },
    { header: 'estado', key: 'estado', width: 13 },
    { header: 'motivo', key: 'motivo', width: 26 }
  ];

  let abonosEscritos = 0;
  for (const item of contributions) {
    const member = memberById.get(item.integranteId.toString());
    for (const abono of item.abonos || []) {
      const row = sheet.addRow({
        id: abono._id ? abono._id.toString() : '',
        aporteId: item.id,
        integrante: nombreDe(member),
        mes: item.mes,
        monto: abono.monto,
        fecha: fechaTexto(abono.fecha),
        referencia: abono.referencia || '',
        estado: abono.estado,
        motivo: abono.motivo || ''
      });
      marcarFilaExistente(row, 9, { idConTexto: true });
      abonosEscritos += 1;
    }
  }

  aplicarEncabezado(sheet, 9);
  sheet.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: 9 } };
  agregarNota(
    sheet.getCell('A1'),
    'Déjalo vacío para agregar un abono nuevo. Si tiene ID, el abono ya existe y no se importa.'
  );
  agregarNota(
    sheet.getCell('B1'),
    'Elige un aporte de Listas. También puedes dejar esta columna vacía y usar Integrante + Mes.'
  );
  agregarNota(sheet.getCell('C1'), 'Solo se usa si no eliges aporte_id.');
  agregarNota(sheet.getCell('D1'), 'Solo se usa si no eliges aporte_id. Formato AAAA-MM.');
  agregarNota(sheet.getCell('F1'), 'AAAA-MM-DD. No puede ser futura. Si se omite, se usa hoy.');
  agregarNota(
    sheet.getCell('H1'),
    'aprobado = dinero recibido; reportado = pendiente de revisión del tesorero.'
  );
  agregarNota(sheet.getCell('I1'), 'Opcional. Máximo 200 caracteres.');

  agregarValidacion(sheet, 'E2:E' + maxFila, {
    type: 'decimal',
    operator: 'greaterThan',
    formulae: [0],
    errorTitle: 'Monto inválido',
    error: 'El monto del abono debe ser mayor a 0.'
  });
  agregarValidacion(sheet, 'F2:F' + maxFila, {
    type: 'date',
    operator: 'lessThanOrEqual',
    formulae: ['TODAY()'],
    errorTitle: 'Fecha inválida',
    error: 'La fecha del abono no puede ser futura.'
  });
  agregarValidacion(sheet, 'H2:H' + maxFila, {
    type: 'list',
    formulae: ['"' + ESTADOS_ABONO.join(',') + '"'],
    errorTitle: 'Estado inválido',
    error: 'Elige aprobado o reportado.'
  });
  if (lastContributionRow >= 2) {
    agregarValidacion(sheet, 'B2:B' + maxFila, {
      type: 'list',
      formulae: [`Listas!$C$2:$C$${lastContributionRow}`],
      errorTitle: 'Aporte inválido',
      error: 'Elige un aporte de la hoja Listas o usa Integrante + Mes.'
    });
  }

  for (let fila = 2; fila <= maxFila; fila += 1) {
    sheet.getCell(`E${fila}`).numFmt = '#,##0.00';
    if (fila > abonosEscritos + 1) {
      sheet.getCell(`C${fila}`).value = {
        formula: `IF($B${fila}="","",IFERROR(VLOOKUP($B${fila},Listas!$C$2:$E$${Math.max(lastContributionRow, 2)},2,FALSE),""))`
      };
      sheet.getCell(`D${fila}`).value = {
        formula: `IF($B${fila}="","",IFERROR(VLOOKUP($B${fila},Listas!$C$2:$E$${Math.max(lastContributionRow, 2)},3,FALSE),""))`
      };
    }
  }
  return sheet;
}

function escribirGastos(workbook, expenses, maxFila) {
  const sheet = workbook.addWorksheet('Gastos');
  sheet.columns = [
    { header: 'id', key: 'id', width: 27 },
    { header: 'fecha', key: 'fecha', width: 13 },
    { header: 'descripcion', key: 'descripcion', width: 40 },
    { header: 'categoria', key: 'categoria', width: 20 },
    { header: 'monto', key: 'monto', width: 14 }
  ];

  for (const item of expenses) {
    const row = sheet.addRow({
      id: item.id,
      fecha: fechaTexto(item.fecha),
      descripcion: item.descripcion,
      categoria: item.categoria,
      monto: item.monto
    });
    marcarFilaExistente(row, 5, { idConTexto: true });
  }

  aplicarEncabezado(sheet, 5);
  sheet.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: 5 } };
  agregarNota(
    sheet.getCell('A1'),
    'Déjalo vacío para agregar un gasto nuevo. Si tiene ID, el gasto ya existe y no se importa.'
  );
  agregarNota(sheet.getCell('B1'), 'AAAA-MM-DD. No puede ser futura. Si se omite, se usa hoy.');
  agregarNota(sheet.getCell('C1'), 'Descripción breve del gasto.');
  agregarNota(sheet.getCell('D1'), 'Elige una categoría o escribe una nueva.');
  agregarNota(sheet.getCell('E1'), 'Número mayor a 0. No puede superar el saldo disponible.');

  agregarValidacion(sheet, 'B2:B' + maxFila, {
    type: 'date',
    operator: 'lessThanOrEqual',
    formulae: ['TODAY()'],
    errorTitle: 'Fecha inválida',
    error: 'La fecha del gasto no puede ser futura.'
  });
  agregarValidacion(sheet, 'D2:D' + maxFila, {
    type: 'list',
    formulae: [`Listas!$G$2:$G$${CATEGORIAS.length + 1}`],
    errorTitle: 'Categoría inválida',
    error: 'Elige una categoría de la lista o escribe una nueva.'
  });
  agregarValidacion(sheet, 'E2:E' + maxFila, {
    type: 'decimal',
    operator: 'greaterThan',
    formulae: [0],
    errorTitle: 'Monto inválido',
    error: 'El monto del gasto debe ser mayor a 0.'
  });

  for (let fila = 2; fila <= maxFila; fila += 1) {
    sheet.getCell(`E${fila}`).numFmt = '#,##0.00';
  }
  return sheet;
}

function escribirListas(workbook, members, contributions) {
  const sheet = workbook.addWorksheet('Listas');
  sheet.columns = [
    { header: 'integrante_id', key: 'integranteId', width: 27 },
    { header: 'integrante_nombre', key: 'integranteNombre', width: 34 },
    { header: 'aporte_id', key: 'aporteId', width: 27 },
    { header: 'aporte_integrante', key: 'aporteIntegrante', width: 34 },
    { header: 'aporte_mes', key: 'aporteMes', width: 12 },
    { header: 'aporte_concepto', key: 'aporteConcepto', width: 30 },
    { header: 'categoria', key: 'categoria', width: 20 },
    { header: 'estado_abono', key: 'estadoAbono', width: 14 },
    { header: 'tipo_usuario', key: 'tipoUsuario', width: 14 },
    { header: 'activo', key: 'activo', width: 9 }
  ];

  const memberById = new Map(members.map((member) => [member.id, member]));
  const filas = Math.max(members.length, contributions.length, CATEGORIAS.length, 2);
  for (let indice = 0; indice < filas; indice += 1) {
    const member = members[indice];
    const contribution = contributions[indice];
    const memberDeAporte = contribution
      ? memberById.get(contribution.integranteId.toString())
      : null;
    sheet.addRow({
      integranteId: member ? member.id : '',
      integranteNombre: member ? nombreDe(member) : '',
      aporteId: contribution ? contribution.id : '',
      aporteIntegrante: contribution ? nombreDe(memberDeAporte) : '',
      aporteMes: contribution ? contribution.mes : '',
      aporteConcepto: contribution ? contribution.concepto : '',
      categoria: CATEGORIAS[indice] || '',
      estadoAbono: ESTADOS_ABONO[indice] || '',
      tipoUsuario: TIPOS_USUARIO[indice] || '',
      activo: OPCIONES_ACTIVO[indice] || ''
    });
  }

  aplicarEncabezado(sheet, 10);
  sheet.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: 10 } };
  agregarNota(
    sheet.getCell('A1'),
    'Catálogos de apoyo. La plantilla los usa para las listas desplegables; no los edites.'
  );
  for (let fila = 2; fila <= sheet.rowCount; fila += 1) {
    marcarFilaExistente(sheet.getRow(fila), 10);
  }
  return {
    sheet,
    lastMemberRow: members.length ? members.length + 1 : 1,
    lastContributionRow: contributions.length ? contributions.length + 1 : 1
  };
}

function escribirResumen(workbook, { semillero, members, contributions, expenses, balance, now }) {
  const sheet = workbook.addWorksheet('Resumen', {
    properties: { tabColor: { argb: COLOR.header } },
    views: [{ showGridLines: false }]
  });
  sheet.columns = [
    { header: 'Concepto', key: 'concepto', width: 38 },
    { header: 'Valor', key: 'valor', width: 28 }
  ];

  aplicarEncabezado(sheet, 2);
  const saldoPendienteTotal = contributions.reduce(
    (total, item) => total + saldoPendiente(item),
    0
  );
  const activos = members.filter((member) => member.activo).length;
  const filas = [
    ['Semillero', `${semillero.nombre} (${semillero.codigo})`],
    ['Generado', fechaHoraBogota(now)],
    ['Versión de plantilla', PLANTILLA_VERSION],
    ['Integrantes activos', activos],
    ['Integrantes totales', members.length],
    ['Aportes registrados', contributions.length],
    ['Total cobrado', round(balance.totalAportado)],
    ['Saldo pendiente por cobrar', round(saldoPendienteTotal)],
    ['Total gastado', round(balance.totalGastado)],
    ['Saldo disponible', round(balance.saldoDisponible)],
    ['Gastos registrados', expenses.length]
  ];

  for (let indice = 0; indice < filas.length; indice += 1) {
    const [concepto, valor] = filas[indice];
    const row = sheet.addRow({ concepto, valor });
    const celdaConcepto = row.getCell(1);
    const celdaValor = row.getCell(2);
    celdaConcepto.font = { size: 11, color: { argb: COLOR.ink2 } };
    celdaValor.font = { size: 11, color: { argb: COLOR.ink }, bold: true };
    if (typeof valor === 'number') {
      celdaValor.numFmt = '#,##0.00';
    }
  }

  sheet.addRow([]);
  const nota = sheet.addRow([
    'Este resumen es informativo. Los valores se recalculan al importar.'
  ]);
  nota.getCell(1).font = { size: 10, color: { argb: COLOR.ink3 } };
  sheet.mergeCells(`A${nota.number}:B${nota.number}`);
}

/**
 * Construye el libro de plantilla con los datos actuales del semillero.
 * Las filas existentes llevan ID y se muestran en gris; solo las filas
 * nuevas (sin ID) se tienen en cuenta al importar.
 */
function buildTemplate({ semillero, members, contributions, expenses, balance, now = new Date() }) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'SemiFund';
  workbook.lastModifiedBy = 'SemiFund';
  workbook.created = now;
  workbook.modified = now;
  workbook.calcProperties.fullCalcOnLoad = true;
  workbook.properties.date1904 = false;

  const cantidadMaxima = Math.min(
    1000,
    Math.max(200, members.length + 100, contributions.length + 100, expenses.length + 100)
  );
  const maxFila = cantidadMaxima;

  escribirInstrucciones(workbook, semillero, now);

  const memberById = new Map(members.map((member) => [member.id, member]));
  const lastMemberRow = members.length ? members.length + 1 : 1;
  const lastContributionRow = contributions.length ? contributions.length + 1 : 1;

  escribirIntegrantes(workbook, members, maxFila);
  escribirAportes(workbook, contributions, memberById, maxFila, lastMemberRow);
  escribirAbonos(workbook, contributions, memberById, maxFila, lastContributionRow);
  escribirGastos(workbook, expenses, maxFila);
  escribirListas(workbook, members, contributions);
  escribirResumen(workbook, { semillero, members, contributions, expenses, balance, now });

  return { workbook, maxFila };
}

module.exports = {
  buildTemplate,
  PLANTILLA_VERSION,
  CATEGORIAS,
  ESTADOS_ABONO,
  TIPOS_USUARIO,
  OPCIONES_ACTIVO
};
