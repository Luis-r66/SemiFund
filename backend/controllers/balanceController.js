const asyncHandler = require('../middleware/asyncHandler');
const { getBalance } = require('../utils/balance');

// GET /api/balance -> { totalAportado, totalGastado, saldoDisponible }
const get = asyncHandler(async (req, res) => {
  const balance = await getBalance();
  res.status(200).json(balance);
});

module.exports = { get };
