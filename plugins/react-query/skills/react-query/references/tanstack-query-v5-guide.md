# TanStack Query v5 with React 19: the definitive guide

**TanStack Query v5 fundamentally reshapes how React applications manage server state**, replacing scattered `useEffect`/`useState` patterns with a declarative cache that handles fetching, caching, synchronization, and garbage collection automatically. This guide distills the latest patterns from the official documentation, TkDodo's 32-part blog series, and v5's breaking changes into a single, actionable reference for modern React 19 applications. The core v5 philosophy is clear: `queryOptions` factories replace custom hooks as the primary abstraction, `useSuspenseQuery` replaces the old `suspense: true` flag, and callbacks like `onSuccess` are gone from queries entirely.

---

## Setting up QueryClient with production-ready defaults

The `QueryClient` is the backbone of every TanStack Query application. Its default configuration determines how aggressively data refetches, how long it lives in cache, and how errors propagate. The most impactful decision you'll make is **setting `staleTime` above zero** — the default of `0` means every piece of data is instantly stale, triggering background refetches on every component mount, window focus, and network reconnect.

```typescript
import { QueryClient, QueryClientProvider, QueryCache } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,        // 1 minute — data stays fresh, no refetch
      gcTime: 1000 * 60 * 5,       // 5 min (default) — inactive data garbage collected
      retry: 3,                     // Retry failed queries 3 times
      retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000),
      refetchOnWindowFocus: true,   // Refetch stale data on tab focus
      refetchOnMount: true,         // Refetch stale data on new observer mount
      refetchOnReconnect: true,     // Refetch stale data on network reconnect
    },
  },
  queryCache: new QueryCache({
    onError: (error, query) => {
      // Global error handler — fires ONCE per failed query, not per component
      const message = (query.meta?.errorMessage as string) ?? error.message
      toast.error(`Something went wrong: ${message}`)
    },
  }),
})

// Create outside the component tree for stable reference
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

The critical distinction is between **`staleTime`** and **`gcTime`**. `staleTime` controls freshness — while data is fresh, no background refetches occur regardless of mount, focus, or reconnect events. `gcTime` controls memory — after a query has zero active observers, its cached data survives for `gcTime` before garbage collection. **`gcTime` should always be >= `staleTime`** to preserve the stale-while-revalidate pattern. For rapidly changing data like live scores, keep `staleTime: 0` with polling. For configuration data or reference tables, set `staleTime: Infinity` and invalidate manually.

| Scenario | staleTime | gcTime | Notes |
|----------|-----------|--------|-------|
| Live data (stock prices, chat) | `0` | `60s` | Poll with `refetchInterval` |
| Standard CRUD (todo lists) | `60s` | `5min` | Good general default |
| User profiles | `5min` | `30min` | Changes infrequently |
| Static config / reference data | `Infinity` | `Infinity` | Invalidate manually or via WebSocket |

DevTools in v5 ship as a separate package (`@tanstack/react-query-devtools`), automatically tree-shake out of production builds, and now support **mutation observation** — a significant addition for debugging optimistic update flows.

---

## Query key factories and the queryOptions revolution

Query keys are TanStack Query's addressing system. The v5 best practice, championed by TkDodo in blog posts #24 and #31, is to **replace raw query key arrays with `queryOptions` factories** — a pattern that co-locates key, fetch function, and options into a single type-safe unit reusable across `useQuery`, `useSuspenseQuery`, `prefetchQuery`, `setQueryData`, and more.

Structure keys from **most generic to most specific** to enable fuzzy matching for invalidation:

```typescript
import { queryOptions } from '@tanstack/react-query'

export const todoQueries = {
  all: () => ['todos'] as const,

  lists: () =>
    queryOptions({
      queryKey: [...todoQueries.all(), 'list'] as const,
      queryFn: fetchAllTodos,
      staleTime: 5 * 60 * 1000,
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
      staleTime: 5 * 60 * 1000,
    }),
}
```

This pattern is powerful for three reasons. First, `queryOptions` is a **TypeScript powerhouse** — it catches typos like `stallTime` instead of `staleTime` through excess property checking, and tags query keys with `DataTag` so that `queryClient.getQueryData(todoQueries.detail(1).queryKey)` returns `Todo | undefined` instead of `unknown`. Second, it works **everywhere** — hooks, route loaders, mutation callbacks, imperative cache access — whereas custom hooks wrapping `useQuery` can only be called inside React components. Third, fuzzy matching invalidation becomes trivial:

```typescript
queryClient.invalidateQueries({ queryKey: todoQueries.all() })  // Everything
queryClient.invalidateQueries({ queryKey: ['todos', 'list'] })  // All lists
```

TkDodo's blog post #31 (January 2026) explicitly recommends `queryOptions` **over** custom hooks as the primary abstraction. Custom hooks that accept partial `UseQueryOptions` break type inference — `data` becomes `unknown`. Instead, colocate `queryOptions` factories with their feature and spread additional options at the call site when needed.

```
src/features/todos/
  queries.ts       // queryOptions factories + fetch functions
  mutations.ts     // useMutation custom hooks (hooks ARE appropriate for mutations)
  components/
    TodoList.tsx
```

---

## useQuery patterns that actually scale

### Conditional fetching with skipToken

v5 introduced **`skipToken`** for type-safe query disabling. Unlike `enabled: false` where the `queryFn` still receives potentially undefined parameters, `skipToken` narrows types inside the conditional branch:

```typescript
import { skipToken, useQuery } from '@tanstack/react-query'

function UserProjects({ userId }: { userId: number | undefined }) {
  const { data } = useQuery({
    queryKey: ['projects', userId],
    queryFn: userId ? () => fetchProjects(userId) : skipToken,
    // userId is narrowed to `number` inside the truthy branch
  })
}
```

One caveat: `refetch()` throws with `skipToken` because there's no query function to call. Use `enabled: false` if you need manual `refetch()` capability.

### select for transformations and render optimization

The `select` option is the **recommended approach for all data transformations**. It runs only when data exists, its result benefits from structural sharing, and it enables partial subscriptions where components re-render only when their selected slice changes:

```typescript
// Base hook accepting optional selector
function useTodos<TData = Todo[]>(select?: (data: Todo[]) => TData) {
  return useQuery({ ...todoQueries.lists(), select })
}

// Component subscribes only to count — re-renders only when count changes
const useTodoCount = () => useTodos((data) => data.length)

// Stable function reference prevents unnecessary re-computation
const selectNames = (data: Todo[]) => data.map((t) => t.title.toUpperCase())
const useTodoNames = () => useTodos(selectNames)
```

For selectors that close over props, wrap with `useCallback` to maintain referential stability. For expensive transforms shared across multiple component instances, TkDodo recommends external memoization libraries like `fast-memoize`.

### placeholderData vs initialData

These serve fundamentally different purposes. **`initialData` persists to the cache** and respects `staleTime` — if fresh, no refetch occurs. **`placeholderData` is observer-level only** — it's never written to cache and always triggers a background refetch. Use `initialData` when pre-filling from another cache entry (with `initialDataUpdatedAt`). Use `placeholderData` for everything else, including the v5 replacement for `keepPreviousData`:

```typescript
// Keep previous page data during pagination (replaces v4's keepPreviousData)
const { data, isPlaceholderData } = useQuery({
  queryKey: ['todos', page],
  queryFn: () => fetchTodos(page),
  placeholderData: (previousData) => previousData,
})
```

A subtle trap: `initialData: []` combined with `staleTime > 0` creates a "phantom" cache entry treated as fresh real data, preventing the actual fetch entirely.

---

## Mutations, optimistic updates, and cache invalidation

### The callback separation principle

TkDodo's critical insight from blog post #12: place **shared business logic** (invalidation, cache updates) in `useMutation` definition callbacks, and **UI-specific logic** (navigation, toasts, form resets) in `mutate()` call-site callbacks. The `useMutation` callbacks fire first, then `mutate()` callbacks:

```typescript
// mutations.ts — shared logic
export function useUpdateTodo() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: updateTodo,
    onSuccess: () => {
      // Always invalidate — this is business logic
      return queryClient.invalidateQueries({ queryKey: todoQueries.all() })
    },
  })
}

// Component — UI logic
function TodoForm() {
  const updateTodo = useUpdateTodo()
  const handleSubmit = (values: TodoInput) => {
    updateTodo.mutate(values, {
      onSuccess: () => navigate('/todos'),  // UI concern
    })
  }
}
```

Returning the `invalidateQueries` promise from `onSuccess` keeps the mutation in `pending` state until the refetch completes — essential for preventing stale UI after form resets.

### Two approaches to optimistic updates

**Via UI (simpler, recommended for most cases):** Render the optimistic value directly from mutation state without touching the cache. v5's `useMutationState` hook enables cross-component optimistic rendering:

```typescript
const { mutate, variables, isPending } = useMutation({
  mutationFn: addTodo,
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

// In JSX — optimistic item rendered from mutation state
{isPending && <li style={{ opacity: 0.5 }}>{variables}</li>}
```

**Via cache (full control, more complex):** Manipulate the cache directly in `onMutate`, snapshot for rollback, and always invalidate in `onSettled`:

```typescript
useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] })
    const previous = queryClient.getQueryData<Todo[]>(['todos'])
    queryClient.setQueryData<Todo[]>(['todos'], (old) =>
      old ? old.map((t) => (t.id === newTodo.id ? { ...t, ...newTodo } : t)) : []
    )
    return { previous }
  },
  onError: (_err, _newTodo, context) => {
    queryClient.setQueryData(['todos'], context?.previous)
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})
```

TkDodo's caution: **don't overuse optimistic updates**. Reserve them for interactions where instant feedback genuinely matters (toggles, likes) and failure is rare. Form submissions that close dialogs or redirect are poor candidates because rollback UX is confusing.

---

## Suspense in React 19 demands a new mental model

v5 replaced the `suspense: true` option with dedicated hooks: **`useSuspenseQuery`**, **`useSuspenseInfiniteQuery`**, and **`useSuspenseQueries`**. The key TypeScript benefit is that `data` is **guaranteed defined** — loading states are handled by `<Suspense>`, errors by `<ErrorBoundary>`.

The canonical setup pairs `QueryErrorResetBoundary` with `react-error-boundary`:

```typescript
import { Suspense } from 'react'
import { QueryErrorResetBoundary, useSuspenseQuery } from '@tanstack/react-query'
import { ErrorBoundary } from 'react-error-boundary'

function App() {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          onReset={reset}
          fallbackRender={({ resetErrorBoundary, error }) => (
            <div>
              <p>Error: {error.message}</p>
              <button onClick={resetErrorBoundary}>Retry</button>
            </div>
          )}
        >
          <Suspense fallback={<Spinner />}>
            <TodoList />
          </Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  )
}
```

**React 19 introduced a critical behavioral change** that TkDodo documented in "React 19 and Suspense — A Drama in 3 Acts." In React 18, when one sibling suspended, React continued rendering other siblings to discover additional promises (enabling parallel fetching). **In React 19, React stops rendering siblings after the first suspension**, creating waterfalls where sibling `useSuspenseQuery` calls execute serially. The fix is twofold: use `useSuspenseQueries` for parallel fetches within the same component, and **prefetch in route loaders** to adopt the "render-as-you-fetch" pattern:

```typescript
// Route loader — both prefetches fire in parallel before component mounts
loader: ({ context: { queryClient } }) => {
  queryClient.prefetchQuery(articleQueryOptions(id))   // Fire and forget
  queryClient.prefetchQuery(commentsQueryOptions(id))  // Fire and forget
}
```

For transitions when query keys change (pagination, filtering), wrap state updates in `startTransition` to keep the old UI visible instead of showing the Suspense fallback:

```typescript
const [isPending, startTransition] = useTransition()
// ...
startTransition(() => setPage((p) => p + 1))
```

---

## Infinite queries and pagination done right

v5 requires **`initialPageParam` as a mandatory option** (no more defaulting in the `queryFn` signature). Return `undefined` or `null` from `getNextPageParam` to signal there are no more pages:

```typescript
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
  queryKey: ['projects'],
  queryFn: ({ pageParam }) => fetchProjects(pageParam),
  initialPageParam: 0,
  getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  maxPages: 5,  // Limit stored pages for memory management
})
```

For **infinite scroll**, combine with `IntersectionObserver` (via `react-intersection-observer`) to trigger `fetchNextPage()` when a sentinel element enters the viewport. For **traditional pagination**, use regular `useQuery` with `placeholderData: keepPreviousData` and prefetch the next page in a `useEffect`. The key tradeoff: infinite queries refetch *all* stored pages on background refetch, while paginated queries refetch only the current page.

---

## Prefetching strategies from hover to router

Three methods serve different purposes: **`prefetchQuery`** fires and forgets (never throws, returns `void`), **`ensureQueryData`** returns cached data if available or fetches (returns the data, throws on error), and **`fetchQuery`** always respects staleness and returns data. In route loaders, the recommended pattern is to `ensureQueryData` for critical data (blocking navigation) and `prefetchQuery` for non-critical data (non-blocking):

```typescript
loader: async ({ context: { queryClient } }) => {
  queryClient.prefetchQuery(commentsQueryOptions)          // Non-blocking
  await queryClient.ensureQueryData(articleQueryOptions)   // Blocks navigation
}
```

**Hover-based prefetching** adds perceived performance at minimal cost:

```typescript
<Link
  to={`/post/${id}`}
  onMouseEnter={() => queryClient.prefetchQuery(postQueryOptions(id))}
  onFocus={() => queryClient.prefetchQuery(postQueryOptions(id))}
>
  {title}
</Link>
```

v5 also provides `usePrefetchQuery` for component-level prefetching before a Suspense boundary — it fires the fetch in the parent without suspending it, so the child's `useSuspenseQuery` finds warm cache.

---

## The ten most dangerous pitfalls

**1. Leaving `staleTime` at zero.** The default triggers background refetches on every mount and window focus. Set `staleTime: 60_000` globally as a starting point.

**2. Syncing server state to local state with `useEffect`.** This is the single most harmful anti-pattern. Copying query data into `useState` or Redux creates a stale copy that misses all background updates. **Derive state instead** — compute values directly from `data` or use `select`.

```typescript
// BAD — Creates out-of-sync intermediate renders
const [count, setCount] = useState(0)
useEffect(() => { if (data) setCount(data.length) }, [data])

// GOOD — Derived state, can never be out of sync
const count = data?.length ?? 0
```

**3. Scattered, untyped query keys.** A typo in one file (`['todo']` vs `['todos']`) silently breaks cache sharing and invalidation. Use `queryOptions` factories to make this structurally impossible.

**4. Not handling `fetch` API errors.** The `fetch` API does not reject on 4xx/5xx. Always check `response.ok` and throw explicitly, or React Query will treat HTTP errors as successful responses.

**5. Per-component error handling with `useEffect`.** If two components use the same query and both show error toasts via `useEffect`, users see duplicate toasts. Use the global `QueryCache` `onError` callback instead — it fires once per failed query.

**6. Stale closures in mutation callbacks.** Values captured in `useMutation` definition callbacks may be stale by the time the mutation resolves. Place closure-dependent logic in `mutate()` call-site callbacks, which capture the current closure.

**7. Object rest destructuring (`{ data, ...rest }`) breaks tracked queries.** React Query tracks which properties you access via Proxy getters. The spread operator accesses all properties, subscribing the component to every change and defeating the optimization.

**8. Forgetting to return the invalidation promise.** If `onSuccess` calls `invalidateQueries` without returning the promise, the mutation transitions to `success` before fresh data arrives, causing a brief stale UI flash.

**9. Mutating cache data directly.** `setQueryData` updaters must return new references. In-place mutation (`old.title = 'new'`) bypasses structural sharing and causes subtle rendering bugs.

**10. Over-applying optimistic updates.** Not every mutation needs optimism. Reserve it for high-confidence, instant-feedback interactions. The rollback UX for failed optimistic updates is inherently poor.

---

## Testing with isolated clients and disabled retries

The **number one testing gotcha** is React Query's default of 3 retries with exponential backoff. Without disabling retries, error-state tests timeout. Create a fresh `QueryClient` per test with retries disabled:

```typescript
const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: Infinity },
    },
  })

function createWrapper() {
  const client = createTestQueryClient()
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  )
}

// Test a custom hook
const { result } = renderHook(() => useQuery(todoQueries.detail(1)), {
  wrapper: createWrapper(),
})
await waitFor(() => expect(result.current.isSuccess).toBe(true))
```

Use **MSW (Mock Service Worker)** over mocking `fetch` directly — it intercepts at the network level for realistic tests. Pre-seed the cache with `queryClient.setQueryData` for tests that need to render immediately without fetching. Never share a `QueryClient` between tests to prevent cache leakage.

---

## TypeScript: let inference do the heavy lifting

The golden rule is **type your fetch functions, not your hooks**. Manually providing generics to `useQuery<Todo[]>` is a type assertion in disguise — if `fetchTodos` actually returns something different, TypeScript won't catch it. Instead:

```typescript
// Type the function return, let inference flow through
const fetchTodos = async (): Promise<Todo[]> => {
  const res = await fetch('/api/todos')
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

const { data } = useQuery({ queryKey: ['todos'], queryFn: fetchTodos })
// data: Todo[] | undefined — inferred correctly
```

Register a **global error type** to avoid typing `Error` everywhere:

```typescript
declare module '@tanstack/react-query' {
  interface Register {
    defaultError: AxiosError<ApiError>
  }
}
```

With `useSuspenseQuery`, `data` is typed as `Todo[]` (never `undefined`) because the Suspense boundary guarantees data exists before the component renders.

---

## Performance: structural sharing, deduplication, and waterfalls

React Query ships three built-in optimizations that most developers underappreciate. **Structural sharing** performs a deep comparison after every refetch and reuses unchanged object references, preventing unnecessary re-renders for `React.memo` components. **Query deduplication** ensures that 10 components mounting with the same query key produce exactly one network request — promises are shared internally. **Tracked queries** use Proxy-based property tracking so that a component destructuring only `{ data }` won't re-render when `isFetching` changes.

The **biggest performance footgun** is request waterfalls — when one fetch can't start until another finishes. Three strategies eliminate them:

- **Hoist parallel queries** to the same component level instead of nesting parent-child fetches
- **Use `useSuspenseQueries`** (not multiple `useSuspenseQuery` calls) for parallel Suspense fetching
- **Prefetch in route loaders** to start fetches before components mount

v5's `useQueries` gained a `combine` option for merging dynamic parallel query results into a single derived value with structural sharing:

```typescript
const { data, isPending } = useQueries({
  queries: ids.map((id) => ({ queryKey: ['post', id], queryFn: () => fetchPost(id) })),
  combine: (results) => ({
    data: results.map((r) => r.data).filter(Boolean),
    isPending: results.some((r) => r.isPending),
  }),
})
```

---

## What v5 broke on purpose — and why

v5 was a deliberate, opinionated reset. The **removal of `onSuccess`/`onError`/`onSettled` from `useQuery`** was the most controversial change. TkDodo explained in "Breaking React Query's API on Purpose" that these callbacks fired per-observer (per component instance), not per-query, causing duplicate side effects and sync bugs. The replacement is global `QueryCache` callbacks for shared logic and direct component logic for UI concerns.

Other breaking changes that reshape daily usage: the **single object syntax** eliminates all positional argument overloads (a codemod handles migration). **`cacheTime` became `gcTime`** to accurately reflect its garbage-collection purpose. **`loading` status became `pending`**, with `isLoading` redefined as `isPending && isFetching` (matching the old `isInitialLoading`). **`keepPreviousData`** merged into `placeholderData` via `placeholderData: keepPreviousData`. The dedicated **`useSuspenseQuery`** hook replaced the `suspense: true` option, providing proper TypeScript narrowing where `data` is guaranteed defined. The new **`queryOptions` helper** and **`skipToken`** filled critical type-safety gaps. And `useQueries` gained the `combine` option while infinite queries gained `maxPages` and required `initialPageParam`. The result is a **~20% smaller bundle** with a more coherent, type-safe API surface.

---

## Conclusion

The v5 mental model centers on three principles. First, **`queryOptions` factories are the primary abstraction** — not custom hooks, not raw key arrays. They provide type safety, reusability across hooks and imperative APIs, and colocate the key-function-options triad. Second, **server state should never be copied into client state**. Derive everything from query results, use `select` for transformations, and let React Query be the single source of truth. Third, **prefetching is no longer optional** in React 19 — the sibling suspension change means "render-as-you-fetch" via route loaders or `usePrefetchQuery` is necessary to avoid waterfalls with Suspense.

The most impactful quick wins for any codebase are setting a global `staleTime` above zero, adopting `queryOptions` factories with `as const` keys, registering a global error type, using the `QueryCache` `onError` for centralized error handling, and structuring mutations with the callback separation pattern. These five changes alone eliminate the vast majority of React Query bugs and performance issues encountered in production.

Source: https://tanstack.com/query/v5/docs/framework/react/overview
