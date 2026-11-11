const express = require('express');
const c = require('../controllers/importController');

const router = express.Router();

// La plantilla viaja como binario .xlsx. El límite evita archivos enormes;
// express.json() no consume este content-type, así que no hay conflicto.
const archivoExcel = express.raw({
  type: [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/octet-stream',
    'application/zip'
  ],
  limit: '8mb'
});

router.post('/preview', archivoExcel, c.preview);
router.post('/confirm', archivoExcel, c.confirm);

module.exports = router;
