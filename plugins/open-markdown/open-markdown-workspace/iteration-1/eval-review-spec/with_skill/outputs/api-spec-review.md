# API Spec Review — docs/api-spec.md

## Summary

The spec covers the essential skeleton of a task management REST API but is too thin to be production-ready. Every section has gaps that would leave a consumer guessing. The suggestions below are prioritised: **must-have** items block implementation; **should-have** items prevent common integration problems; **nice-to-have** items raise the quality bar.

---

## Section-by-section findings

### 1. Overview

**Issues**
- No base URL or environment list (production vs. staging).
- No API versioning strategy beyond the doc title. Is `v1` in the URL path? A query param? A header?
- No link to a changelog or deprecation policy.

**Suggested additions**
```
Base URL: https://api.example.com/v1
Environments: production (above), staging (https://staging-api.example.com/v1)
Versioning: URL path versioning — /v1/...
```

---

### 2. Authentication

**Issues**
- No explanation of how to obtain a Bearer token (OAuth2 flow? API key endpoint? Login endpoint?).
- No token expiry or refresh mechanism described.
- No mention of what happens on an invalid/expired token (which HTTP status code, which error shape).

**Suggested additions**
```
Token source: POST /auth/token with {email, password} → returns {access_token, expires_in}
Refresh: POST /auth/refresh with {refresh_token}
On failure: 401 Unauthorized with {"error": "unauthorized", "message": "..."}
```

---

### 3. Endpoints

#### GET /api/tasks

**Issues**
- No pagination. What happens when there are 10,000 tasks? Missing `limit`, `offset` or `cursor` params.
- No filtering or sorting parameters documented.
- Response only shows one field per task (`id`, `title`, `status`). Are there others? Is the list exhaustive?
- No HTTP status code documented (should be 200).
- `status` has no defined enum — what values are valid?

**Suggested additions**
```
Query params:
  status   — filter by status (pending|in_progress|done|cancelled)
  limit    — page size, default 20, max 100
  offset   — pagination offset, default 0

Response (200 OK):
{
  "tasks": [
    {
      "id": 1,
      "title": "Example task",
      "description": "...",
      "status": "pending",
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    }
  ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

#### POST /api/tasks

**Issues**
- No HTTP status code on success (should be 201 Created).
- No response body documented — does it return the created task?
- `title` is presumably required but that is not stated. `description` required or optional?
- No validation rules (max length, allowed characters).

**Suggested additions**
```
Request body:
  title        string  required  Max 255 chars
  description  string  optional  Max 5000 chars

Response (201 Created):
{
  "id": 42,
  "title": "New task",
  "description": "Task description",
  "status": "pending",
  "created_at": "2026-04-02T10:00:00Z",
  "updated_at": "2026-04-02T10:00:00Z"
}
```

#### PUT /api/tasks/:id

**Issues**
- Completely undocumented. No request body, no response body, no status codes, no notes on partial vs. full replacement.
- PUT implies full replacement — should this be PATCH for partial updates?
- No mention of what happens when `:id` does not exist (404?).

**Suggested additions**
```
PUT replaces all mutable fields. Use PATCH for partial updates (recommended).

Request body (all fields optional, at least one required):
  title        string  Max 255 chars
  description  string  Max 5000 chars
  status       string  pending|in_progress|done|cancelled

Response (200 OK): updated task object (same shape as GET)
On not found: 404 with {"error": "not_found", "message": "Task 999 not found"}
```

#### DELETE /api/tasks/:id

**Issues**
- No response body or status code documented (204 No Content is conventional).
- No mention of 404 behaviour.
- No mention of soft vs. hard delete.

**Suggested additions**
```
Response (204 No Content): empty body
On not found: 404 {"error": "not_found", "message": "Task 999 not found"}
Deletion is permanent (hard delete). Deleted tasks cannot be recovered.
```

---

### 4. Error Handling

**Issues**
- States that errors return `error` and `message` fields, but gives no example.
- No enumeration of expected HTTP status codes (400, 401, 403, 404, 422, 429, 500).
- No distinction between client errors and server errors.

**Suggested additions**
```
Error shape:
{
  "error": "validation_error",
  "message": "title is required",
  "details": [           // optional, for validation errors
    {"field": "title", "message": "is required"}
  ]
}

Status codes used by this API:
  200  OK
  201  Created
  204  No Content
  400  Bad Request — malformed JSON or missing required fields
  401  Unauthorized — missing or invalid token
  403  Forbidden — authenticated but lacks permission
  404  Not Found — resource does not exist
  422  Unprocessable Entity — valid JSON but business rule violation
  429  Too Many Requests — rate limit exceeded
  500  Internal Server Error
```

---

### 5. Rate Limiting

**Issues**
- States "100 requests per minute per user" but does not document the response headers consumers should read.
- No mention of what happens when the limit is exceeded (429? which body?).
- No mention of whether limits differ by endpoint or plan tier.

**Suggested additions**
```
When the limit is reached, the API returns:
  HTTP 429 Too Many Requests
  {"error": "rate_limit_exceeded", "message": "Retry after 23 seconds"}

Response headers on every request:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 73
  X-RateLimit-Reset: 1743591600   (Unix timestamp when the window resets)
```

---

## Structural suggestions

1. **Add a data model section.** Define the `Task` object in one place and reference it from each endpoint rather than repeating (or omitting) fields inline.

2. **Add an Examples section.** Provide a full request/response pair with curl or HTTPie for the most common flows (create task, list tasks, update status).

3. **Document content type.** State that the API accepts and returns `application/json` and that requests with a body must set `Content-Type: application/json`.

4. **Version the spec itself.** Add a `Last updated` date and a brief changelog so consumers know when things change.

5. **Consider OpenAPI.** A machine-readable OpenAPI (Swagger) file alongside the prose spec lets consumers generate SDKs and validate requests automatically.

---

## Priority summary

| Priority | Item |
|----------|------|
| Must | Document all request/response bodies and HTTP status codes |
| Must | Define `status` enum values |
| Must | Explain how to obtain a Bearer token |
| Must | Add pagination to GET /api/tasks |
| Should | Define the Task data model in one place |
| Should | Document rate limit headers and 429 response |
| Should | Clarify PUT vs. PATCH semantics |
| Should | Add content-type requirements |
| Nice | Full curl examples |
| Nice | OpenAPI spec file |
| Nice | Changelog / last-updated field |
