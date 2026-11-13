const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

// Paginación opcional: si el cliente no envía page ni limit, el endpoint
// responde como siempre (arreglo completo) para no romper la app Android ya
// instalada. Con parámetros responde { items, total, page, limit, pages }.
function parsePagination(query, options = {}) {
  const defaultLimit = options.defaultLimit || DEFAULT_LIMIT;
  const pidePagina = query.page !== undefined && query.page !== '';
  const pideLimite = query.limit !== undefined && query.limit !== '';
  const paginado = pidePagina || pideLimite;
  if (!paginado) {
    return { paginated: false, page: 1, limit: defaultLimit, skip: 0 };
  }

  let page = 1;
  if (query.page !== undefined && query.page !== '') {
    page = Number.parseInt(query.page, 10);
    if (!Number.isInteger(page) || page < 1) {
      return { error: 'page debe ser un entero mayor o igual a 1' };
    }
  }

  let limit = defaultLimit;
  if (query.limit !== undefined && query.limit !== '') {
    limit = Number.parseInt(query.limit, 10);
    if (!Number.isInteger(limit) || limit < 1) {
      return { error: 'limit debe ser un entero mayor o igual a 1' };
    }
    limit = Math.min(limit, MAX_LIMIT);
  }

  return { paginated: true, page, limit, skip: (page - 1) * limit };
}

function paginatedBody(items, total, page, limit) {
  const pages = Math.max(1, Math.ceil(total / limit));
  return { items, total, page, limit, pages };
}

module.exports = { parsePagination, paginatedBody, DEFAULT_LIMIT, MAX_LIMIT };
