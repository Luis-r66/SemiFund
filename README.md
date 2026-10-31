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

Para recuperación de contraseña:

```
MAIL_MODE=console          # local: el código aparece en la consola
MAIL_FROM_NAME=SemiFund
MAIL_FROM=                 # remitente verificado en Brevo
BREVO_API_KEY=             # solo en Render o .env local, nunca en Git
```

En Render configura `MAIL_MODE=brevo`, `MAIL_FROM` y `BREVO_API_KEY`.

## Levantar el backend

```bash
cd backend
npm run dev    # desarrollo (nodemon)
npm start      # producción
```

Verificar: `GET http://localhost:3000/health` → `{ "ok": true }`.

Para sincronizar los datos académicos de las cuentas con los integrantes existentes:

```bash
cd backend
npm run sync:members -- --dry-run   # revisar cambios
npm run sync:members                # aplicar
```

## Autenticación, perfil y recuperación

| Método | Ruta | OK | Errores |
|---|---|---|---|
| POST | `/auth/register` `{nombres, apellidos, email, password}` | 201 `{token, user}` | 400, 409, 429 |
| POST | `/auth/login` `{email, password}` | 200 `{token, user}` | 401, 429 |
| GET | `/auth/me` | 200 perfil + semilleros | 401 |
| PATCH | `/auth/me` `{nombres?, apellidos?, tipoUsuario?, programa?, semestre?}` | 200 perfil | 400 |
| PATCH | `/auth/password` `{currentPassword, newPassword}` | 200 `{token}` | 400, 401, 429 |
| POST | `/auth/forgot-password` `{email}` | 200 mensaje genérico | 400, 429, 503 |
| POST | `/auth/reset-password` `{email, code, password}` | 200 | 400, 429 |

- `tipoUsuario`: `estudiante | profesor`.
- Estudiante: `programa` y `semestre` (1–10).
- Profesor: área/departamento en `programa`, sin semestre.
- `nombres`/`apellidos` son los campos nuevos; `nombre` sigue aceptándose por compatibilidad.
- El código de recuperación tiene 6 dígitos, vence en 15 minutos, es de un solo uso y máximo 5 intentos.
- `PATCH /auth/password` y `reset-password` invalidan sesiones anteriores con `tokenVersion`.

## Endpoints de tesorería (base `http://localhost:3000/api`)

| Método | Ruta | OK | Errores |
|---|---|---|---|
| GET | `/members?activo=true` | 200 lista | 400 filtro inválido |
| GET | `/members/:id` | 200 | 404 |
| POST | `/members` `{nombres, apellidos, programa, semestre}` | 201 | 400 |
| PUT | `/members/:id` (manual: nombre, programa, semestre, activo; vinculado: solo activo) | 200 | 400, 404, 409 datos académicos de cuenta |
| DELETE | `/members/:id` (soft, `activo=false`) | 204 | 404 |
| GET | `/contributions?status=pending&memberId=` | 200 | 400 |
| POST | `/contributions` `{integranteId, monto, mes, concepto}` | 201 | 400, 409 aporte duplicado |
| PATCH | `/contributions/:id/report` `{referencia?}` | 200 | 403 no es propio, 404, 409 ya pagado/reportado |
| PATCH | `/contributions/:id/pay` | 200 | 404, 409 ya pagado |
| PATCH | `/contributions/:id/reject` `{motivo?}` | 200 | 404, 409 no está reportado |
| GET | `/expenses?category=&month=YYYY-MM` | 200 | 400 |
| POST | `/expenses` `{descripcion, categoria, monto, fecha?}` (sin fecha futura) | 201 | 400, 409 saldo insuficiente |
| GET | `/balance` → `{totalAportado, totalGastado, saldoDisponible}` | 200 | — |
| GET | `/reports/movimientos.csv` | 200 CSV | 403 no tesorero |

`status` en query: `pending|paid|overdue|reported` → `pendiente|pagado|vencido|reportado` en DB. `GET /contributions` agrega `esPropio` a cada aporte.

- El integrante solo puede reportar aportes propios. El tesorero aprueba con `/pay` o rechaza con `/reject`.
- El CSV `movimientos.csv` incluye aportes y gastos. El correo del integrante sale de su cuenta; los integrantes manuales sin cuenta quedan con correo vacío.
- El perfil académico de la cuenta se sincroniza con los integrantes vinculados. El tesorero no puede editar carrera/semestre de un integrante con cuenta.

## Reglas de negocio (validadas en backend)

1. Gasto con `monto > saldoDisponible` → `409 { "error": "Saldo insuficiente" }` (`controllers/expenseController.js` + `utils/balance.js` con `aggregate` en vivo).
2. Aporte: `pendiente→reportado→pagado`, `vencido→reportado→pagado`, `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`. Un rechazo devuelve el aporte a `pendiente`. Desde `pagado` nada → `409`.
3. Un integrante no puede reportar el aporte de otro (`403`); el tesorero no puede crear dos aportes del mismo integrante y mes (`409`).
4. Al crear un semillero o aprobar una solicitud se copian los datos académicos de la cuenta; al actualizar el perfil se sincronizan los integrantes vinculados.

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
