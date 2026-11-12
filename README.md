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

### Google y Cloudinary

```
GOOGLE_CLIENT_ID=571520017186-....apps.googleusercontent.com
CLOUDINARY_CLOUD_NAME=gcfx7sd0
CLOUDINARY_API_KEY=983957817848339
CLOUDINARY_API_SECRET=...   # solo Render y backend/.env local
```

- `GOOGLE_CLIENT_ID` es el **Web Client ID** de Google Cloud Console (público).
- El cliente OAuth **Android** debe tener el package `com.luisriascos.semi_fund` y el SHA-1 del keystore con el que se firma el APK.
- `CLOUDINARY_API_SECRET` es como una contraseña: nunca se sube al repositorio ni viaja en el APK. Las subidas se hacen desde el backend.
- Si Cloudinary no está configurado, el endpoint de comprobantes responde `503` con un mensaje claro.

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
| POST | `/auth/google` `{idToken}` | 200 `{token, user, requierePerfil}` | 400, 401, 403, 409, 429, 503 |
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
| GET | `/members/:id/statement` (tesorero o el mismo integrante) | 200 resumen + cuotas | 403, 404 |
| POST | `/members` `{nombres, apellidos, programa, semestre}` | 201 | 400 |
| PUT | `/members/:id` (manual: nombre, programa, semestre, activo; vinculado: solo activo) | 200 | 400, 404, 409 datos académicos de cuenta |
| DELETE | `/members/:id` (soft, `activo=false`) | 204 | 404 |
| GET | `/contributions?status=pending&memberId=` | 200 | 400 |
| POST | `/contributions` `{integranteId, monto, mes, concepto}` | 201 | 400, 409 aporte duplicado |
| POST | `/contributions/bulk` `{mes, monto, concepto, integranteIds?}` | 201 `{creadas, omitidas}` | 400, 403 no tesorero |
| PATCH | `/contributions/:id/report` `{referencia?}` | 200 | 403 no es propio, 404, 409 ya pagado/reportado |
| PATCH | `/contributions/:id/pay` | 200 | 404, 409 ya pagado |
| PATCH | `/contributions/:id/reject` `{motivo?}` | 200 | 404, 409 no está reportado |
| POST | `/contributions/:id/payments` `{monto?, referencia?}` | 201 abono | 400, 403, 404, 409 |
| PATCH | `/contributions/:id/payments/:abonoId/approve` | 200 | 404, 409 abono no reportado |
| PATCH | `/contributions/:id/payments/:abonoId/reject` `{motivo?}` | 200 | 404, 409 abono no reportado |
| PATCH | `/contributions/:id/payments/:abonoId/void` | 200 | 404, 409 abono no aprobado |
| POST | `/contributions/:id/payments/:abonoId/comprobante` (multipart `comprobante`) | 200 aporte actualizado | 400, 403, 404, 409, 413, 415, 503 |
| GET | `/expenses?category=&month=YYYY-MM` | 200 | 400 |
| POST | `/expenses` `{descripcion, categoria, monto, fecha?}` (sin fecha futura) | 201 | 400, 409 saldo insuficiente |
| GET | `/balance` → `{totalAportado, totalGastado, saldoDisponible}` | 200 | — |
| GET | `/reports/movimientos.csv` | 200 CSV | 403 no tesorero |
| GET | `/reports/libro.xlsx` | 200 Excel (Integrantes, Aportes, Gastos, Balance) | 403 no tesorero |
| GET | `/reports/plantilla.xlsx` | 200 Excel para importar | 403 no tesorero |
| POST | `/import/preview` (cuerpo `.xlsx`) | 200 vista previa fila por fila | 400, 413 más de 8 MB |
| POST | `/import/confirm` (cuerpo `.xlsx`) | 201 resumen de creados | 409 sin filas nuevas, 422 errores, 413 |
| GET | `/audit?limit=100` | 200 historial | 403 no tesorero |

`status` en query: `pending|paid|overdue|reported` → `pendiente|pagado|vencido|reportado` en DB. `GET /contributions` agrega `esPropio` a cada aporte.

- El integrante solo puede reportar aportes propios. El tesorero aprueba con `/pay` o rechaza con `/reject`.
- Los abonos parciales se guardan en `abonos[]` y actualizan `montoPagado`; el saldo y el estado `parcial` se calculan en el modelo. El tesorero puede anular un abono aprobado.
- Las cuotas masivas crean una cuota por integrante activo y omiten a quien ya tenga una para ese mes.
- El CSV `movimientos.csv` y el libro `libro.xlsx` incluyen aportes y gastos. El correo del integrante sale de su cuenta; los integrantes manuales sin cuenta quedan con correo vacío.
- El perfil académico de la cuenta se sincroniza con los integrantes vinculados. El tesorero no puede editar carrera/semestre de un integrante con cuenta.
- La auditoría registra integrantes, aportes, abonos y gastos sin bloquear la operación principal.

## Plantilla Excel e importación

La app descarga `GET /reports/plantilla.xlsx` desde **Aportes → menú de Excel → Descargar plantilla Excel**, la llena y la sube con **Importar Excel**. La app muestra la vista previa antes de confirmar.

La plantilla solo usa los datos que hoy guarda el APK: nombres y apellidos, programa, semestre, tipo de usuario, aportes, abonos y gastos. No pide documento, correo ni teléfono.

Hojas del libro:

- `Instrucciones`: convenciones y advertencias.
- `Integrantes`: personas del semillero.
- `Aportes`: cuotas por integrante y mes.
- `Abonos`: pagos parciales o totales.
- `Gastos`: salidas de dinero.
- `Listas`: catálogos e IDs para las listas desplegables.
- `Resumen`: cifras al momento de generar la plantilla.

Reglas:

- Las filas con `id` son registros existentes: se muestran en gris y **se ignoran al importar**. Solo se crean las filas con `id` vacío.
- Los integrantes nuevos se agregan antes que sus aportes y abonos, en el mismo archivo.
- Mes en `AAAA-MM`; fechas en `AAAA-MM-DD`, reales y nunca futuras.
- Montos mayores a 0. Los profesores no llevan semestre.
- Duplicados: integrante por nombre normalizado (sin tildes ni mayúsculas), aporte por integrante + mes, gasto por fecha + descripción + monto, abono por aporte + monto + fecha + referencia. Las filas repetidas se omiten.
- Si hay un solo error, la importación no guarda nada y devuelve `422` con el detalle.
- El archivo no puede superar 8 MB (`413`). Si se supera, descarga una plantilla nueva y no agregues filas vacías de más.
- Tope de 5000 filas por hoja.

Pruebas de las reglas puras:

```bash
cd backend
npm test    # 34 pruebas
```

## Inicio de sesión con Google

- La app pide el `idToken` con el plugin `google_sign_in` y lo envía a `POST /api/auth/google`.
- El backend lo valida con `google-auth-library` usando `GOOGLE_CLIENT_ID` como audiencia.
- Se exige `email_verified = true`.
- Si el correo ya existe, la cuenta se vincula (Google ya verificó el correo). Si no existe, se crea sin contraseña y `requierePerfil: true` envía al onboarding.
- Botón **Continuar con Google** en login y registro.
- Si la pantalla de consentimiento está en modo *Testing*, agrega tu correo como usuario de prueba en Google Cloud Console.

Para publicar la app en Google Cloud Console se usan estas páginas del backend:

- Página principal: `https://semifund-api.onrender.com/`
- Política de privacidad: `https://semifund-api.onrender.com/privacidad`
- Dominio autorizado: `semifund-api.onrender.com`

Los archivos están en `backend/public/` y también hay una copia en `PRIVACIDAD.md`. Google exige ambas URLs para habilitar **Publicar app** cuando la app pasa de *Testing* a *In production*.

En web, el mismo cliente OAuth de tipo **Aplicación web** debe tener registrados estos orígenes de JavaScript (sin barra final):

- `https://luis-r66.github.io` (producción)
- `http://localhost:8080` (desarrollo local)

El `idToken` se obtiene con `clientId` y `serverClientId` iguales al Web Client ID, y el backend lo valida de la misma forma que en Android. En web hay que usar el botón oficial de Google (`google_sign_in_web`), porque el plugin no permite pedir el token con una llamada normal; el token llega por el evento de autenticación del propio botón.

## Versión web

Hay dos aplicaciones en el mismo GitHub Pages:

- `https://luis-r66.github.io/SemiFund/` — **app de iPhone**, congelada. Es la versión móvil de siempre, publicada desde la rama `iphone`, con el arreglo del botón de Google y un aviso para entrar con correo y contraseña cuando está instalada en la pantalla de inicio.
- `https://luis-r66.github.io/SemiFund/web/` — **web de escritorio**, publicada desde `main`. Login y registro en un recuadro centrado, inicio con rejilla de accesos y contenido limitado a 1100 px. Por debajo de 1024 px se mantiene el diseño móvil.

Detalles:

- Ambas son la misma aplicación Flutter compilada para navegador y consumen la API de Render: `https://semifund-api.onrender.com/api`.
- El workflow `.github/workflows/flutter-web.yml` compila las dos y las publica en un solo despliegue. La rama `iphone` solo se compila; no se le aplican cambios de `main`.
- La rama `iphone` no debe recibir el layout de escritorio: es la que usan los iPhone.
- La sesión se guarda en `localStorage`. Excel, CSV y PDF se descargan con el navegador, y los comprobantes se abren en una pestaña nueva.

### Instalar en iPhone

1. Abrir `https://luis-r66.github.io/SemiFund/` **en Safari** (Chrome y Firefox en iOS no permiten instalarla).
2. Compartir → **Añadir a pantalla de inicio**.
3. Queda como una app con su ícono; abre a pantalla completa.

No hay app nativa de iOS: eso exigiría Apple Developer (99 USD/año) y un Mac. La PWA es la vía disponible.

Dentro de la app instalada conviene entrar con **correo y contraseña**: iOS puede no devolver el control después del selector de cuentas de Google. En Safari normal, Google sí funciona.

Para probar en local (web de escritorio):

```bash
cd mobile
flutter run -d chrome --web-port 8080 \
  --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

Para generar el build de escritorio:

```bash
flutter build web --release --base-href /SemiFund/web/ \
  --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

Para regenerar el build de iPhone (rama congelada):

```bash
git checkout iphone
cd mobile
flutter build web --release --base-href /SemiFund/ \
  --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

## Comprobantes de abonos con Cloudinary

- En el detalle de un aporte, cada abono tiene **Adjuntar comprobante** (integrante dueño o tesorero).
- Se aceptan JPG, PNG, WebP y PDF de hasta **5 MB**, uno por abono.
- El backend recibe el archivo en memoria con `multer`, lo sube a Cloudinary y guarda `url`, `publicId`, `tipo` y `nombre` dentro del abono.
- El APK solo muestra o abre el comprobante; **nunca** maneja el API secret.
- Al reemplazar un comprobante se borra el anterior de Cloudinary (best-effort).
- Al anular un abono el comprobante se conserva como evidencia.
- Carpetas en Cloudinary: `semifund/comprobantes`.

## Mantener despierta la API en Render

Render Free duerme por inactividad. `.github/workflows/render-ping.yml` llama cada 10 minutos a `https://semifund-api.onrender.com/health` y falla si la respuesta no es `{"ok":true}`.

- Se puede ejecutar a mano desde **Actions → Render ping → Run workflow**.
- GitHub puede retrasar las ejecuciones programadas; el workflow reintenta hasta 4 veces para cubrir el arranque en frío.
- Si cambia el dominio de Render, actualiza la URL del workflow.


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
- Producción (Render) → `https://semifund-api.onrender.com/api`
- Permiso `INTERNET` en `AndroidManifest` + `usesCleartextTraffic="true"` si es `http`.
- Detalle de JSON por endpoint: ver `API_CONTRACT.md` (incluye interfaz Retrofit + data classes Kotlin).

La app no necesita Node ni MongoDB locales: el APK release usa Render por defecto.

```bash
cd mobile
flutter build apk                # release → https://semifund-api.onrender.com/api
flutter run                      # debug → emulador local
flutter build apk --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Sin `--dart-define`, debug usa `10.0.2.2` y release usa Render. Revisa `lib/core/config/app_config.dart`.


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
  services/ (excelTemplate.js, excelImport.js)
  utils/balance.js (agregaciones en vivo)
  utils/importValidation.js (reglas puras de la plantilla)
postman/Semillero-API.postman_collection.json
API_CONTRACT.md (contrato para Android)
```

## Demostración en vivo (sustentación)

- Crear: `POST /members` → `POST /contributions` → `PATCH .../pay` → `GET /balance` (sube el saldo).
- 404: `GET /members/000000000000000000000000`.
- 409: `POST /expenses` con monto `999999999`, o `PATCH .../pay` dos veces.
- 400: `POST /members` sin `nombre`.
- Soft delete: `DELETE /members/:id` → `GET` muestra `activo:false`.
