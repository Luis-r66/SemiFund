# SemiFund

Tesorería clara para semilleros: aportes, abonos, gastos y auditoría, con roles de tesorero e integrante.

**API REST en Node.js + app Flutter.** Proyecto individual: API propia para el control de integrantes, aportes y gastos del semillero, con colección de pruebas Postman.

`mobile/` Flutter (Android + web) · `backend/` Node.js + Express + Mongoose · `postman/` colección exportada · DB MongoDB Atlas (`semillero`).

## Abrir la app

- **Web de escritorio:** https://luis-r66.github.io/SemiFund/web/
- **iPhone (PWA, congelada en la rama `iphone`):** https://luis-r66.github.io/SemiFund/
- **APK Android:** https://github.com/Luis-r66/SemiFund/releases/latest

Las tres consumen la API de Render: `https://semifund-api.onrender.com/api`.
El detalle de las dos compilaciones web está en la sección **Versión web**, más abajo.

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

Los avisos de la campanita (abonos, cuotas e invitaciones aceptadas) usan el mismo
envío de Brevo. Cada usuario puede desactivarlos desde la campanita; además,
`WEB_URL` define el enlace del botón de los correos
(por defecto `https://luis-r66.github.io/SemiFund/web/`).

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
npm run dev    # desarrollo (node --watch)
npm start      # producción
```

Verificar: `GET http://localhost:3000/health` → `{ "ok": true, "version": "1.6.2" }`.

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
| PATCH | `/auth/password` `{currentPassword, newPassword}` | 200 `{token}` | 400 contraseña incorrecta, 401 sin sesión, 429 |
| POST | `/auth/logout` | 200 mensaje | 401 |
| POST | `/auth/forgot-password` `{email}` | 200 mensaje genérico | 400, 429, 503 |
| POST | `/auth/reset-password` `{email, code, password}` | 200 | 400, 429 |

- `tipoUsuario`: `estudiante | profesor`.
- Estudiante: `programa` y `semestre` (1–10).
- Profesor: área/departamento en `programa`, sin semestre.
- `nombres`/`apellidos` son los campos nuevos; `nombre` sigue aceptándose por compatibilidad.
- El código de recuperación tiene 6 dígitos, vence en 15 minutos, es de un solo uso y máximo 5 intentos.
- `PATCH /auth/password` y `reset-password` invalidan sesiones anteriores con `tokenVersion`.
- `POST /auth/logout` también sube `tokenVersion`: el token deja de servir de inmediato. Como el JWT dura 7 días y no se puede borrar, esto cierra además las sesiones abiertas en otros dispositivos con la misma cuenta.
- Una contraseña actual incorrecta responde `400`, no `401`: la sesión sigue siendo válida y la app muestra el error en el formulario.

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
| POST | `/contributions` `{integranteId, monto, mes, concepto, tipo?}` | 201 | 400, 409 cuota duplicada |
| POST | `/contributions/bulk` `{mes, monto, concepto, tipo?, integranteIds?}` | 201 `{creadas, omitidas}` | 400, 403 no tesorero |
| PATCH | `/contributions/:id/pay` | 200 | 404, 409 ya pagado |
| PATCH | `/contributions/:id/reject` `{motivo?}` | 200 | 404, 409 no está reportado |
| DELETE | `/contributions/:id` (solo sin abonos) | 204 | 404, 409 tiene abonos |
| POST | `/contributions/:id/payments` (multipart: `monto?`, `referencia?`, `comprobante`) | 201 abono | 400 falta comprobante, 403, 404, 409, 413, 415, 503 |
| PATCH | `/contributions/:id/payments/:abonoId/approve` | 200 | 404, 409 abono no reportado |
| PATCH | `/contributions/:id/payments/:abonoId/reject` `{motivo?}` | 200 | 404, 409 abono no reportado |
| PATCH | `/contributions/:id/payments/:abonoId/void` | 200 | 404, 409 abono no aprobado |
| POST | `/contributions/:id/payments/:abonoId/comprobante` (multipart `comprobante`) | 200 aporte actualizado | 400, 403, 404, 409, 413, 415, 503 |
| GET | `/semilleros/me` | 200 detalle, saldo inicial y permiso de ajuste | 401, 403 |
| PATCH | `/semilleros/me/saldo-inicial` `{monto, nota?}` | 200 saldo recalculado | 400, 403, 404 |
| GET | `/expenses?category=&month=YYYY-MM` | 200 | 400 |
| POST | `/expenses` `{descripcion, categoria, monto, fecha?}` (sin fecha futura) | 201 | 400, 409 saldo insuficiente |
| GET | `/balance` → `{saldoInicial, totalAportado, totalGastado, saldoDisponible}` | 200 | — |
| GET | `/reports/movimientos.csv` | 200 CSV | 403 no tesorero |
| GET | `/reports/libro.xlsx` | 200 Excel (Integrantes, Aportes, Abonos, Gastos, Listas, Resumen) | 403 no tesorero |
| GET | `/reports/plantilla.xlsx` | 200 Excel para importar | 403 no tesorero |
| POST | `/import/preview` (cuerpo `.xlsx`) | 200 vista previa fila por fila | 400, 413 más de 8 MB |
| POST | `/import/confirm` (cuerpo `.xlsx`) | 201 resumen de creados | 409 sin filas nuevas, 422 errores, 413 |
| GET | `/audit?limit=100` | 200 historial | 403 no tesorero |

`status` en query: `pending|paid|overdue|reported` → `pendiente|pagado|vencido|reportado` en DB. `GET /contributions` agrega `esPropio` a cada aporte.

- El integrante solo ve y reporta **sus propios registros**: el filtro se aplica en el servidor, no solo en la app.
- **Cuota** y **aporte** son tipos distintos: la cuota es la mensualidad única por integrante y mes; el aporte es un destino concreto (viaje, materiales, etc.) y puede repetirse en el mismo mes. `tipo` es opcional y vale `cuota` por defecto; los registros anteriores a la 1.5.2 se leen como cuota.
- Desde la 1.6.0 el integrante **no crea aportes propios**: la tesorería asigna la cuota y los aportes a uno, varios o todos los integrantes, y el integrante reporta el pago desde el detalle.
- Reportar exige **comprobante en el mismo envío** (JPG, PNG, WebP o PDF, máximo 5 MB). Sin archivo la API responde `400` y no crea el abono. Si Cloudinary falla, tampoco queda un pago reportado sin respaldo.
- El integrante reporta siempre el **saldo pendiente completo**: la app muestra el monto fijo y la API ignora cualquier `monto` que envíe. El tesorero sí puede registrar abonos parciales.
- El tesorero puede **eliminar una cuota sin abonos** desde el detalle del aporte. Si tiene cualquier abono, la API responde `409` y la conserva para no perder evidencia contable. El borrado queda en auditoría con mes, monto, estado e integrante.
- El tesorero aprueba con `/pay` o con `/approve`, y rechaza con `/reject`. También puede registrar efectivo o consignación con `/payments` sin comprobante y adjuntarlo después.
- Los abonos parciales se guardan en `abonos[]` y actualizan `montoPagado`; el saldo y el estado `parcial` se calculan en el modelo. El tesorero puede anular un abono aprobado.
- Las cuotas masivas crean una cuota por integrante activo y omiten a quien ya tenga una para ese mes. Con `tipo: "aporte"` se omite a quien ya tenga el mismo aporte (`mes + concepto`), de modo que la operación se pueda repetir para integrantes nuevos.
- La cuota única por integrante y mes está respaldada por un índice parcial en Mongo, no solo por la comprobación previa: dos peticiones simultáneas ya no pueden duplicarla. Si la base trae cuotas repetidas de versiones anteriores, `npm run check:duplicate-fees` las lista para revisarlas a mano (no borra nada).
- El CSV `movimientos.csv` y el libro `libro.xlsx` incluyen aportes, gastos y la línea de saldo inicial. El correo del integrante sale de su cuenta; los integrantes manuales sin cuenta quedan con correo vacío.
- El perfil académico de la cuenta se sincroniza con los integrantes vinculados. El tesorero no puede editar carrera/semestre de un integrante con cuenta.
- La auditoría registra integrantes, aportes, abonos, gastos y ajustes de saldo inicial sin bloquear la operación principal.

### Saldo inicial

El saldo inicial es dinero que el semillero ya tenía antes de usar la app. **No es un aporte de ningún integrante**: no crea cuotas, no suma a «aportes por cobrar» y no aparece en el estado de cuenta de nadie.

- Se puede indicar al crear el semillero (`POST /semilleros` con `saldoInicial` y `saldoInicialNota`) o ajustar después con `PATCH /semilleros/me/saldo-inicial`.
- Puede ajustarlo quien creó el semillero. Si el creador ya no está activo, puede hacerlo el tesorero actual. Todo ajuste guarda el valor anterior, el nuevo, quién lo cambió y cuándo.
- Fórmula: `saldoDisponible = saldoInicial + aportes cobrados − gastos`. La validación de gastos usa ese valor, así que se puede gastar el dinero inicial antes de que existan cuotas.
- Los semilleros anteriores a la 1.5.0 quedan con saldo inicial `0`; no se reescriben datos.

## Plantilla Excel e importación

La app descarga `GET /reports/plantilla.xlsx` desde **Aportes → menú de Excel → Importar Excel → Descargar plantilla**, la llena y la sube en la misma ventana. La app muestra la vista previa antes de confirmar. El menú de Excel solo tiene **Importar Excel** y **Exportar libro completo**.

La plantilla solo usa los datos que hoy guarda el APK: nombres y apellidos, programa, semestre, tipo de usuario, aportes, abonos y gastos. No pide documento, correo ni teléfono.

Hojas del libro:

- `Instrucciones`: convenciones y advertencias.
- `Integrantes`: personas del semillero.
- `Aportes`: cuotas y aportes por integrante, con su tipo y mes.
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
npm test    # 92 pruebas en 16 archivos
```

## Documentos con plantillas propias

Solo para cuentas con `tipoUsuario: profesor`. El profesor sube su propio
`.docx` o `.xlsx` (el acta, la carta, el formato de la universidad), la app lo
llena con los datos del semillero y él descarga el archivo para enviarlo.

- El profesor decide qué escribir: dentro del archivo las marcas son
  `{{campo}}`, por ejemplo `{{semillero.nombre}}`, `{{profesor.nombre}}` o
  `{{mes}}`.
- Las listas se repiten con `{{#integrantes}}...{{/integrantes}}`,
  `{{#gastos}}...{{/gastos}}` y `{{#movimientos}}...{{/movimientos}}`. Dentro del
  bloque se escribe `{{nombre}}` o `{{integrantes.nombre}}`, ambas funcionan.
- Al subir la plantilla la app lee las etiquetas y rechaza el archivo con la
  lista exacta de las que no puede llenar. También rechaza un bloque sin cerrar.
- **Reemplazar** cambia el archivo conservando el nombre: sirve cuando la
  universidad cambia el formato cada semestre.
- **Generar** pide el mes y los datos propios del documento (fechas, ciudad,
  objeto, hora, lugar, observaciones, valor entregado). El backend entrega el
  archivo lleno y lo descarta: no se guarda en el servidor.
- No hay vista previa ni PDF: el profesor abre el Word o Excel descargado y lo
  convierte si lo necesita. Las marcas desaparecen del archivo generado.
- Las plantillas se guardan en Cloudinary (`semifund/plantillas`, tipo `raw`).
  Sin `CLOUDINARY_*` configurado, subir responde `503`.
- Un estudiante recibe `403` en todos los endpoints de documentos.

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

- Cuando el **integrante reporta**, el formulario exige **comprobante en el mismo paso**: monto, referencia opcional y archivo. Sin archivo no se envía.
- Se aceptan JPG, PNG, WebP y PDF de hasta **5 MB**, uno por abono.
- El backend recibe el archivo en memoria con `multer`, valida el tipo y lo sube a Cloudinary **antes** de guardar el abono. Si la subida falla, no queda un pago reportado sin respaldo.
- El **tesorero** conserva el registro de efectivo o consignación sin comprobante; si luego consigue el soporte, lo adjunta desde el detalle del abono.
- El APK solo muestra o abre el comprobante; **nunca** maneja el API secret.
- Al reemplazar un comprobante se borra el anterior de Cloudinary (best-effort).
- Al anular un abono el comprobante se conserva como evidencia.
- Carpetas en Cloudinary: `semifund/comprobantes`.

## Mantener despierta la API en Render

Render Free duerme por inactividad. `.github/workflows/render-ping.yml` llama cada 10 minutos a `https://semifund-api.onrender.com/health` y falla si la respuesta no contiene `"ok":true`. Ese endpoint también devuelve `version`, así se comprueba qué build está desplegado.

- Se puede ejecutar a mano desde **Actions → Render ping → Run workflow**.
- GitHub puede retrasar las ejecuciones programadas; el workflow reintenta hasta 4 veces para cubrir el arranque en frío.
- Si cambia el dominio de Render, actualiza la URL del workflow.


## Reglas de negocio (validadas en backend)

1. Gasto con `monto > saldoDisponible` → `409 { "error": "Saldo insuficiente" }` (`controllers/expenseController.js` + `utils/balance.js` con `aggregate` en vivo). El disponible incluye el saldo inicial.
2. Aporte: `pendiente→reportado→pagado`, `vencido→reportado→pagado`, `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`. Un rechazo devuelve el aporte a `pendiente`. Desde `pagado` nada → `409`.
3. Un integrante no puede ver ni reportar el registro de otro (`403`); el tesorero no puede crear dos **cuotas** del mismo integrante y mes (`409`). Los **aportes** pueden repetirse en el mismo mes.
4. Reportar sin comprobante → `400` y no se crea el abono. El tesorero sí puede registrar efectivo sin soporte.
5. El saldo inicial no es un aporte: se ajusta aparte, queda auditado y no crea cuotas ni avisos.
6. Al crear un semillero o aprobar una solicitud se copian los datos académicos de la cuenta; al actualizar el perfil se sincronizan los integrantes vinculados.

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

## Versión, actualizaciones y recorrido inicial

- La versión instalada se muestra en **Perfil → Acerca de**. La app consulta
  `https://api.github.com/repos/Luis-r66/SemiFund/releases/latest` como máximo
  una vez al día al abrir y también con el botón **Buscar actualizaciones**.
- Si hay una versión nueva, aparece un aviso en Inicio y en Perfil. En Android,
  **Descargar** abre el APK en el navegador y el sistema pide confirmación para
  instalarlo, porque fuera de Play Store no se puede instalar sola. En la web
  el aviso no descarga el APK: **Ver** abre la página de la release en GitHub.
- Las notas de la release se muestran como texto: el Markdown del cuerpo
  (`##`, `**`, viñetas) se limpia antes de dibujarlo.
- La introducción guiada aparece una vez por cuenta, cuando el inicio ya tiene
  datos, y señala con nubes los botones reales: saldo, aportes, gastos y
  documentos. Se puede saltar y repetir desde **Perfil → Ver introducción**.
- **Perfil → Ajustes del semillero** permite salir del semillero o, si la cuenta
  lo creó, eliminarlo escribiendo el nombre exacto. También muestra **Saldo
  inicial**, un ajuste auditado que no crea aportes, y los **datos del semillero**
  (ciudad y centro de costos) que se imprimen en los documentos; los edita el
  tesorero. Si el creador ya no está activo, el tesorero actual puede corregir el
  saldo. El último tesorero no puede salir sin transferir la tesorería. Eliminar
  es un borrado lógico: el semillero y su historial dejan de estar disponibles,
  pero quedan registrados para auditoría.

Para publicar una versión hay dos caminos:

**Automático (recomendado).** El workflow `.github/workflows/android-apk.yml`
compila el APK en GitHub, lo renombra a `SemiFund.apk` y lo adjunta a la
release. Se lanza al empujar un tag `vX.Y.Z` o a mano desde
**Actions → APK Android → Run workflow** indicando el tag (la release debe
existir).

**Manual.**

```bash
cd mobile
# subir version: 1.6.2+14 en pubspec.yaml
flutter build apk --release
# el adjunto debe llamarse SemiFund.apk para que la app lo encuentre primero
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/SemiFund.apk
gh release create v1.6.2 build/app/outputs/flutter-apk/SemiFund.apk \
  --title "SemiFund v1.6.2" --notes-file entrega/notas-v1.6.2.md
```

El APK adjunto debe llamarse `SemiFund.apk` (o terminar en `.apk`) para que la
app lo encuentre en la release. El build release sigue firmado con la clave
debug, así que el workflow no necesita secretos.


## Roles y administración

Los permisos viven en la **membresía**, no en la cuenta: una misma persona puede
ser tesorera en un semillero e integrante en otro.

- **Creador:** quien registra el semillero. Puede eliminarlo (borrado lógico) y
  transferir la tesorería.
- **Tesorero:** aprueba cuentas, crea cuotas y aportes grupales, aprueba abonos,
  registra gastos, descarga reportes y consulta la auditoría. Su propia cuota la
  registra directo, con comprobante opcional.
- **Integrante:** consulta **solo sus** registros, su estado de cuenta y reporta
  las cuotas que la tesorería le asignó. No crea aportes por su cuenta: cada
  cuota o aporte lo asigna el dueño a uno, varios o todos los integrantes. El
  contador del inicio es personal: el servidor filtra por su `memberId`.
- **Profesor:** además de lo anterior, sube sus plantillas y genera documentos.
- **Nombres:** los de personas y del semillero rechazan números en la app y en el
  servidor. Conceptos, descripciones, notas y referencias sí aceptan números.

No hay un administrador global. Es una decisión de alcance, no un olvido: con
roles por semillero nadie ve las finanzas de otro, y el soporte excepcional
(restaurar un semillero eliminado, desbloquear una cuenta) se hace por base de
datos. Si el proyecto creciera, un admin global exigiría un campo aparte en
`User` —nunca auto-registrable—, siembra por variable de entorno, validación
contra la base en cada petición, auditoría de cada acción y segundo factor.
Queda fuera de la v1.6.2.

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
  services/ (excelTemplate.js, excelImport.js, documentEngine.js, documentData.js)
  utils/balance.js (agregaciones en vivo)
  utils/importValidation.js (reglas puras de la plantilla)
  utils/programas.js (carreras y áreas)
postman/Semillero-API.postman_collection.json
API_CONTRACT.md (contrato para Android)
```

## Demostración en vivo (sustentación)

- Crear: `POST /members` → `POST /contributions` → `PATCH .../pay` → `GET /balance` (sube el saldo).
- 404: `GET /members/000000000000000000000000`.
- 409: `POST /expenses` con monto `999999999`, o `PATCH .../pay` dos veces.
- 400: `POST /members` sin `nombre`.
- Soft delete: `DELETE /members/:id` → `GET` muestra `activo:false`.


## Manuales

Los dos manuales se publican como adjuntos del release y no viven en el
repositorio:

- **Manual de usuario:** [SemiFund-Manual-de-usuario.pdf](https://github.com/Luis-r66/SemiFund/releases/download/v1.6.2/SemiFund-Manual-de-usuario.pdf)
- **Manual técnico:** [SemiFund-Manual-tecnico.pdf](https://github.com/Luis-r66/SemiFund/releases/download/v1.6.2/SemiFund-Manual-tecnico.pdf)

Ambos describen la versión 1.6.2 y usan capturas del semillero de prueba de las
pruebas golden, no de cuentas reales.

Las fuentes quedan fuera del repositorio (`entrega/manuales/` está ignorada por
git). Para regenerarlos:

```bash
cd entrega/manuales
node build.mjs      # Chrome headless imprime portada y cuerpo
python merge.py     # une, numera, agrega marcadores y metadatos
```

Requieren Chrome instalado y PyMuPDF (`pip install pymupdf`). Cuando cambie una
pantalla, hay que actualizar sus goldens (`flutter test --update-goldens`) y
copiar las imágenes nuevas a `entrega/manuales/img/` antes de reconstruir.
