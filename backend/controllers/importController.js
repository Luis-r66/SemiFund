const asyncHandler = require('../middleware/asyncHandler');
const { invalidateBalance } = require('../utils/balance');
const {
  analizarImportacion,
  aplicarImportacion,
  vistaPreviaPublica
} = require('../services/excelImport');

function validarArchivo(req) {
  if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
    const error = new Error(
      'Envía el archivo .xlsx de la plantilla en el cuerpo de la solicitud.'
    );
    error.status = 400;
    throw error;
  }
}

// POST /api/import/preview
// Recibe el .xlsx como cuerpo binario y devuelve el análisis fila por fila.
const preview = asyncHandler(async (req, res) => {
  validarArchivo(req);
  const analisis = await analizarImportacion({
    buffer: req.body,
    semilleroId: req.semilleroId
  });
  res.status(200).json(vistaPreviaPublica(analisis));
});

// POST /api/import/confirm
// Vuelve a validar contra la base actual y guarda solo si no hay errores.
const confirm = asyncHandler(async (req, res) => {
  validarArchivo(req);
  const analisis = await analizarImportacion({
    buffer: req.body,
    semilleroId: req.semilleroId
  });

  if (analisis.totales.errores > 0) {
    return res.status(422).json({
      error:
        'La importación tiene errores. Corrige las filas indicadas y vuelve a intentarlo.',
      ...vistaPreviaPublica(analisis)
    });
  }
  if (analisis.totales.nuevos === 0) {
    return res.status(409).json({
      error: 'No hay filas nuevas para importar. La plantilla solo tiene datos existentes.',
      ...vistaPreviaPublica(analisis)
    });
  }

  const resultado = await aplicarImportacion(analisis.plan, {
    semilleroId: req.semilleroId,
    usuarioId: req.userId
  });
  invalidateBalance(req.semilleroId);

  res.status(201).json({
    ...resultado,
    resumen: analisis.resumen,
    totales: analisis.totales,
    mensaje: `Importación completada: ${resultado.creados.integrantes} integrantes, ${resultado.creados.aportes} aportes, ${resultado.creados.abonos} abonos y ${resultado.creados.gastos} gastos.`
  });
});

module.exports = { preview, confirm };
