---
name: react-query
description: >
  TanStack Query v5 skill with three modes — code review, v4→v5 migration assistance, and coding
  guidance while writing v5 code. Trigger whenever code imports from `@tanstack/react-query` or
  `@tanstack/react-query-devtools`, or uses `useQuery`, `useMutation`, `useSuspenseQuery`,
  `useSuspenseQueries`, `useSuspenseInfiniteQuery`, `useInfiniteQuery`, `useQueries`,
  `useMutationState`, `queryOptions`, `skipToken`, `QueryClient`, `QueryClientProvider`,
  `QueryCache`, `MutationCache`, or `HydrationBoundary`. Also trigger for: auditing React data
  fetching code, replacing `useEffect`/`useState` fetching patterns, implementing cache
  invalidation, optimistic updates, prefetching, infinite scroll or pagination, upgrading from
  React Query v4 to v5, Suspense integration, MSW testing setup for React Query, and
  authentication/token-refresh wiring around queries. When in doubt whether this skill applies
  to React data management code, use it.
---

# TanStack Query v5 — Review, Migration & Coding Guide

**Authoritative source:** the [TanStack Query v5 React docs](https://tanstack.com/query/v5/docs/framework/react/overview). Every rule and pattern in this skill is either cited directly to a docs page or explicitly marked as a community best practice. When uncertain, fetch the cited URL and verify — the docs are the source of truth, not this file.

## How to Use This Skill

Pick a mode based on what the user is asking for. The modes compose — e.g., a v4 project being upgraded often wants both migration guidance and a review pass after.

| Intent | Mode | Primary reference |
|---|---|---|
| "Review this code" / "audit my React Query usage" / "check for anti-patterns" | **Review** | `references/review-checklist.md` |
| "Upgrade from v4" / "migrate to v5" / `cacheTime`/`onSuccess` on `useQuery` spotted | **Migrate** | `references/v5-migration.md` |
| "Add a query/mutation" / "how do I…" / setting up a new feature | **Code** | `references/coding-standards.md` + topic refs |

## Mode 1 — Review

When asked to audit a codebase:

1. **Discover surface area.** Search for all imports from `@tanstack/react-query` / `@tanstack/react-query-devtools`, identify the router, locate the `QueryClient` and its `defaultOptions`, enumerate every `useQuery` / `useMutation` / `useSuspenseQuery` / `useInfiniteQuery` / `useQueries` call site, and check for `queryOptions` factories vs scattered inline keys.
2. **Run the checklist.** Critical issues (C1–C6), warnings (W1–W14), and v4→v5 migrations (M1–M12) are in `references/review-checklist.md` with detection hints and doc URLs per check.
3. **Emit the report** in the exact structured format in `review-checklist.md` — include file:line, cite the v5 doc URL under **Source**, and give concrete before/after fixes for every finding.

Do **not** invent findings to fill the report. If the code is clean, say so.

## Mode 2 — Migrate v4 → v5

Full migration reference lives in `references/v5-migration.md`. TL;DR:

1. Upgrade the package — v5 requires React ≥ 18 and TypeScript ≥ 4.7.
2. Run the official codemod for the hook-signature change:
   ```bash
   npx jscodeshift@latest ./path/to/src/ \
     --extensions=ts,tsx \
     --parser=tsx \
     --transform=./node_modules/@tanstack/react-query/build/codemods/src/v5/remove-overloads/remove-overloads.cjs
   ```
3. Apply manual renames — `cacheTime → gcTime`, `keepPreviousData: true → placeholderData: keepPreviousData`, `suspense: true → useSuspenseQuery`, `useErrorBoundary → throwOnError`, `<Hydrate> → <HydrationBoundary>`, `status === 'loading' → 'pending'`, etc.
4. Add `initialPageParam` to every `useInfiniteQuery`.
5. Remove `onSuccess`/`onError`/`onSettled` from `useQuery` configs — relocate to `QueryCache` callbacks or component effects. Mutations keep these callbacks.
6. Run a review pass (Mode 1) afterward.

## Mode 3 — Code

Writing new v5 code. The full rule set is in `references/coding-standards.md`. The non-negotiables:

- **Global `staleTime > 0`** (60s is a good default). `gcTime >= staleTime`.
- **`QueryClient` at module scope**, never inside a component.
- **`queryOptions` factories**, never scattered inline keys. Structure keys generic → specific.
- **`queryKey` includes every variable used in `queryFn`** — treat it like a dependency array.
- **`response.ok` check** in any `fetch`-based `queryFn`.
- **`select` for transformation**, not copying to `useState`.
- **`skipToken` for conditional fetching** (preserves types). `enabled: false` only when manual `refetch` is intended.
- **Mutations: return the `invalidateQueries` promise from `onSuccess`** so the mutation stays pending until caches are fresh.
- **Optimistic updates: invalidate in `onSettled`**, not `onSuccess`. Snapshot → cancel → write → rollback on error.
- **`useSuspenseQuery` + `<ErrorBoundary>` paired with every `<Suspense>`**. Parallel fetches under one boundary use `useSuspenseQueries`.
- **`initialPageParam` is required** for `useInfiniteQuery`.
- **Type the `queryFn` return**; don't use manual generics on the hook.
- **Tests: fresh `QueryClient` per test**, `retry: false`, `gcTime: Infinity`, MSW for network mocking.

## v5 Status Flags Cheat Sheet

Source: [queries](https://tanstack.com/query/v5/docs/framework/react/guides/queries).

| Flag | Meaning |
|---|---|
| `isPending` | No cached data yet (v4 `isLoading`) |
| `isFetching` | A fetch is in flight (background or foreground) |
| `isLoading` | `isPending && isFetching` — first load in progress (v4 `isInitialLoading`) |
| `isSuccess` | Resolved; `data` is defined |
| `isError` | Rejected; `error` is defined |
| `isPlaceholderData` | Rendering placeholder / kept-previous data |

## Quick Anti-Pattern Scan

When reading or writing code, these should pattern-match instantly:

- `useState(data)` or `useEffect(() => setX(data), [data])` → copying server state to client state. Delete the local state.
- `const { data, ...rest } = useQuery(...)` → the spread defeats tracked-query re-render optimization.
- `fetch(url).then(r => r.json())` with no `r.ok` check → HTTP errors cached as success.
- `cacheTime:` anywhere → v4 leftover, rename to `gcTime`.
- `onSuccess` / `onError` / `onSettled` inside a `useQuery({...})` config → v4 leftover, these are removed in v5 for queries.
- `suspense: true` on a query → use `useSuspenseQuery`.
- `keepPreviousData: true` → rename to `placeholderData: keepPreviousData`.
- `useInfiniteQuery({...})` with no `initialPageParam` → will throw in v5.
- Multiple `useSuspenseQuery` calls in one component → serial waterfall, use `useSuspenseQueries`.
- `setQueryData` updater mutating `old` in place → breaks structural sharing.
- `invalidateQueries` inside a mutation `onSuccess` without `return` → UI flashes stale before refetch.
- Shared `QueryClient` across tests → state leakage, order-dependent failures.

## Reference Index

Every reference below cites the v5 docs at the top. Fetch the doc URLs when you need verification.

- **`references/review-checklist.md`** — audit tables (C1–C6, W1–W14, M1–M12) and the report format
- **`references/coding-standards.md`** — full opinionated rules for writing new v5 code
- **`references/v5-migration.md`** — complete v4→v5 change list and the official codemod
- **`references/setup.md`** — `QueryClient` configuration, `QueryCache.onError`, feature-based colocation, query key rules, `queryOptions`
- **`references/query-patterns.md`** — `select`, `skipToken`, dependent queries, paginated, infinite, prefetching, Suspense, error boundaries, status flags, cache timing, TypeScript tips
- **`references/mutations.md`** — basic mutations, callback separation, optimistic updates via `variables`, optimistic updates via cache manipulation with rollback
- **`references/auth.md`** — token refresh at the HTTP layer, `skipToken`/`enabled` gating, `queryClient.clear()` on logout, retry policy for 401s
- **`references/testing.md`** — per-test `QueryClient`, MSW handlers, success/error-path test shapes, cache pre-seeding

## Grounding Principle

Every recommendation in this skill maps to a v5 doc section. If a user request leads you into territory not covered by the cited docs (e.g., a third-party HTTP client's auth integration), call it out explicitly and verify against that tool's own documentation before recommending a pattern. When the v5 docs change between minor versions, the docs win — flag the discrepancy and offer to update this skill.
