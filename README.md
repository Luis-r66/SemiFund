# Tesorería Semillero de Software — Backend API REST

Proyecto individual: API propia para el control de integrantes, aportes y gastos del semillero + colección de pruebas Postman.

`backend/` Node.js + Express + Mongoose · `postman/` colección exportada · DB MongoDB Atlas (`semillero`).

## Requisitos

- Node.js 18+ (`node --version`)
- Acceso a MongoDB Atlas (Cluster0, DB `semillero`) o Mongo local
- Postman o Insomnia para las pruebas
- (Solo Android) emulador o dispositivo en la misma red que el PC

## Instalación

```bash
cd backend
npm install
cp .env.example .env   # y completa MONGODB_URI si hace falta
```

`.env` usa:

```
PORT=3000
MONGODB_URI=mongodb://<usuario>:<password>@ac-ed2os0d-shard-00-00.../semillero?ssl=true&replicaSet=atlas-7lf8t9-shard-0&authSource=admin&retryWrites=true&w=majority
```

> Hay dos formatos en `.env.example`: `mongodb+srv` (recomendado) y URI directa con los 3 shards (fallback si Node falla con `querySrv ECONNREFUSED`). No subir `.env` al repo.

## Levantar el backend

```bash
cd backend
npm run dev    # desarrollo (nodemon)
npm start      # producción
```

Verificar: `GET http://localhost:3000/health` → `{ "ok": true }`.

## Endpoints (base `http://localhost:3000/api`)

| Método | Ruta | OK | Errores |
|---|---|---|---|
| GET | `/members?activo=true` | 200 lista | 400 filtro inválido |
| GET | `/members/:id` | 200 | 404 |
| POST | `/members` `{nombre, programa, semestre}` | 201 | 400 |
| PUT | `/members/:id` | 200 | 400, 404 |
| DELETE | `/members/:id` (soft, `activo=false`) | 204 | 404 |
| GET | `/contributions?status=pending&memberId=` | 200 | 400 |
| POST | `/contributions` `{integranteId, monto, mes}` | 201 | 400 (incluye integrante inexistente) |
| PATCH | `/contributions/:id/pay` | 200 | 404, 409 ya pagado |
| GET | `/expenses?category=&month=YYYY-MM` | 200 | 400 |
| POST | `/expenses` `{descripcion, categoria, monto, fecha?}` | 201 | 400, 409 saldo insuficiente |
| GET | `/balance` → `{totalAportado, totalGastado, saldoDisponible}` | 200 | — |

`status` en query: `pending|paid|overdue` → `pendiente|pagado|vencido` en DB.

## Reglas de negocio (validadas en backend)

1. Gasto con `monto > saldoDisponible` → `409 { "error": "Saldo insuficiente" }` (`controllers/expenseController.js` + `utils/balance.js` con `aggregate` en vivo).
2. Aporte: `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`. Desde `pagado` nada → `409` (`controllers/contributionController.js#pay`).

## Probar con Postman / Insomnia

1. Importa `postman/Semillero-API.postman_collection.json`.
2. Variable `baseUrl` = `http://localhost:3000/api` (ya viene así).
3. Ejecuta en orden: Members → Contributions → Expenses → Balance. Los `Crear` guardan `memberId`/`contributionId` solos.
4. Casos de error incluidos: 400 sin nombre, 404 id `000000000000000000000000`, 409 doble pago, 409 gasto gigante.

## URL base para la app Android (`API_CONTRACT.md`)

- Emulador → `http://10.0.2.2:3000/api/`
- Dispositivo físico (misma Wi-Fi) → `http://<IP-LAN-del-PC>:3000/api/` (ej. `http://192.168.1.10:3000/api/`)
- Permiso `INTERNET` en `AndroidManifest` + `usesCleartextTraffic="true"` si es `http`.
- Detalle de JSON por endpoint: ver `API_CONTRACT.md` (incluye interfaz Retrofit + data classes Kotlin).

## Estructura por capas

```
backend/
  server.js (conecta Mongo + listen)
  app.js (Express, /health, /api/*, 404, errorHandler)
  config/db.js
  models/ (Member, Contribution, Expense — schemas Mongoose)
  controllers/ (lógica negocio + reglas)
  routes/ (solo mapeo método→controlador)
  middleware/ (asyncHandler, validateObjectId, errorHandler)
  utils/balance.js (agregaciones en vivo)
postman/Semillero-API.postman_collection.json
API_CONTRACT.md (contrato para Android)
```

## Demostración en vivo (sustentación)

- Crear: `POST /members` → `POST /contributions` → `PATCH .../pay` → `GET /balance` (sube el saldo).
- 404: `GET /members/000000000000000000000000`.
- 409: `POST /expenses` con monto `999999999`, o `PATCH .../pay` dos veces.
- 400: `POST /members` sin `nombre`.
- Soft delete: `DELETE /members/:id` → `GET` muestra `activo:false`.
