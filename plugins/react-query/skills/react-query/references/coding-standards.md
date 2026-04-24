# Coding Standards for New v5 Code

Every rule below cites the v5 doc section that backs it. Where a rule is a community best practice (not explicit in the docs), the **Source** line says so.

## Client Setup

- **Set a non-zero global `staleTime`.** 60 seconds is a sensible default for most apps. The v5 default of `0` means every query refetches on mount, window focus, and reconnect — usually not what you want.
  Source: [important-defaults](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults).
- **Keep `gcTime >= staleTime`.** Otherwise data is garbage-collected while still considered fresh and the stale-while-revalidate guarantee breaks.
  Source: [caching](https://tanstack.com/query/v5/docs/framework/react/guides/caching).
- **Instantiate `QueryClient` at module scope**, never inside a component — a new instance per render drops the cache every render.
- **Handle background errors with `QueryCache.onError`**, not per-component `useEffect` toasts. Per-component toasts multiply with the number of mounts using the same key.
  Source: [QueryCache reference](https://tanstack.com/query/v5/docs/reference/QueryCache).
- **Include `<ReactQueryDevtools>` in the provider tree.** It's tree-shaken in production.

Canonical example: see `setup.md`.

## Query Keys — Use `queryOptions` Factories

Scattered inline keys rot silently — a typo in one file quietly creates a second cache entry and both components think they have fresh data. Centralize every key and `queryFn` in a `queryOptions` factory.

```typescript
import { queryOptions } from '@tanstack/react-query'

export const todoQueries = {
  all: () => ['todos'] as const,

  lists: () =>
    queryOptions({
      queryKey: [...todoQueries.all(), 'list'] as const,
      queryFn: fetchAllTodos,
    }),

  list: (filters: TodoFilters) =>
    queryOptions({
      queryKey: [...todoQueries.all(), 'list', { filters }] as const,
      queryFn: () => fetchTodos(filters),
    }),

  detail: (id: number) =>
    queryOptions({
      queryKey: [...todoQueries.all(), 'detail', id] as const,
      queryFn: () => fetchTodoById(id),
    }),
}
```

Rules:

- Structure keys from **most generic → most specific** so partial invalidation works (`queryClient.invalidateQueries({ queryKey: todoQueries.all() })` hits everything).
- Use `as const` for literal type inference.
- Include **every** variable used in `queryFn` in the key. Treat the key as a React dependency array.
  Source: [query-keys](https://tanstack.com/query/v5/docs/framework/react/guides/query-keys).

## File Organization

```
src/features/{feature}/
  queries.ts        // queryOptions factories + queryFns
  mutations.ts      // useMutation hooks
  components/
```

Export only custom hooks from these modules. Keep `queryFn`s and keys private — callers should not know how data is fetched.

## Data Fetching

- **Always check `response.ok`** when using the `fetch` API. Fetch doesn't reject on 4xx/5xx — React Query will happily cache an error body as success data.
  Source: [query-functions](https://tanstack.com/query/v5/docs/framework/react/guides/query-functions).
- **Prefer `skipToken` over `enabled: false`** for conditional queries — `skipToken` preserves the return type. Use `enabled: false` only when you actually want `refetch()` to work manually.
  Source: [disabling-queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries).
- **Use `select` for data transformation**, not a component-level mapping. `select` enables partial subscriptions — the component only re-renders when the selected slice changes.
  Source: [render-optimizations](https://tanstack.com/query/v5/docs/framework/react/guides/render-optimizations).
- **Keep `select` functions stable** (module-level or `useCallback`) or they run on every render.
- **Use `placeholderData: keepPreviousData`** to avoid UI flicker during key changes (pagination, filtering).
  Source: [paginated-queries](https://tanstack.com/query/v5/docs/framework/react/guides/paginated-queries).
- **Never copy query data into `useState`.** Derive everything from `data`. Source state belongs in the cache; derived UI state belongs in render.

## Mutations

- **Split callbacks by concern:**
  - Definition callbacks (`useMutation({ onSuccess })`) — shared logic: cache updates, invalidation, analytics.
  - Call-site callbacks (`mutate(v, { onSuccess })`) — UI logic: navigation, toasts, form resets.
- **Return the invalidation promise from `onSuccess`.** Without `return`, the mutation transitions to success before fresh data arrives, causing a stale flash.
  Source: [invalidations-from-mutations](https://tanstack.com/query/v5/docs/framework/react/guides/invalidations-from-mutations).
- **Invalidate in `onSettled` for optimistic updates**, not `onSuccess`. Ensures the cache reconciles after errors too.
  Source: [optimistic-updates](https://tanstack.com/query/v5/docs/framework/react/guides/optimistic-updates).
- **Never mutate cached data in place.** `setQueryData` updaters must return new references.
- **Reserve optimistic UI for high-confidence, instant-feedback interactions** (toggles, likes, inline edits). Avoid it for form submissions that navigate away — rollback UX is confusing when the user is already on another screen.

Full patterns: see `mutations.md`.

## Suspense & React 19

- **Use `useSuspenseQuery`**, not `suspense: true`. `data` is guaranteed defined.
  Source: [suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense).
- **Always pair `<Suspense>` with an `<ErrorBoundary>`.** Use `QueryErrorResetBoundary` + `react-error-boundary`.
- **Never use multiple `useSuspenseQuery` calls under the same Suspense boundary.** React 19 stops rendering at the first suspension — the queries run serially, not in parallel. Use `useSuspenseQueries` for parallel fetches.
- **Prefetch in route loaders** to avoid waterfalls. `ensureQueryData` for blocking critical data; `prefetchQuery` for background prefetches.
  Source: [prefetching](https://tanstack.com/query/v5/docs/framework/react/guides/prefetching).
- **Use `startTransition` on key changes** (e.g., pagination) to keep the previous UI visible instead of unmounting into the fallback.

## Infinite Queries

- **`initialPageParam` is required in v5.** No default is provided.
- **Return `undefined` from `getNextPageParam`** to signal "no more pages".
- **Use `maxPages`** to cap memory for long infinite feeds.
  Source: [infinite-queries](https://tanstack.com/query/v5/docs/framework/react/guides/infinite-queries).

## TypeScript

- **Type the `queryFn` return** — let inference flow to `useQuery`. Manual generics (`useQuery<Todo[]>(...)`) defeat `select` inference.
  Source: [typescript](https://tanstack.com/query/v5/docs/framework/react/typescript).
- **Register a global error type** via module augmentation so `error` is correctly typed everywhere:
  ```typescript
  declare module '@tanstack/react-query' {
    interface Register {
      defaultError: ApiError
    }
  }
  ```
- **`as const`** on query key arrays for literal type inference.

## Testing

- **Fresh `QueryClient` per test** — `retry: false`, `gcTime: Infinity`.
  Source: [testing](https://tanstack.com/query/v5/docs/framework/react/guides/testing).
- **MSW over `fetch` mocking** — exercises real serialization and real error paths.
- **Pre-seed the cache with `setQueryData`** for tests about rendering, not fetching.
- **Never share a `QueryClient`** between tests. State leakage causes order-dependent failures.

Full patterns: see `testing.md`.
