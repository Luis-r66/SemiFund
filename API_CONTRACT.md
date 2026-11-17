# API Contract — Tesorería Semillero de Software

> Versión 1.5.2. Fuente de verdad para la app Android. Todo es JSON salvo los
> endpoints `multipart` de comprobantes y aportes propios.
> Base URL: `http://<HOST>:<PUERTO>/api` — local `http://10.0.2.2:3000/api` (emulador) o `http://<IP-LAN>:3000/api` (físico).

## 1. Modelos

### Member

```json
{
  "id": "uuid",
  "_id": "uuid",
  "nombre": "Ana Torres",
  "nombres": "Ana",
  "apellidos": "Torres",
  "tipoUsuario": "estudiante",
  "programa": "Ingeniería de Software",
  "semestre": 5,
  "esCuentaVinculada": true,
  "activo": true,
  "fechaIngreso": "2026-02-10T15:00:00.000Z"
}
```

| Campo | Reglas |
|---|---|
| nombre | requerido, no vacío |
| nombres / apellidos | opcionales; se usan para iniciales |
| tipoUsuario | `estudiante`, `profesor` o `null` |
| programa | requerido, no vacío; para profesor es el área |
| semestre | requerido para estudiante, 1–10; `null` para profesor |
| esCuentaVinculada | `true` si el integrante está vinculado a un `User` |
| activo / fechaIngreso | autogenerados |

### Contribution

```json
{
  "id": "uuid",
  "integranteId": "uuid-member",
  "monto": 50000,
  "mes": "2026-09",
  "concepto": "Cuota mensual",
  "tipo": "cuota",
  "estado": "pendiente",
  "fechaPago": null
}
```

`estado`: `pendiente|pagado|vencido|reportado`. `tipo`: `cuota|aporte`; los registros anteriores a la 1.5.2 se devuelven como `cuota`. `mes`: `YYYY-MM`. `monto` > 0. `concepto`: requerido, no vacío.
Campos nuevos: `referencia`, `fechaReporte`, `reportadoPor`, `fechaRevision`, `revisadoPor`, `motivoRechazo`.
La respuesta de `GET /api/contributions` agrega `esPropio` para indicar si el aporte pertenece al integrante de la sesión.
El **integrante solo recibe sus propios registros**: el filtro se aplica en el servidor. El tesorero puede filtrar con `memberId`.
La **cuota** es única por integrante y mes. Los **aportes** (viaje, materiales, etc.) pueden repetirse en el mismo mes y convivir con la cuota.

### Expense

```json
{
  "id": "uuid",
  "descripcion": "Inscripción evento",
  "categoria": "eventos",
  "monto": 120000,
  "fecha": "2026-09-12T10:00:00.000Z"
}
```

### Balance

```json
{
  "saldoInicial": 200000,
  "totalAportado": 350000,
  "totalGastado": 120000,
  "saldoDisponible": 430000
}
```

Calculado en vivo, no almacenado: `saldoDisponible = saldoInicial + totalAportado − totalGastado`.
`saldoInicial` es dinero que el semillero ya tenía y **no** es aporte de ningún integrante.
Los semilleros anteriores a la 1.5.0 lo devuelven en `0`. Error: `{ "error": "mensaje" }`.

## 2. Endpoints

### Members

```
GET    /api/members
GET    /api/members?activo=true|false
GET    /api/members/:id            -> 200 | 404 {"error":"Integrante no encontrado"}
POST   /api/members                -> 201 | 400
PUT    /api/members/:id            -> 200 | 400 | 404 | 409
  - Integrante manual: nombre, nombres, apellidos, programa, semestre 1-10, activo.
  - Integrante vinculado a cuenta: solo activo; los datos académicos se editan desde /api/auth/me.
DELETE /api/members/:id            -> 204 (activo=false) | 404
```

Crear:

```json
{ "nombre": "Luis Riascos", "programa": "Ingeniería de Software", "semestre": 6 }
```

Editar (parcial):

```json
{ "nombre": "Luis E. Riascos", "semestre": 7 }
```

### Contributions

```
GET   /api/contributions
GET   /api/contributions?status=pending&memberId=
POST  /api/contributions            -> 201 | 400 | 409 cuota duplicada
POST  /api/contributions/bulk       -> 201 cuotas o aportes para todos los activos
POST  /api/contributions/self       -> 201 aporte propio reportado | 400 | 403 | 413 | 415 | 503
PATCH /api/contributions/:id/pay    -> 200 | 404 | 409
PATCH /api/contributions/:id/reject -> 200 | 404 | 409
DELETE /api/contributions/:id      -> 204 | 404 | 409 cuota con abonos
POST  /api/contributions/:id/payments -> 201 abono | 400 | 403 | 404 | 409 | 413 | 415 | 503
PATCH /api/contributions/:id/payments/:abonoId/approve -> 200 | 404 | 409
PATCH /api/contributions/:id/payments/:abonoId/reject  -> 200 | 404 | 409
PATCH /api/contributions/:id/payments/:abonoId/void    -> 200 | 404 | 409
POST  /api/contributions/:id/payments/:abonoId/comprobante -> 200 | 400 | 403 | 404 | 409 | 413 | 415 | 503
```

`status`: `pending|paid|overdue|reported` (= `pendiente|pagado|vencido|reportado`).

- `pay`: solo tesorero. Acepta pendiente, vencido o reportado; guarda `fechaPago`, `fechaRevision` y `revisadoPor`.
- `reject`: solo tesorero y solo sobre un aporte `reportado`; lo devuelve a `pendiente` y guarda `motivoRechazo`. Se conserva para datos anteriores.
- `bulk`: solo tesorero. Crea la misma cuota para todos los activos y omite a quien ya la tenga. Con `tipo: "aporte"` omite solo a quien ya tenga el mismo aporte (`mes + concepto`), de modo que se pueda repetir para integrantes nuevos.
- `self`: cualquier integrante con ficha activa crea **su propio aporte** (`tipo: "aporte"`), adjunta el comprobante obligatorio y queda en estado `reportado` para que el tesorero lo apruebe.
- `payments`: el integrante reporta un abono propio y **debe enviar comprobante en el mismo multipart**. El monto que envíe se ignora: el abono cubre siempre el saldo pendiente completo. El tesorero registra dinero recibido (total o parcial) y puede omitir el comprobante.
- `DELETE /contributions/:id`: solo tesorero. Elimina una cuota o aporte **sin abonos** y responde `204`. Si existe cualquier abono responde `409 {"error":"La cuota tiene abonos registrados; no se puede eliminar"}`. La auditoría guarda el mes, el monto, el estado y el nombre del integrante.
- `approve` / `reject` / `void`: solo tesorero. Un rechazo exige motivo en la app y devuelve el registro a su estado anterior.

Crear:

```json
{ "integranteId": "uuid", "monto": 50000, "mes": "2026-09", "concepto": "Cuota mensual", "tipo": "cuota" }
```

`tipo` es opcional y vale `cuota` por defecto. Una segunda cuota del mismo integrante y mes responde `409`; los aportes con `tipo: "aporte"` se pueden repetir.

Aporte masivo:

```json
{ "mes": "2026-09", "monto": 40000, "concepto": "Viaje a Medellín", "tipo": "aporte" }
```

Aporte propio (multipart `multipart/form-data`):

```
monto=40000
mes=2026-09
concepto=Viaje a Medellín
referencia=TRX-123       # opcional
comprobante=@pago.png    # obligatorio
```

Reportar abono (multipart `multipart/form-data`):

```
monto=25000              # solo tesorero: total o parcial. Para el integrante se ignora
referencia=TRX-123       # opcional
comprobante=@pago.png    # obligatorio para el integrante
```

Reglas del comprobante: JPG, PNG, WebP o PDF; máximo 5 MB; un archivo.
Sin comprobante el integrante recibe `400 {"error":"Adjunta el comprobante del abono"}` y **no** se crea el abono.
Si Cloudinary no está configurado, `503`; si el tipo no es válido, `415`. En ambos casos tampoco se guarda el abono.

Pagar: `PATCH` sin body → `estado: "pagado"` + `fechaPago`. Repetir → `409 {"error":"El aporte ya fue pagado"}`.

### Expenses

```
GET  /api/expenses
GET  /api/expenses?category=transporte&month=2026-10
POST /api/expenses -> 201 | 400 (fecha futura o inválida) | 409 {"error":"Saldo insuficiente"}
```

Crear:

```json
{ "descripcion": "Bus evento Cali", "categoria": "transporte", "monto": 20000 }
```

### Balance

```
GET /api/balance -> 200 { saldoInicial, totalAportado, totalGastado, saldoDisponible }
```

### Avisos y resumen

```
GET   /api/summary -> 200 { balance, activeMembers, pendingContributions, expensesCount, generatedAt }
GET   /api/notifications?page=1&limit=20&unread=true
GET   /api/notifications/unread-count -> 200 { count }
POST  /api/notifications/read-all -> 200 { updated }
PATCH /api/notifications/:id/read
GET   /api/notifications/preferences -> 200 { avisosPorCorreo }
PATCH /api/notifications/preferences -> 200 { avisosPorCorreo }
```

`pendingContributions` es personal para el integrante (solo sus cuotas sin pagar); el tesorero ve todo el semillero. Sin integrante vinculado el valor es `0`.

- Listados sin `page`/`limit` devuelven el arreglo completo (compatibilidad con la app Android).
- Eventos: `abono_reportado`, `abono_aprobado`, `abono_rechazado`, `cuota_nueva` e `invitacion_aceptada`.
- Cada aviso se guarda por usuario y semillero; también se envía por correo (Brevo) salvo que el usuario lo desactive.
- Fichas sin cuenta vinculada no reciben avisos.

### Reportes

```
GET /api/reports/movimientos.csv -> 200 text/csv | 403
```
- Solo tesorero del semillero activo.
- Un solo archivo con aportes y gastos, separados por la columna `tipo_registro`.
- Columnas: `tipo_registro, semillero_codigo, semillero_nombre, periodo, fecha, fecha_pago, integrante_nombre, integrante_email, programa, semestre, descripcion, categoria, monto, moneda, estado, referencia, id_origen`.
- `integrante_email` sale de la cuenta vinculada; si el integrante es manual, queda vacío.
- UTF-8 con BOM, separador coma, fechas `YYYY-MM-DD`, montos con dos decimales.
## 6. Autenticación y semilleros (Fase 2)

### Auth (públicas)

```
POST   /api/auth/register  { nombres, apellidos, email, password } -> 201 { token, user } | 400 | 409 | 429
POST   /api/auth/login     { email, password }                     -> 200 { token, user } | 401 | 429
POST   /api/auth/logout    (Authorization)                         -> 200
GET    /api/auth/me        (Authorization)                         -> 200 { id, nombre, nombres, apellidos, email, tipoUsuario, programa, semestre, semilleros[] }
PATCH  /api/auth/me        (Authorization) { nombres?, apellidos?, tipoUsuario?, programa?, semestre? } -> 200 | 400
PATCH  /api/auth/password  (Authorization) { currentPassword, newPassword } -> 200 { token, mensaje } | 400 | 401 | 429
POST   /api/auth/forgot-password { email }                         -> 200 mensaje genérico | 400 | 429 | 503
POST   /api/auth/reset-password  { email, code, password }         -> 200 | 400 | 429
```

`password` mínimo 8 caracteres. `email` se guarda en minúsculas y debe ser único. El token JWT expira en 7d.
`nombres` y `apellidos` son los campos nuevos; por compatibilidad, un cliente anterior todavía puede enviar `nombre`.
`register` responde `requierePerfil: true`; la app debe enviar a completar perfil académico.

Perfil académico:
- `tipoUsuario`: `estudiante | profesor`.
- `programa`: carrera para estudiante; área o departamento para profesor.
- `semestre`: entero 1–10, obligatorio para estudiante; `null` para profesor.
- "Profesor" es solo un dato de perfil; no cambia los permisos de tesorero/integrante.

Recuperación:
- `forgot-password` genera un código de 6 dígitos, lo envía por Brevo y responde genéricamente para no revelar si el correo existe.
- El código vence en 15 minutos, es de un solo uso y admite máximo 5 intentos.
- `reset-password` invalida las sesiones anteriores mediante `tokenVersion`.
- `PATCH /auth/password` pide la contraseña actual, incrementa `tokenVersion` y devuelve un token nuevo.
- Rate limiting: `429` en login, registro, recuperación y cambio de contraseña.
- Variables de entorno: `MAIL_MODE` (`console` en local, `brevo` en producción), `BREVO_API_KEY`, `MAIL_FROM`, `MAIL_FROM_NAME`.
### Semilleros (hub — requieren Authorization, no `X-Semillero-Id`)

```
GET    /api/semilleros                          -> 200 [ { semilleroId, semilleroNombre, semilleroCodigo (solo tesorero), esTesorero, esCreador, estado, miembros, saldoInicial, saldoInicialNota, puedeAjustarSaldoInicial } ]
POST   /api/semilleros  { nombre, saldoInicial?, saldoInicialNota? } -> 201 { semillero: { id, nombre, codigo, saldoInicial }, saldoInicial, memberId } | 400
POST   /api/semilleros/join  { codigo }         -> 201 { semilleroId, semilleroNombre, estado } | 404 | 409
```

El creador queda como **tesorero automático** y se crea su `Member` vinculado con los datos académicos de su cuenta. El código de invitación tiene 8 caracteres alfanuméricos, es permanente y rotable; solo el tesorero lo ve.
La creación del semillero, su integrante inicial y su membresía se revierte si falla una etapa.
Las membresías cuyo semillero ya no existe o fue eliminado se omiten de las respuestas de listado y perfil. `esCreador` indica si la cuenta creó el semillero activo.
`saldoInicial` es opcional, mayor o igual a cero y **no crea aportes**. `puedeAjustarSaldoInicial` indica si la cuenta puede corregirlo.

### Semillero activo (requieren Authorization + encabezado `X-Semillero-Id`)

```
GET    /api/semilleros/me                                            -> 200 { id, nombre, creadoPor, esTesorero, esCreador, saldoInicial: { monto, nota, registradoPor, actualizadoEn }, puedeAjustarSaldoInicial, codigo? }
PATCH  /api/semilleros/me/saldo-inicial  { monto, nota? }            -> 200 { saldoInicial, totalAportado, totalGastado, saldoDisponible } | 400 | 403
PATCH  /api/semilleros/me  { nombre }                                -> 200 | 400 (solo tesorero)
POST   /api/semilleros/me/code/rotate                                -> 200 { codigo } (solo tesorero)
GET    /api/semilleros/me/accounts                                   -> 200 [ { id, usuario, integrante, esTesorero, estado, fechaSolicitud } ]
PATCH  /api/semilleros/me/accounts/:membershipId  { estado?, esTesorero? } -> 200 | 404 | 409 (solo tesorero)
POST   /api/semilleros/me/leave                                     -> 200 { ok, mensaje } | 409 (último tesorero)
DELETE /api/semilleros/me  { confirmacion }                         -> 200 { ok, mensaje } | 400 nombre no coincide | 403 no es el creador
```

`estado` de una membresía: `pendiente | activo | rechazado | inactivo`. Al aprobar (`estado: 'activo'`) se reactiva el `Member` existente de esa cuenta o se crea si no hay; es idempotente y no duplica integrantes. Al reingresar con un código se conserva el `memberId` para que las cuotas anteriores sigan ligadas a la misma persona. Nunca se puede quedar el semillero sin al menos un tesorero activo (409).

El nombre del semillero admite letras, espacios y signos como `&`, punto, coma, apóstrofe o guion; **no admite números** (`400`).

Saldo inicial:

- `GET /semilleros/me` devuelve `saldoInicial.monto`, `saldoInicial.nota`, quién lo registró y cuándo. Los semilleros anteriores a la 1.5.0 responden `{ monto: 0 }` sin reescribir el documento.
- `PATCH /semilleros/me/saldo-inicial` acepta `monto >= 0` y una nota de hasta 300 caracteres. Recalcula el saldo y devuelve también `totalAportado`, `totalGastado` y `saldoDisponible`.
- Puede ajustarlo quien creó el semillero. Si el creador ya no tiene membresía activa, puede hacerlo el tesorero actual. En cualquier otro caso `403`.
- Cada ajuste guarda en auditoría el monto anterior, el nuevo, el usuario y la nota. No crea ni modifica aportes de los integrantes.

Salir y eliminar:
- `POST /me/leave` marca la membresía como `inactivo` y desactiva su `Member`. Cualquier integrante activo puede salir; el último tesorero activo recibe `409` y debe transferir la tesorería antes.
- `DELETE /me` es un borrado lógico: exige ser quien creó el semillero y que `confirmacion` coincida con el nombre (sin distinguir mayúsculas, tildes ni espacios extra). Marca `activo: false`, guarda `eliminadoEn`/`eliminadoPor`, deja las membresías inactivas y los integrantes inactivos, y registra el hecho en la auditoría.
- Un semillero eliminado responde `403 { code: "semillero_eliminado" }` a cualquier petición con `X-Semillero-Id`; la app debe volver a la lista de semilleros.

`PATCH /api/contributions/:id/pay` valida el `id` como ObjectId y responde `400` si no es válido.

### Modelo de relación (usuarios, membresías e integrantes)

- `User`: cuenta de acceso (id, nombre, nombres, apellidos, email, tipoUsuario, programa, semestre, passwordHash, tokenVersion).
- `Membership`: vincula un `User` con un `Semillero` (`userId`, `semilleroId`, `esTesorero`, `estado`, `memberId?`). Un usuario solo puede tener una membresía por semillero.
- `Semillero`: conserva `creadoPor`, `saldoInicial` (`monto`, `nota`, `registradoPor`, `actualizadoEn`), `activo`, `eliminadoEn` y `eliminadoPor` para el borrado lógico y la auditoría.
- `Member`: integrante que aporta (`userId?`, `nombre`, `nombres`, `apellidos`, `tipoUsuario`, `programa`, `semestre`, `activo`, `semilleroId`). Si está vinculado a una cuenta, el perfil académico se sincroniza desde `User` al crear el semillero, aprobar la solicitud o actualizar `/api/auth/me`. El tesorero no puede editar los datos académicos de un integrante vinculado.
- Todos los miembros del semillero pueden consultar aportes y gastos; solo el tesorero puede crear cuotas, aportes grupales y gastos. El integrante solo ve sus propios registros y puede crear un aporte propio con comprobante obligatorio, además de reportar sus cuotas.

## 3. Reglas (backend manda)

1. Gasto > `saldoDisponible` → `409 Saldo insuficiente`. El disponible incluye el saldo inicial.
2. Aporte: `pendiente→reportado→pagado`, `vencido→reportado→pagado`, `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`; desde `pagado` nada → `409`. Un rechazo devuelve el aporte a `pendiente`.
3. Un integrante solo ve sus propios registros y no puede reportar el de otro (`403`). El tesorero no puede crear dos **cuotas** del mismo integrante y mes (`409`); los **aportes** sí pueden repetirse en el mismo mes.
4. Reportar un abono exige comprobante en el mismo multipart; sin archivo → `400` y no se crea el abono. Si Cloudinary falla (`503`) o el tipo no es válido (`415`), tampoco se guarda. El tesorero puede registrar efectivo sin comprobante.
5. El saldo inicial no es un aporte ni genera cuotas: se ajusta aparte, siempre auditado, y puede dejar el disponible en negativo (la app lo advierte en rojo).
6. `DELETE /members/:id` no borra, pone `activo:false`. Reactivar: `PUT /members/:id` con `{ "activo": true }`.
7. Aporte `pendiente` con `mes` anterior al actual se actualiza a `vencido` al consultar.

## 4. Códigos

200 GET/PUT/PATCH · 201 POST · 204 DELETE · 400 validación · 401 no autenticado · 403 sin permiso · 404 no existe · 409 regla de negocio · 429 demasiados intentos · 500 interno · 503 correo no disponible.

## 5. Android (Retrofit + Kotlin)

```kotlin
const val BASE_URL = "http://10.0.2.2:3000/api/"
```

```kotlin
interface SemilleroApi {
    @GET("members")
    suspend fun getMembers(@Query("activo") activo: Boolean? = null): List<Member>

    @GET("members/{id}")
    suspend fun getMember(@Path("id") id: String): Member

    @POST("members")
    suspend fun createMember(@Body body: CreateMemberRequest): Member

    @PUT("members/{id}")
    suspend fun updateMember(@Path("id") id: String, @Body body: Map<String, @JvmSuppressWildcards Any?>): Member

    @DELETE("members/{id}")
    suspend fun deactivateMember(@Path("id") id: String)

    @GET("contributions")
    suspend fun getContributions(
        @Query("status") status: String? = null,
        @Query("memberId") memberId: String? = null
    ): List<Contribution>

    @POST("contributions")
    suspend fun createContribution(@Body body: CreateContributionRequest): Contribution

    @POST("contributions/bulk")
    suspend fun createBulkContributions(@Body body: CreateBulkContributionRequest): BulkResult

    @Multipart
    @POST("contributions/self")
    suspend fun createSelfContribution(
        @Part("monto") monto: RequestBody,
        @Part("mes") mes: RequestBody,
        @Part("concepto") concepto: RequestBody,
        @Part("referencia") referencia: RequestBody?,
        @Part comprobante: MultipartBody.Part
    ): Contribution

    @PATCH("contributions/{id}/pay")
    suspend fun payContribution(@Path("id") id: String): Contribution

    @GET("expenses")
    suspend fun getExpenses(
        @Query("category") category: String? = null,
        @Query("month") month: String? = null
    ): List<Expense>

    @POST("expenses")
    suspend fun createExpense(@Body body: CreateExpenseRequest): Expense

    @GET("balance")
    suspend fun getBalance(): Balance

    @Multipart
    @POST("contributions/{id}/payments")
    suspend fun reportPayment(
        @Path("id") id: String,
        @Part("monto") monto: RequestBody?,
        @Part("referencia") referencia: RequestBody?,
        @Part comprobante: MultipartBody.Part?
    ): Contribution
}
```

```kotlin
data class Member(
    val id: String,
    val nombre: String,
    val programa: String,
    val semestre: Int,
    val activo: Boolean,
    val fechaIngreso: String
)

data class CreateMemberRequest(val nombre: String, val programa: String, val semestre: Int)

data class Contribution(
    val id: String,
    val integranteId: String,
    val monto: Double,
    val mes: String,
    val concepto: String,
    val tipo: String = "cuota",
    val estado: String,
    val fechaPago: String?
)

data class CreateContributionRequest(
    val integranteId: String,
    val monto: Double,
    val mes: String,
    val concepto: String,
    val tipo: String = "cuota"
)

data class CreateBulkContributionRequest(
    val monto: Double,
    val mes: String,
    val concepto: String,
    val tipo: String = "cuota"
)

data class BulkResult(val creadas: Int, val omitidas: List<Any>)

data class Expense(
    val id: String,
    val descripcion: String,
    val categoria: String,
    val monto: Double,
    val fecha: String
)

data class CreateExpenseRequest(
    val descripcion: String,
    val categoria: String,
    val monto: Double,
    val fecha: String? = null
)

data class SaldoInicial(
    val monto: Double = 0.0,
    val nota: String? = null,
    val registradoPor: String? = null,
    val actualizadoEn: String? = null
)

data class SemilleroActivo(
    val id: String,
    val nombre: String,
    val creadoPor: String,
    val esTesorero: Boolean,
    val esCreador: Boolean,
    val saldoInicial: SaldoInicial = SaldoInicial(),
    val puedeAjustarSaldoInicial: Boolean = false,
    val codigo: String? = null
)

data class UpdateSaldoInicialRequest(val monto: Double, val nota: String? = null)

data class Balance(
    val saldoInicial: Double = 0.0,
    val totalAportado: Double,
    val totalGastado: Double,
    val saldoDisponible: Double
)
```
