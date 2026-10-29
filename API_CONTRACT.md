# API Contract — Tesorería Semillero de Software

> Fuente de verdad para la app Android. Todo es JSON.
> Base URL: `http://<HOST>:<PUERTO>/api` — local `http://10.0.2.2:3000/api` (emulador) o `http://<IP-LAN>:3000/api` (físico).

## 1. Modelos

### Member

```json
{
  "id": "uuid",
  "_id": "uuid",
  "nombre": "Ana Torres",
  "programa": "Ingeniería de Software",
  "semestre": 5,
  "activo": true,
  "fechaIngreso": "2026-02-10T15:00:00.000Z"
}
```

| Campo | Reglas |
|---|---|
| nombre | requerido, no vacío |
| programa | requerido, no vacío |
| semestre | requerido, 1–10 |
| activo / fechaIngreso | autogenerados |

### Contribution

```json
{
  "id": "uuid",
  "integranteId": "uuid-member",
  "monto": 50000,
  "mes": "2026-09",
  "concepto": "Cuota mensual",
  "estado": "pendiente",
  "fechaPago": null
}
```

`estado`: `pendiente|pagado|vencido`. `mes`: `YYYY-MM`. `monto` > 0. `concepto`: requerido, no vacío.

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
{ "totalAportado": 350000, "totalGastado": 120000, "saldoDisponible": 230000 }
```

Calculado en vivo, no almacenado. Error: `{ "error": "mensaje" }`.

## 2. Endpoints

### Members

```
GET    /api/members
GET    /api/members?activo=true|false
GET    /api/members/:id            -> 200 | 404 {"error":"Integrante no encontrado"}
POST   /api/members                -> 201 | 400
PUT    /api/members/:id            -> 200 | 400 | 404   (solo: nombre, programa, semestre 1-10, activo boolean; otros campos se ignoran)
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
POST  /api/contributions            -> 201 | 400 (incluye "El integrante no existe")
PATCH /api/contributions/:id/pay    -> 200 | 404 | 409
```

`status`: `pending|paid|overdue` (= `pendiente|pagado|vencido`).

Crear:

```json
{ "integranteId": "uuid", "monto": 50000, "mes": "2026-09", "concepto": "Cuota mensual" }
```

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
GET /api/balance -> 200 { totalAportado, totalGastado, saldoDisponible }
```
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
GET    /api/semilleros                          -> 200 [ { semilleroId, semilleroNombre, semilleroCodigo (solo tesorero), esTesorero, estado, miembros } ]
POST   /api/semilleros  { nombre }              -> 201 { semillero, memberId } | 400
POST   /api/semilleros/join  { codigo }         -> 201 { semilleroId, semilleroNombre, estado } | 404 | 409
```

El creador queda como **tesorero automático** y se crea su `Member` vinculado (`programa: 'Sin definir'`, `semestre: 1` hasta capturar datos reales). El código de invitación tiene 8 caracteres alfanuméricos, es permanente y rotable; solo el tesorero lo ve.
La creación del semillero, su integrante inicial y su membresía se revierte si falla una etapa.
Las membresías cuyo semillero ya no existe se omiten de las respuestas de listado y perfil.

### Semillero activo (requieren Authorization + encabezado `X-Semillero-Id`)

```
GET    /api/semilleros/me                                            -> 200 { id, nombre, creadoPor, esTesorero, codigo? }
PATCH  /api/semilleros/me  { nombre }                                -> 200 | 400 (solo tesorero)
POST   /api/semilleros/me/code/rotate                                -> 200 { codigo } (solo tesorero)
GET    /api/semilleros/me/accounts                                   -> 200 [ { id, usuario, integrante, esTesorero, estado, fechaSolicitud } ]
PATCH  /api/semilleros/me/accounts/:membershipId  { estado?, esTesorero? } -> 200 | 404 | 409 (solo tesorero)
```

`estado` de una membresía: `pendiente | activo | rechazado | inactivo`. Al aprobar (`estado: 'activo'`) se crea/vincula el `Member` de forma idempotente. Nunca se puede quedar el semillero sin al menos un tesorero activo (409).

`PATCH /api/contributions/:id/pay` valida el `id` como ObjectId y responde `400` si no es válido.

### Modelo de relación (usuarios, membresías e integrantes)

- `User`: cuenta de acceso (id, nombre, nombres, apellidos, email, tipoUsuario, programa, semestre, passwordHash, tokenVersion).
- `Membership`: vincula un `User` con un `Semillero` (`userId`, `semilleroId`, `esTesorero`, `estado`, `memberId?`). Un usuario solo puede tener una membresía por semillero.
- `Member`: integrante que aporta (`nombre`, `nombres`, `apellidos`, `programa`, `semestre`, `activo`, `semilleroId`). Es distinto de `User` y `Membership`; se crea al aprobar una solicitud o al crear el semillero. El perfil académico de la cuenta no se sincroniza automáticamente con este integrante.
- Todos los miembros del semillero pueden consultar aportes y gastos; solo el tesorero puede crear/editar/pagar/desactivar.

## 3. Reglas (backend manda)

1. Gasto > saldo → `409 Saldo insuficiente`.
2. Aporte: `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`; desde `pagado` nada → `409`.
3. `DELETE /members/:id` no borra, pone `activo:false`.
4. Reactivar un integrante: `PUT /members/:id` con `{ "activo": true }`.
5. Aporte `pendiente` con `mes` anterior al actual se devuelve como `vencido`.

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
    val estado: String,
    val fechaPago: String?
)

data class CreateContributionRequest(
    val integranteId: String,
    val monto: Double,
    val mes: String,
    val concepto: String
)

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

data class Balance(val totalAportado: Double, val totalGastado: Double, val saldoDisponible: Double)
```
