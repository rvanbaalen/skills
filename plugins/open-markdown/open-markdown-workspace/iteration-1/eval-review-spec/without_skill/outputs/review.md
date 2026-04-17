# API Specification Review — docs/api-spec.md

## Summary

The spec covers the basics of a task management REST API but is significantly under-specified for a production API. Below are findings organized by severity, followed by concrete suggestions for each section.

---

## Critical Issues

### 1. No Response Bodies for POST, PUT, DELETE

`POST /api/tasks`, `PUT /api/tasks/:id`, and `DELETE /api/tasks/:id` have no documented response bodies. Consumers cannot know:

- What the created/updated resource looks like
- What HTTP status code to expect (201 vs 200 vs 204)
- Whether a delete returns the deleted object or just a 204 No Content

**Suggestion:** Add a `**Response:**` block for every endpoint. Example for POST:

```json
HTTP 201 Created
{
  "task": {
    "id": 42,
    "title": "New task",
    "description": "Task description",
    "status": "pending",
    "created_at": "2026-04-02T10:00:00Z",
    "updated_at": "2026-04-02T10:00:00Z"
  }
}
```

### 2. PUT /api/tasks/:id Has No Request Body

The update endpoint documents no request body schema. Consumers cannot know which fields are updatable, whether partial updates (PATCH semantics) are supported, or whether all fields are required.

**Suggestion:** Document the request body and note whether it is a full replacement (PUT) or partial update (PATCH). If partial updates are intended, rename the method to `PATCH`.

### 3. No HTTP Status Codes Documented

No endpoint specifies which HTTP status codes it returns. This is essential for error handling on the client side.

**Suggestion:** Add a status code table or inline annotations per endpoint. Example:

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 201 | Resource created |
| 204 | Deleted, no content |
| 400 | Validation error |
| 401 | Missing/invalid token |
| 403 | Forbidden |
| 404 | Resource not found |
| 429 | Rate limit exceeded |

---

## Significant Gaps

### 4. Authentication Section Is Too Sparse

The spec says "Bearer token in the Authorization header" but does not explain:

- How to obtain a token (OAuth flow? API key? Login endpoint?)
- Token expiry and refresh strategy
- What happens when a token is invalid (expected error shape)

**Suggestion:** Add a subsection covering token issuance, expiry, and a concrete header example:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 5. Task Object Schema Is Incomplete

The GET response shows `id`, `title`, and `status` but the POST request body includes `description`. The full data model is never formally defined. Consumers cannot know all available fields, their types, or which are required vs optional.

**Suggestion:** Add a `## Data Models` section with a complete schema table:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | — | Auto-assigned unique identifier |
| title | string | yes | Short task title (max 255 chars) |
| description | string | no | Long-form task description |
| status | enum | — | One of: `pending`, `in_progress`, `done` |
| created_at | ISO 8601 | — | Server-assigned creation timestamp |
| updated_at | ISO 8601 | — | Server-assigned last-update timestamp |

### 6. Error Response Schema Is Vague

The spec says errors return `error` and `message` fields but gives no example, no list of error codes, and no explanation of what distinguishes `error` from `message`.

**Suggestion:** Add a concrete example and an error code registry:

```json
{
  "error": "validation_error",
  "message": "Title is required and must not exceed 255 characters."
}
```

### 7. Rate Limiting — No Behaviour on Breach

The spec states 100 req/min but does not document:

- Which HTTP status is returned when the limit is exceeded (standard: 429)
- Whether `Retry-After` or `X-RateLimit-*` headers are included
- Whether limits are per IP, per token, or per user account

**Suggestion:**

> When the rate limit is exceeded, the API returns HTTP `429 Too Many Requests` with a `Retry-After` header (seconds until the window resets) and the standard error body. Response headers on every request include `X-RateLimit-Limit: 100`, `X-RateLimit-Remaining: N`, and `X-RateLimit-Reset: <unix timestamp>`.

---

## Minor Issues

### 8. No Filtering, Sorting, or Pagination on GET /api/tasks

Real-world task lists can be large. Without pagination, the endpoint is unusable at scale.

**Suggestion:** Document query parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number (1-indexed) |
| per_page | integer | 20 | Items per page (max 100) |
| status | string | — | Filter by status value |
| sort | string | created_at | Field to sort by |
| order | string | desc | `asc` or `desc` |

And document a paginated response envelope:

```json
{
  "tasks": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 84,
    "total_pages": 5
  }
}
```

### 9. No Versioning Strategy

The document is titled "v1.0" but the API base path is `/api/` with no version segment. Future breaking changes will require a versioning strategy.

**Suggestion:** Use a versioned base path (`/api/v1/`) and document the deprecation/sunset policy.

### 10. No Content-Type Requirements

No mention of required `Content-Type: application/json` for POST/PUT request bodies, or that responses are always `application/json`.

**Suggestion:** Add a `## Request Format` section noting that all bodies must be valid JSON and must include `Content-Type: application/json`.

### 11. Spec Version and Changelog Missing

There is no `Last Updated` date, no changelog, and no contact/support information.

**Suggestion:** Add a header block:

```
Version: 1.0
Last Updated: 2026-04-02
Maintainer: <team or contact>
```

---

## Revised Structure Suggestion

```
# API Specification v1.0
## Overview
## Base URL
## Versioning
## Authentication
## Request Format
## Data Models
  ### Task
## Endpoints
  ### GET /api/v1/tasks
  ### POST /api/v1/tasks
  ### GET /api/v1/tasks/:id
  ### PUT /api/v1/tasks/:id  (or PATCH)
  ### DELETE /api/v1/tasks/:id
## Error Handling
  ### Error Codes
## Rate Limiting
## Changelog
```

Note that `GET /api/tasks/:id` (fetch single task) is missing entirely from the current spec and should be added.
