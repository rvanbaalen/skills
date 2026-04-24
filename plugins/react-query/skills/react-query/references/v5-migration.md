# v4 → v5 Migration

**Authoritative source:** [TanStack Query v5 — Migrating to v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5). Prefer the docs over this summary if they disagree — the docs are updated when minor v5 releases change behavior.

## Prerequisites

- React ≥ 18.0 (v5 relies on `useSyncExternalStore`).
- TypeScript ≥ 4.7 (for improved inference).

## Breaking Changes at a Glance

| Topic | v4 | v5 | Docs |
|---|---|---|---|
| Hook signature | `useQuery(key, fn, options)` | `useQuery({ queryKey, queryFn, ...options })` | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| Cache time | `cacheTime` | `gcTime` | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| Previous data | `keepPreviousData: true` | `placeholderData: keepPreviousData` | [paginated-queries](https://tanstack.com/query/v5/docs/framework/react/guides/paginated-queries) |
| Query status | `status: 'loading'` | `status: 'pending'` | [queries](https://tanstack.com/query/v5/docs/framework/react/guides/queries) |
| Loading flags | `isLoading` (no data yet) | `isPending` (no data yet); new `isLoading === isPending && isFetching` | [queries](https://tanstack.com/query/v5/docs/framework/react/guides/queries) |
| Query callbacks | `onSuccess` / `onError` / `onSettled` on `useQuery` | **Removed.** Use `QueryCache` / `MutationCache` callbacks, or handle in components. | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| Suspense | `suspense: true` option | Dedicated `useSuspenseQuery` / `useSuspenseInfiniteQuery` / `useSuspenseQueries` | [suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense) |
| Error boundaries | `useErrorBoundary: true` | `throwOnError: true` | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| SSR hydration | `<Hydrate>` | `<HydrationBoundary>` | [ssr](https://tanstack.com/query/v5/docs/framework/react/guides/ssr) |
| Infinite queries | `initialPageParam` inferred/optional | **`initialPageParam` is required** | [infinite-queries](https://tanstack.com/query/v5/docs/framework/react/guides/infinite-queries) |
| Disabling queries | `enabled: false` for conditional fetching | `skipToken` is the type-safe primitive | [disabling-queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries) |
| Removals | `isInitialLoading`, `remove()`, `refetchPage`, `contextSharing`, custom `context` prop, `isDataEqual` | Replaced per docs | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| Renames | `hashQueryKey` | `hashKey` | [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5) |
| Error type | Default `unknown` | Default `Error` | [typescript](https://tanstack.com/query/v5/docs/framework/react/typescript) |

## Codemod

The codemod ships inside the installed `@tanstack/react-query` package and is invoked via `jscodeshift`. Source: [migrating-to-v5 → Codemod](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5#codemod).

TypeScript / TSX:

```bash
npx jscodeshift@latest ./path/to/src/ \
  --extensions=ts,tsx \
  --parser=tsx \
  --transform=./node_modules/@tanstack/react-query/build/codemods/src/v5/remove-overloads/remove-overloads.cjs
```

JavaScript / JSX:

```bash
npx jscodeshift@latest ./path/to/src/ \
  --extensions=js,jsx \
  --transform=./node_modules/@tanstack/react-query/build/codemods/src/v5/remove-overloads/remove-overloads.cjs
```

For TypeScript projects, `--parser=tsx` is required — the codemod silently skips files otherwise. Run prettier/eslint afterward; the transform may affect formatting.

## Server-Side Behavior

- Default `retry` is `0` on the server (was `3`). Source: [migrating-to-v5](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5).
- Window focus now uses the `visibilitychange` event (no longer `focus`).
- Network status ignores `navigator.onLine`; assumes `online: true` on start and reacts to browser `online`/`offline` events.

## Migration Checklist

When auditing a v4 codebase for upgrade, search for each of these and replace:

1. `cacheTime:` → `gcTime:`
2. `keepPreviousData: true` → `placeholderData: keepPreviousData` (imported from `@tanstack/react-query`)
3. `useQuery(` with positional args → single-object signature (run the codemod)
4. `onSuccess` / `onError` / `onSettled` inside `useQuery({...})` configs → move to `QueryCache` callbacks or component effects
5. `suspense: true` → `useSuspenseQuery`
6. `useErrorBoundary:` → `throwOnError:`
7. `status === 'loading'` → `status === 'pending'`
8. `isInitialLoading` → `isLoading` (now `isPending && isFetching`)
9. `useInfiniteQuery` configs without `initialPageParam` → add it explicitly (`0`, `null`, etc.)
10. `<Hydrate>` → `<HydrationBoundary>`
11. `enabled: someCondition` used purely to disable → consider `skipToken` for type safety

The codemod handles (3) automatically. The rest are manual but mechanical.
