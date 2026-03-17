---
name: react-query
description: >
  TanStack Query v5 (React Query) best practices, code review, and strict coding standards.
  Use this skill whenever you encounter or write code involving useQuery, useMutation,
  useSuspenseQuery, useInfiniteQuery, useQueries, useMutationState, QueryClient,
  QueryClientProvider, queryOptions, skipToken, or any import from '@tanstack/react-query'.
  Also trigger when reviewing React data fetching code, replacing useEffect/useState
  data fetching patterns, implementing cache invalidation, optimistic updates, prefetching,
  or infinite scroll. Covers query key factories, mutation callback separation, Suspense
  integration with React 19, and the most dangerous anti-patterns. When in doubt whether
  this skill applies to React data management code, use it.
---

# TanStack Query v5 — Review & Coding Standards

This skill operates in two modes:

- **Review mode**: Audit existing code and produce a structured report of issues, anti-patterns, and v4-to-v5 migration opportunities
- **Coding mode**: Follow strict v5 best practices when writing new TanStack Query code

For the full API guide and detailed explanations, read [references/tanstack-query-v5-guide.md](references/tanstack-query-v5-guide.md).

---

## Review Mode

When asked to review TanStack Query usage in a project:

### Step 1: Discover the project's React Query surface

1. Search for all files importing from `@tanstack/react-query` or `@tanstack/react-query-devtools`
2. Identify the router in use (TanStack Router, React Router, Next.js, Remix, etc.) to assess prefetching patterns
3. Locate the `QueryClient` instantiation and its default configuration
4. Find all `useQuery`, `useMutation`, `useSuspenseQuery`, `useInfiniteQuery`, and `useQueries` call sites
5. Check for `queryOptions` factory files or patterns
6. Look for query key patterns (inline arrays vs factories)

### Step 2: Run the review checklist

Check every item below. Only report findings that actually exist in the codebase.

#### Critical Issues (bugs or data integrity problems)

| ID | Check | What to look for |
|----|-------|-------------------|
| C1 | **Server state copied to client state** | `useState` + `useEffect` that copies `data` from a query into local state. Creates a stale copy that misses background updates. |
| C2 | **fetch without error checking** | `fetch()` calls used as `queryFn` that don't check `response.ok`. The fetch API does not reject on 4xx/5xx — React Query treats HTTP errors as successful data. |
| C3 | **Cache mutation** | `setQueryData` updaters that mutate the previous value in-place instead of returning a new reference. Breaks structural sharing. |
| C4 | **Missing invalidation in onSettled** | Optimistic update mutations that invalidate only in `onSuccess` instead of `onSettled`. On error, the cache keeps stale optimistic data. |
| C5 | **gcTime < staleTime** | `gcTime` lower than `staleTime` breaks stale-while-revalidate — data gets garbage collected while still considered fresh. |

#### Warnings (anti-patterns and performance issues)

| ID | Check | What to look for |
|----|-------|-------------------|
| W1 | **staleTime left at zero** | No global `staleTime` configured. Every query refetches on mount, window focus, and reconnect. |
| W2 | **Scattered inline query keys** | Raw `['todos', id]` arrays spread across files instead of centralized `queryOptions` factories. Typos silently break cache sharing. |
| W3 | **Custom hooks wrapping useQuery with partial options** | Hooks accepting partial `UseQueryOptions` and spreading them. Breaks type inference — `data` becomes `unknown`. Use `queryOptions` factories instead. |
| W4 | **Per-component error toasts via useEffect** | Multiple components using the same query key each showing error toasts. Use the global `QueryCache` `onError` callback instead. |
| W5 | **Object rest destructuring** | `const { data, ...rest } = useQuery(...)` — spread accesses all Proxy properties, subscribing to every change and defeating tracked query optimization. |
| W6 | **Unreturned invalidation promise** | `onSuccess` calling `invalidateQueries` without `return`. Mutation transitions to success before fresh data arrives, causing a stale flash. |
| W7 | **Suspense waterfall** | Multiple `useSuspenseQuery` calls in the same component or sibling components under one `<Suspense>`. React 19 stops rendering after the first suspension. Use `useSuspenseQueries` or prefetch in route loaders. |
| W8 | **initialData trap** | `initialData: []` with `staleTime > 0` creates a phantom cache entry treated as fresh real data, preventing the actual fetch. |
| W9 | **Overused optimistic updates** | Optimistic updates on form submissions that navigate away or close dialogs. Rollback UX is confusing — reserve for toggles, likes, inline edits. |
| W10 | **Stale closures in mutation callbacks** | Component-scope values captured in `useMutation` definition callbacks that may be stale by resolution time. Move closure-dependent logic to `mutate()` call-site callbacks. |
| W11 | **Missing error boundary for Suspense** | `useSuspenseQuery` without a corresponding `<ErrorBoundary>` near the `<Suspense>` boundary. |
| W12 | **Shared QueryClient in tests** | Test files reusing a single `QueryClient` across tests, causing cache leakage. |

#### v4 to v5 Migration

| ID | v4 Pattern | v5 Replacement |
|----|-----------|----------------|
| M1 | `onSuccess`/`onError`/`onSettled` on `useQuery` | Removed. Use `QueryCache` callbacks for global handling, component logic for UI. |
| M2 | `keepPreviousData: true` | `placeholderData: keepPreviousData` (import from `@tanstack/react-query`) |
| M3 | `cacheTime` | Renamed to `gcTime` |
| M4 | `suspense: true` on query options | Use `useSuspenseQuery` / `useSuspenseInfiniteQuery` / `useSuspenseQueries` |
| M5 | `isInitialLoading` | Use `isLoading` (now equals `isPending && isFetching`) |
| M6 | `useQuery(key, fn, options)` positional args | Single object: `useQuery({ queryKey, queryFn, ...options })` |
| M7 | `enabled: false` for conditional fetching | Prefer `skipToken` for type-safe disabling |
| M8 | `loading` status | Renamed to `pending` |
| M9 | `useQuery<TData>()` manual generics | Remove generics — type the `queryFn` return and let inference flow |

### Step 3: Generate the report

Produce a structured report in this exact format:

```markdown
## TanStack Query Review Report

### Summary
- **Critical**: X issues
- **Warnings**: Y issues
- **Migration**: Z items
- **Assessment**: [one-sentence overall assessment]

### Critical Issues

#### [C1] Server state copied to client state
**File:** `src/components/TodoList.tsx:14`
**Issue:** Query data copied to useState via useEffect, creating stale copy that misses background updates.
**Fix:**
[before/after code block showing the fix]

### Warnings
[Same format — ID, file, issue, fix]

### v4 to v5 Migration Opportunities
[Same format — ID, file, v4 pattern found, v5 replacement with code]

### Recommendations
[Prioritized list of suggested improvements, starting with highest-impact changes]
```

Group findings by severity. Within each group, order by impact. Include file paths with line numbers and concrete before/after code fixes for every finding.

---

## Coding Standards

When writing new TanStack Query code, follow these rules strictly.

### QueryClient Setup

- Set a global `staleTime` above zero (60 seconds is a sensible default for most apps)
- Ensure `gcTime >= staleTime` always
- Use `QueryCache` `onError` for global error handling — never per-component `useEffect` error toasts
- Create `QueryClient` outside the component tree for a stable reference
- Include `<ReactQueryDevtools>` in development

### Query Key Factories with queryOptions

All query definitions go through `queryOptions` factories. Never use inline query key arrays.

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

Structure keys from most generic to most specific. Use `as const` for type-safe keys.

### File Organization

```
src/features/{feature}/
  queries.ts       // queryOptions factories + fetch functions
  mutations.ts     // useMutation hooks (custom hooks ARE appropriate for mutations)
  components/
    FeatureList.tsx
    FeatureDetail.tsx
```

### Data Fetching

- **Always check `response.ok`** when using the fetch API as a `queryFn`. Throw explicitly on 4xx/5xx.
- Use `skipToken` for conditional fetching (type-safe disabling). Use `enabled: false` only when you need manual `refetch()`.
- Use `select` for all data transformations. Keep selectors as stable references (module-level functions or `useCallback`).
- Use `placeholderData: (prev) => prev` to keep previous data during key changes (pagination, filtering).
- Never copy query data into `useState`. Derive everything from `data` directly.

### Mutations

- **Callback separation**: shared logic (invalidation, cache updates) in `useMutation` definition, UI logic (navigation, toasts, form resets) in `mutate()` call-site callbacks.
- **Return the invalidation promise** from `onSuccess` to keep the mutation pending until fresh data arrives.
- **Invalidate in `onSettled`** (not `onSuccess`) when using optimistic updates, so the cache corrects on both success and error.
- Never mutate cached data in-place in `setQueryData` updaters. Always return new references.
- Reserve optimistic updates for high-confidence, instant-feedback interactions (toggles, likes). Avoid for form submissions that navigate away.

### Suspense & React 19

- Use `useSuspenseQuery` (not `suspense: true`) — `data` is guaranteed defined.
- Always pair `<Suspense>` with `<ErrorBoundary>` (use `QueryErrorResetBoundary` + `react-error-boundary`).
- Never use multiple `useSuspenseQuery` calls in the same component — use `useSuspenseQueries` for parallel fetches.
- Prefetch in route loaders to avoid waterfalls. Use `ensureQueryData` for critical (blocking) data, `prefetchQuery` for non-critical.
- Use `startTransition` when query keys change (pagination) to keep old UI visible instead of showing the Suspense fallback.

### Infinite Queries

- Always provide `initialPageParam` (required in v5).
- Return `undefined` from `getNextPageParam` to signal no more pages.
- Use `maxPages` to limit stored pages for memory management.
- Combine with `IntersectionObserver` for infinite scroll.

### TypeScript

- **Type fetch functions, not hooks.** Never provide manual generics to `useQuery<T>()`. Let inference flow from the `queryFn` return type.
- Register a global error type via module augmentation (`Register` interface).
- Use `as const` on all query key arrays for literal type inference.

### Testing

- Create a fresh `QueryClient` per test with `retry: false` and `gcTime: Infinity`.
- Use MSW (Mock Service Worker) over mocking `fetch` directly.
- Pre-seed cache with `queryClient.setQueryData` for tests needing immediate data.
- Never share a `QueryClient` between tests.

---

## Quick Reference: v5 Status Flags

| v4 | v5 | Meaning |
|----|-----|---------|
| `isLoading` | `isPending` | No cached data yet |
| `isInitialLoading` | `isLoading` | `isPending && isFetching` |
| — | `isPlaceholderData` | Showing placeholder, real fetch in progress |

## Deep Dive

For the complete TanStack Query v5 reference covering all configuration options, detailed pattern explanations, performance optimization strategies, and the full list of v5 breaking changes, read [references/tanstack-query-v5-guide.md](references/tanstack-query-v5-guide.md).
