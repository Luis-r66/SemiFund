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
  "estado": "pendiente",
  "fechaPago": null
}
```

`estado`: `pendiente|pagado|vencido`. `mes`: `YYYY-MM`. `monto` > 0.

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
PUT    /api/members/:id            -> 200 | 400 | 404
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
{ "integranteId": "uuid", "monto": 50000, "mes": "2026-09" }
```

Pagar: `PATCH` sin body → `estado: "pagado"` + `fechaPago`. Repetir → `409 {"error":"El aporte ya fue pagado"}`.

### Expenses

```
GET  /api/expenses
GET  /api/expenses?category=transporte&month=2026-10
POST /api/expenses -> 201 | 400 | 409 {"error":"Saldo insuficiente"}
```

Crear:

```json
{ "descripcion": "Bus evento Cali", "categoria": "transporte", "monto": 20000 }
```

### Balance

```
GET /api/balance -> 200 { totalAportado, totalGastado, saldoDisponible }
```

## 3. Reglas (backend manda)

1. Gasto > saldo → `409 Saldo insuficiente`.
2. Aporte: `pendiente→pagado`, `pendiente→vencido`, `vencido→pagado`; desde `pagado` nada → `409`.
3. `DELETE /members/:id` no borra, pone `activo:false`.

## 4. Códigos

200 GET/PUT/PATCH · 201 POST · 204 DELETE · 400 validación · 404 no existe · 409 regla negocio · 500 interno.

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
    val estado: String,
    val fechaPago: String?
)

data class CreateContributionRequest(val integranteId: String, val monto: Double, val mes: String)

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
