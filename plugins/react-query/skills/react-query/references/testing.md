# Testing

**Authoritative source:** [Testing](https://tanstack.com/query/v5/docs/framework/react/guides/testing). The docs recommend mocking at the network layer (MSW or similar) rather than mocking React Query itself.

## QueryClient Configuration for Tests

Per the docs:

- Disable retries (`retry: false`) — otherwise error-path tests time out while v5 runs three retries with exponential backoff.
- Set `gcTime: Infinity` in Jest to suppress premature-cleanup warnings.
- **Create a fresh `QueryClient` per test.** Sharing one instance leaks cache across tests and causes order-dependent failures.

```typescript
// src/test/utils.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render } from '@testing-library/react'

export function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: Infinity,
      },
    },
  })
}

export function renderWithClient(ui: React.ReactElement) {
  const testQueryClient = createTestQueryClient()
  return render(
    <QueryClientProvider client={testQueryClient}>
      {ui}
    </QueryClientProvider>
  )
}
```

## Mocking with MSW

The docs recommend MSW as the preferred approach over mocking `fetch` or the HTTP client directly. Mocking at the network layer means components exercise real serialization, real error paths, and the cache behaves exactly as it does in production.

```typescript
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/todos', () =>
    HttpResponse.json([{ id: 1, text: 'Test todo', completed: false }])
  ),

  http.post('/api/todos', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: 2, ...body })
  }),
]
```

```typescript
// src/test/setup.ts
import { setupServer } from 'msw/node'
import { handlers } from './mocks/handlers'

export const server = setupServer(...handlers)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

## Test Shapes

**Success path — use async matchers:**

```typescript
test('displays todos', async () => {
  renderWithClient(<TaskList />)
  expect(await screen.findByText('Test todo')).toBeInTheDocument()
})
```

**Error path — override the handler per test:**

```typescript
test('shows error state', async () => {
  server.use(
    http.get('/api/todos', () =>
      HttpResponse.json({ message: 'Failed to fetch' }, { status: 500 })
    )
  )

  renderWithClient(<TaskList />)
  expect(await screen.findByText(/failed/i)).toBeInTheDocument()
})
```

**Pre-seed cache when the test cares about rendered state, not fetch behavior:**

```typescript
const client = createTestQueryClient()
client.setQueryData(['todos', 1], { id: 1, text: 'Seeded', completed: false })
render(
  <QueryClientProvider client={client}>
    <TodoDetail id={1} />
  </QueryClientProvider>
)
```

## Testing Principles

- Use `findBy*` for anything driven by an async query — `getBy*` fires before the fetch resolves.
- Silence expected `console.error` calls in error-path tests so CI output stays clean.
- Verify both the happy path and at least one error path per query.
- For mutations, assert both the optimistic UI change and the settled UI once the server response is applied.
