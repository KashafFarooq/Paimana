# Paimana REST API v1

Base path: `/api/v1`. Success responses use `{ "success": true, "data": ... }`.
Errors use `{ "success": false, "error": { "code": "...", "message": "...", "details": [] } }`.
Except for `GET /health` and auth register/login/refresh, routes require
`Authorization: Bearer <accessToken>`. Customer and order documents are scoped
to the authenticated account.

## Health

`GET /health`

```json
{
  "success": true,
  "data": { "status": "ok" }
}
```

## Authentication

`POST /api/v1/auth/register`

```json
{ "name": "Ayesha Khan", "email": "ayesha@example.com", "password": "long-password-123" }
```

`POST /api/v1/auth/login`

```json
{ "email": "ayesha@example.com", "password": "long-password-123" }
```

Both return HTTP 201 (register) or 200 (login):

```json
{
  "success": true,
  "data": {
    "user": { "id": "68f000000000000000000001", "name": "Ayesha Khan", "email": "ayesha@example.com" },
    "accessToken": "<JWT>",
    "refreshToken": "<JWT>",
    "tokenType": "Bearer"
  }
}
```

`POST /api/v1/auth/refresh` accepts `{ "refreshToken": "<JWT>" }` and returns
the same token response shape. `GET /api/v1/auth/me` returns
`{ "success": true, "data": { "user": { "id", "name", "email" } } }`.
`POST /api/v1/auth/logout` revokes refresh tokens for the current account and
returns `{ "success": true, "data": { "message": "Signed out." } }`.

Passwords must be 10–128 characters. Access tokens expire after 15 minutes by
default; refresh tokens expire after 30 days. Override these defaults with
backend environment variables.

## Customers

`GET /api/v1/customers?q=ayesha&page=1&limit=50&updatedSince=<ISO-8601>` returns
`{ "success": true, "data": { "items": [<Customer>], "total": 1, "page": 1, "limit": 50 } }`.
Search is a literal, case-insensitive match against name and phone. `limit` is
restricted to 1–100. `updatedSince` supports incremental pulls.

Customer JSON:

```json
{
  "id": "68f000000000000000000002",
  "clientId": "local-device-uuid",
  "name": "Ayesha Khan",
  "phone": "+923001234567",
  "note": "Prefers a relaxed sleeve",
  "createdAt": "2026-10-28T08:00:00.000Z",
  "updatedAt": "2026-10-28T08:00:00.000Z"
}
```

`POST /api/v1/customers` accepts `{ "name": "Ayesha Khan", "phone": "+923001234567", "note": "Prefers a relaxed sleeve", "clientId": "local-device-uuid" }`.
`clientId` is optional; when supplied, it performs an owner-scoped upsert and
makes offline retries idempotent for that account. The Flutter client uses its
local record ID as the `clientId`, so the same ID works in `/:id` paths.
The response is HTTP 201 with `{ "success": true, "data": { "customer": <Customer> } }`.

`GET /api/v1/customers/:id` returns `{ "success": true, "data": { "customer": <Customer> } }`.
`PATCH /api/v1/customers/:id` accepts any non-empty subset of `name`, `phone`
and `note` and returns the same customer shape.
`DELETE /api/v1/customers/:id` returns
`{ "success": true, "data": { "id": "68f000000000000000000002" } }`.

## Orders

`GET /api/v1/orders?status=pending&page=1&limit=50&updatedSince=<ISO-8601>`
returns `{ "success": true, "data": { "items": [<Order>], "total": 1, "page": 1, "limit": 50 } }`.

```json
{
  "id": "68f000000000000000000003",
  "clientId": "local-order-uuid",
  "customerId": "68f000000000000000000002",
  "customerName": "Ayesha Khan",
  "garment": "Three-piece suit",
  "dueDate": "2026-11-12T00:00:00.000Z",
  "totalAmount": 18000,
  "paidAmount": 5000,
  "status": "stitching",
  "note": "Navy blue, lace on sleeves",
  "createdAt": "2026-10-28T08:00:00.000Z",
  "updatedAt": "2026-10-28T08:00:00.000Z"
}
```

`POST /api/v1/orders` accepts the order fields above, except `id`, `createdAt`
and `updatedAt`; `customerId` and `clientId` are optional, `paidAmount`,
`status` and `note` default to `0`, `pending` and `""`. The response is HTTP
201 with `{ "success": true, "data": { "order": <Order> } }`. Supplying
`clientId` performs an owner-scoped upsert for offline retry and lets the
Flutter app use that local ID in `/:id` paths. `paidAmount` cannot exceed
`totalAmount`; linked customers must belong to the same account.

`GET /api/v1/orders/:id` returns `{ "success": true, "data": { "order": <Order> } }`.
`PATCH /api/v1/orders/:id` accepts a non-empty subset of the order fields
except `clientId`, `createdAt` and `updatedAt`; it returns the same order
shape. `DELETE /api/v1/orders/:id` returns
`{ "success": true, "data": { "id": "68f000000000000000000003" } }`.
Deleting an order also removes its associated payment history atomically.

## Payments

Payment create/delete and order deletion use MongoDB transactions. The
configured MongoDB deployment must support transactions (MongoDB Atlas does).

`GET /api/v1/payments?orderId=<order-id-or-client-id>&page=1&limit=50` returns
`{ "success": true, "data": { "items": [<Payment>], "total": 1, "page": 1, "limit": 50 } }`.
Omit `orderId` to list payments for all orders belonging to the current
account. An `orderId` must refer to an order owned by that account.
When the order has a client ID, the response uses that client ID as
`orderId` so offline records can be matched; otherwise it returns the MongoDB
ID.

Payment JSON:

```json
{
  "id": "68f000000000000000000004",
  "clientId": "local-payment-uuid",
  "orderId": "68f000000000000000000003",
  "amount": 5000,
  "paymentType": "advance",
  "method": "cash",
  "paidAt": "2026-10-28T08:00:00.000Z",
  "note": "Advance received",
  "createdAt": "2026-10-28T08:00:00.000Z",
  "updatedAt": "2026-10-28T08:00:00.000Z"
}
```

`POST /api/v1/payments` accepts:

```json
{
  "orderId": "local-order-uuid",
  "clientId": "local-payment-uuid",
  "amount": 5000,
  "paymentType": "advance",
  "method": "cash",
  "paidAt": "2026-10-28T08:00:00.000Z",
  "note": "Advance received"
}
```

`orderId` may be a MongoDB ID or the order's client ID. `paymentType` is
`advance`, `partial` or `final`; `method` is `cash`, `bank_transfer`,
`mobile_wallet` or `other`. `amount` must be positive, and cannot exceed the
remaining order balance. A `final` payment must equal the remaining balance.
A supplied `clientId` makes retries idempotent for
the account: an identical retry returns the existing payment without changing
the order balance again, while a conflicting payload returns HTTP 409.
Success is HTTP 201 with
`{ "success": true, "data": { "payment": <Payment> } }`.

`DELETE /api/v1/payments/:id` accepts the payment MongoDB ID or client ID.
It atomically removes the payment and subtracts its amount from the associated
order's `paidAmount`. Success returns
`{ "success": true, "data": { "id": "68f000000000000000000004" } }`.

## AI assistant

`POST /api/v1/ai/:action`, authenticated and rate limited, accepts:

```json
{
  "text": "Extract a navy blue three-piece suit order for Ayesha",
  "context": { "language": "en" }
}
```

Supported `action` values: `order-extraction`, `measurement-extraction`,
`design-suggestions`, `fabric-calculator`, `price-estimator`,
`delivery-prediction`, `whatsapp-message`, `business-dashboard`,
`measurement-validation`, `repeat-order`, and `voice-order`.

Success response:

```json
{
  "success": true,
  "data": {
    "action": "order-extraction",
    "suggestion": "{\"customerName\":\"Ayesha\",\"garment\":\"Three-piece suit\"}",
    "requiresReview": true
  }
}
```

The suggestion is never persisted by the API. Gemini credentials stay on the
server (`GEMINI_API_KEY`) and are never sent to the Flutter client. The
application must present the response for human review before saving.

## Error contract

Validation errors return HTTP 400 with `error.code = "VALIDATION_ERROR"` and
field/message details. Missing or invalid authentication returns HTTP 401.
Unknown resources return HTTP 404. Duplicate email returns HTTP 409.
Unconfigured AI returns HTTP 503; upstream AI failures return HTTP 502.
