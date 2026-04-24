# QueryClient Setup & Feature Colocation

**Authoritative sources:**
- [Important Defaults](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults)
- [QueryClient reference](https://tanstack.com/query/v5/docs/framework/react/reference/QueryClient)
- [QueryCache reference](https://tanstack.com/query/v5/docs/reference/QueryCache)

## v5 Default Behavior

Per the docs:

- `staleTime: 0` — every query is instantly stale; mount/focus/reconnect trigger a background refetch.
- `gcTime: 5 * 60_000` (5 min) — inactive queries are garbage collected after this.
- `retry: 3` on the client with exponential backoff. `retry: 0` on the server.
- `refetchOnWindowFocus: true`, `refetchOnReconnect: true`.

Tune `staleTime` before anything else; it is the primary control for how often data refetches. Keep `gcTime >= staleTime` — if data is garbage collected while still considered fresh, the stale-while-revalidate guarantee breaks.

## Canonical Client Setup

```typescript
// src/app/providers.tsx
import { QueryClient, QueryClientProvider, QueryCache } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { toast } from './toast'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60_000,            // 1 minute — tune per app
      gcTime: 5 * 60_000,           // 5 min (default)
      retry: (failureCount, error) => {
        if (error?.response?.status === 401) return false
        return failureCount < 3
      },
    },
  },
  queryCache: new QueryCache({
    // Global error handling — source of truth for background errors.
    // See: https://tkdodo.eu/blog/react-query-error-handling
    onError: (error, query) => {
      if (query.state.data !== undefined) {
        toast.error(`Something went wrong: ${error.message}`)
      }
    },
  }),
})

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

Key rules:

- Instantiate `QueryClient` **at module scope**, never inside a component — new instance per render drops the cache.
- `ReactQueryDevtools` is tree-shaken in production builds; keep it in the root.
- Only show background-error toasts when cached `data` exists, so first-load errors don't double-report with the component's own error UI.

## Feature-Based Colocation

Group queries with the feature they power. Export only custom hooks; keep keys and `queryFn`s private.

```
src/features/Todos/
├── index.tsx
├── queries.ts      // Key factories, queryFns, hooks
├── types.ts
└── components/
```

```typescript
// features/todos/queries.ts
import { queryOptions, useQuery } from '@tanstack/react-query'
import axios from 'axios'
import type { Todo } from './types'

// Private key factory — hierarchical from generic → specific
const todoKeys = {
  all: ['todos'] as const,
  lists: () => [...todoKeys.all, 'list'] as const,
  list: (filters: string) => [...todoKeys.lists(), { filters }] as const,
  details: () => [...todoKeys.all, 'detail'] as const,
  detail: (id: number) => [...todoKeys.details(), id] as const,
}

// Private queryFn
const fetchTodos = (filters: string): Promise<Todo[]> =>
  axios.get('/api/todos', { params: { filters } }).then(r => r.data)

// Public hook
export const useTodosQuery = (filters: string) =>
  useQuery({
    queryKey: todoKeys.list(filters),
    queryFn: () => fetchTodos(filters),
    staleTime: 30_000,
  })
```

## Query Options Factories (Preferred)

For shared query configuration across hooks and imperative access, use `queryOptions`. Source: [query-options](https://tanstack.com/query/v5/docs/framework/react/guides/query-options).

```typescript
import { queryOptions } from '@tanstack/react-query'

export const todoQueries = {
  all: () => ['todos'] as const,

  detail: (id: number) =>
    queryOptions({
      queryKey: [...todoQueries.all(), 'detail', id] as const,
      queryFn: () => fetchTodoById(id),
      staleTime: 5_000,
    }),
}

// Reuse everywhere with full type inference:
useQuery(todoQueries.detail(1))
queryClient.prefetchQuery(todoQueries.detail(5))
queryClient.setQueryData(todoQueries.detail(42).queryKey, newTodo)
queryClient.getQueryData(todoQueries.detail(42).queryKey) // fully typed
```

Also supported: `useSuspenseQuery`, `useQueries`.

## Query Key Rules

From [query-keys](https://tanstack.com/query/v5/docs/framework/react/guides/query-keys):

- Keys are hashed deterministically — object key order does **not** matter.
- Array item order **does** matter (`['todos', status, page]` ≠ `['todos', page, status]`).
- Include **every variable used in `queryFn`** — treat the key like a React dependency array. Missing variables cause silent cache collisions.
- Be consistent with types: `['todos', '1']` and `['todos', 1]` are different keys.
- Use `as const` on key arrays for literal type inference.
