# Query Patterns

**Authoritative sources:**
- [Queries](https://tanstack.com/query/v5/docs/framework/react/guides/queries)
- [Query Functions](https://tanstack.com/query/v5/docs/framework/react/guides/query-functions)
- [Disabling / Lazy queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries) (covers `skipToken`)
- [Dependent Queries](https://tanstack.com/query/v5/docs/framework/react/guides/dependent-queries)
- [Paginated / Lagged queries](https://tanstack.com/query/v5/docs/framework/react/guides/paginated-queries)
- [Infinite Queries](https://tanstack.com/query/v5/docs/framework/react/guides/infinite-queries)
- [Prefetching & Router Integration](https://tanstack.com/query/v5/docs/framework/react/guides/prefetching)
- [Suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense)
- [Render Optimizations](https://tanstack.com/query/v5/docs/framework/react/guides/render-optimizations) (covers `select`)

## Data Transformation with `select`

`select` transforms cached data for a specific subscriber without altering the cache, and enables per-component re-render optimization.

```typescript
// Only re-renders when the count changes
export const useTodosCount = () =>
  useQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
    select: (data) => data.length,
  })
```

Memoize expensive `select` functions so they are stable across renders:

```typescript
// Stable reference
const transformTodos = (data: Todo[]) => expensiveTransform(data)

useQuery({ queryKey: ['todos'], queryFn: fetchTodos, select: transformTodos })

// Unstable — runs on every render
useQuery({ queryKey: ['todos'], queryFn: fetchTodos, select: (d) => expensiveTransform(d) })
```

## Conditional Fetching — Prefer `skipToken`

Per [disabling-queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries), v5 introduced `skipToken` for type-safe conditional disabling. Use `enabled: false` only when intentionally relying on manual `refetch()`.

```typescript
import { skipToken, useQuery } from '@tanstack/react-query'

const { data } = useQuery({
  queryKey: ['user', userId],
  // queryFn only runs when userId is truthy; data is typed correctly as possibly undefined
  queryFn: userId ? () => fetchUser(userId) : skipToken,
})
```

## Dependent Queries

```typescript
const { data: user } = useQuery({
  queryKey: ['user', email],
  queryFn: () => getUserByEmail(email),
})

const { data: projects } = useQuery({
  queryKey: ['projects', user?.id],
  queryFn: () => getProjectsByUser(user.id),
  enabled: !!user?.id,
})
```

Dependent queries create a request waterfall. The docs note: *"Doing them serially instead of in parallel always takes twice as much time."* Restructure the backend API to return combined data when possible, or prefetch in a route loader.

## Paginated Queries

Show the previous page's data while the next page loads:

```typescript
import { keepPreviousData } from '@tanstack/react-query'

const { data, isPlaceholderData } = useQuery({
  queryKey: ['posts', page],
  queryFn: () => fetchPosts(page),
  placeholderData: keepPreviousData,
})
```

## Infinite Queries

`initialPageParam` is required in v5. `getNextPageParam` returns `undefined` when there are no more pages.

```typescript
const {
  data,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
} = useInfiniteQuery({
  queryKey: ['projects'],
  queryFn: ({ pageParam }) => fetchProjects(pageParam),
  initialPageParam: 0,
  getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  maxPages: 10, // optional memory cap
})

return (
  <>
    {data?.pages.map((page, i) => (
      <React.Fragment key={i}>
        {page.data.map(p => <ProjectCard key={p.id} {...p} />)}
      </React.Fragment>
    ))}
    <button onClick={() => fetchNextPage()} disabled={!hasNextPage || isFetchingNextPage}>
      {isFetchingNextPage ? 'Loading…' : 'Load more'}
    </button>
  </>
)
```

## Prefetching

Eliminate loading states by priming the cache before the user asks.

```typescript
function ShowDetailsButton() {
  const queryClient = useQueryClient()
  const prefetch = () => {
    queryClient.prefetchQuery({
      queryKey: ['details'],
      queryFn: getDetailsData,
      staleTime: 60_000,
    })
  }
  return <button onMouseEnter={prefetch} onClick={open}>Show</button>
}
```

In router loaders, prefer `ensureQueryData` for blocking critical data, `prefetchQuery` for non-blocking. Source: [prefetching](https://tanstack.com/query/v5/docs/framework/react/guides/prefetching).

## Preventing Waterfalls

```typescript
// Waterfall
const { data: user } = useQuery(userQuery)
const { data: posts } = useQuery(postsQuery(user?.id)) // waits for user

// Parallel with gating
const { data: user } = useQuery(userQuery)
const { data: posts } = useQuery({ ...postsQuery(user?.id), enabled: !!user?.id })
const { data: stats } = useQuery({ ...statsQuery(user?.id), enabled: !!user?.id })

// Best — prefetch in a route loader before the page mounts
```

## Suspense

Per [suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense), dedicated hooks guarantee `data` is defined:

```typescript
import { useSuspenseQuery } from '@tanstack/react-query'

function TaskList() {
  const { data } = useSuspenseQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  })
  return <ul>{data.map(t => <TodoItem key={t.id} {...t} />)}</ul>
}

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <TaskList />
    </Suspense>
  )
}
```

Rules:

- Pair every Suspense boundary with an error boundary. Use `QueryErrorResetBoundary` + `react-error-boundary`.
- Multiple `useSuspenseQuery` calls in one component create a waterfall — use `useSuspenseQueries` for parallel fetches.
- Use `startTransition` on key changes (e.g., pagination) to keep the previous UI visible instead of unmounting into the fallback.

## Error Boundary Pattern

```typescript
import { QueryErrorResetBoundary } from '@tanstack/react-query'
import { ErrorBoundary } from 'react-error-boundary'

<QueryErrorResetBoundary>
  {({ reset }) => (
    <ErrorBoundary
      onReset={reset}
      fallbackRender={({ error, resetErrorBoundary }) => (
        <div>
          <p>{error.message}</p>
          <button onClick={resetErrorBoundary}>Try again</button>
        </div>
      )}
    >
      <TaskList />
    </ErrorBoundary>
  )}
</QueryErrorResetBoundary>
```

## Status Flags Cheat Sheet

Source: [queries](https://tanstack.com/query/v5/docs/framework/react/guides/queries).

| Flag | Meaning |
|---|---|
| `isPending` | Query has no cached data yet |
| `isFetching` | A fetch is in flight (background or foreground) |
| `isLoading` | `isPending && isFetching` — first load in progress |
| `isSuccess` | Query resolved successfully; `data` is defined |
| `isError` | Query rejected; `error` is defined |
| `isPlaceholderData` | Currently rendering placeholder / kept-previous data |

## Cache Timing Quick Reference

| `staleTime` | Fits |
|---|---|
| `0` (default) | Always stale — refetch on mount/focus/reconnect |
| `30_000` | User-generated content that changes often |
| `120_000` | Profile / preferences |
| `600_000` | Static reference data |

| `gcTime` | Fits |
|---|---|
| `300_000` (default, 5 min) | Most cases |
| `Infinity` | Persistence-backed caches |
| `0` | Effectively disables caching — avoid |

Invariant: `gcTime >= staleTime`.

## TypeScript Tips

Per [typescript](https://tanstack.com/query/v5/docs/framework/react/typescript):

- Type the `queryFn` return; let inference flow through `useQuery`. Avoid manual generics like `useQuery<Todo[]>`.
- Register a global error type via module augmentation:
  ```typescript
  declare module '@tanstack/react-query' {
    interface Register {
      defaultError: ApiError
    }
  }
  ```
- Use discriminated unions — `isSuccess` narrows `data` to non-undefined; `isError` narrows `error` to defined.
