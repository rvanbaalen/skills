# Review Checklist & Report Format

Use this reference when asked to audit a TanStack Query codebase. Every check below is either directly stated in the [v5 docs](https://tanstack.com/query/v5/docs/framework/react/overview) or a widely-adopted community best practice — the *Source* column points to the authoritative doc section when one exists. If a codebase is following a pattern the docs don't cover, flag it as an observation rather than a violation.

## Discovery Steps

Before producing a report:

1. Search for all imports from `@tanstack/react-query` and `@tanstack/react-query-devtools`.
2. Identify the router (TanStack Router / React Router / Next / Remix) to assess prefetching opportunities.
3. Locate the `QueryClient` instantiation and read its `defaultOptions`.
4. List every `useQuery`, `useMutation`, `useSuspenseQuery`, `useInfiniteQuery`, `useQueries` call site.
5. Check for `queryOptions` factories versus scattered inline keys.
6. Check the package version in `package.json` — if it's `^4.x` you're looking at a v4 codebase, route findings through the migration table.

## Critical Issues (bugs or data integrity)

| ID | Check | Detection hint | Source |
|----|-------|---------------|--------|
| C1 | Server state copied to client state | `useState` initialized from a query's `data`, or `useEffect` that calls `setState(data)` | [important-defaults](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults) |
| C2 | `fetch()` without `response.ok` check in `queryFn` | `fetch(url).then(r => r.json())` with no throw on 4xx/5xx — fetch does not reject on HTTP errors | [query-functions](https://tanstack.com/query/v5/docs/framework/react/guides/query-functions) |
| C3 | Cache mutation inside `setQueryData` | Updater function mutates `old` in place instead of returning a new reference | [updates-from-mutation-responses](https://tanstack.com/query/v5/docs/framework/react/guides/updates-from-mutation-responses) |
| C4 | Missing invalidation in `onSettled` for optimistic updates | `onMutate` writes optimistic data, but invalidation only runs in `onSuccess` — on error the cache keeps stale optimistic state | [optimistic-updates](https://tanstack.com/query/v5/docs/framework/react/guides/optimistic-updates) |
| C5 | `gcTime < staleTime` | Data is garbage collected while still considered fresh — breaks stale-while-revalidate | [caching](https://tanstack.com/query/v5/docs/framework/react/guides/caching) |
| C6 | Query keys missing variables from `queryFn` | `queryFn` closes over `filters`/`sortBy` that aren't in `queryKey` — causes silent cache collisions | [query-keys](https://tanstack.com/query/v5/docs/framework/react/guides/query-keys) |

## Warnings (anti-patterns & perf)

| ID | Check | Source |
|----|-------|--------|
| W1 | Global `staleTime` left at zero — every query refetches on every mount/focus/reconnect | [important-defaults](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults) |
| W2 | Raw inline query keys scattered across files instead of `queryOptions` factories | [query-options](https://tanstack.com/query/v5/docs/framework/react/guides/query-options) |
| W3 | Custom hooks accepting `Partial<UseQueryOptions>` and spreading them — breaks type inference, `data` becomes `unknown` | [typescript](https://tanstack.com/query/v5/docs/framework/react/typescript) |
| W4 | Per-component error toasts via `useEffect` instead of `QueryCache.onError` — duplicates toasts across mounts | [QueryCache reference](https://tanstack.com/query/v5/docs/reference/QueryCache) |
| W5 | `const { data, ...rest } = useQuery(...)` — spread touches every property, defeats tracked-query re-render optimization | Community: [TkDodo — Status Checks in React Query](https://tkdodo.eu/blog/status-checks-in-react-query) |
| W6 | `onSuccess` in a mutation calling `invalidateQueries` without `return` — mutation resolves before refetch completes | [invalidations-from-mutations](https://tanstack.com/query/v5/docs/framework/react/guides/invalidations-from-mutations) |
| W7 | Sibling `useSuspenseQuery` calls under a single `<Suspense>` — creates a waterfall. Use `useSuspenseQueries` | [suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense) |
| W8 | `initialData: []` combined with `staleTime > 0` — phantom cache entry prevents the real fetch | [initial-query-data](https://tanstack.com/query/v5/docs/framework/react/guides/initial-query-data) |
| W9 | Optimistic updates on form submissions that navigate away — rollback UX is confusing | [optimistic-updates](https://tanstack.com/query/v5/docs/framework/react/guides/optimistic-updates) |
| W10 | Stale-closure risk — component values captured in `useMutation` definition callbacks | [mutations — side effects](https://tanstack.com/query/v5/docs/framework/react/guides/mutations#consecutive-mutations) |
| W11 | `useSuspenseQuery` without a paired `<ErrorBoundary>` near the `<Suspense>` boundary | [suspense](https://tanstack.com/query/v5/docs/framework/react/guides/suspense) |
| W12 | Single `QueryClient` shared across tests — leaks state, order-dependent failures | [testing](https://tanstack.com/query/v5/docs/framework/react/guides/testing) |
| W13 | `enabled: false` used where `skipToken` would preserve types | [disabling-queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries) |
| W14 | Manual generics on `useQuery<T>()` — prevents inference from flowing through `select` | [typescript](https://tanstack.com/query/v5/docs/framework/react/typescript) |

## v4 → v5 Migration

| ID | v4 | v5 |
|----|----|----|
| M1 | `onSuccess` / `onError` / `onSettled` on `useQuery` | Removed — use `QueryCache` callbacks or component logic |
| M2 | `keepPreviousData: true` | `placeholderData: keepPreviousData` (imported from `@tanstack/react-query`) |
| M3 | `cacheTime` | `gcTime` |
| M4 | `suspense: true` | `useSuspenseQuery` / `useSuspenseInfiniteQuery` / `useSuspenseQueries` |
| M5 | `isInitialLoading` | `isLoading` (now `isPending && isFetching`) |
| M6 | `useQuery(key, fn, options)` | `useQuery({ queryKey, queryFn, ...options })` — codemod handles this |
| M7 | `enabled: false` | `skipToken` is the type-safe primitive |
| M8 | `status === 'loading'` | `status === 'pending'` |
| M9 | `useQuery<T>()` manual generics | Type the `queryFn` return, drop generics |
| M10 | `useErrorBoundary: true` | `throwOnError: true` |
| M11 | `<Hydrate>` | `<HydrationBoundary>` |
| M12 | `hashQueryKey` | `hashKey` |

Full migration context: see `v5-migration.md` in this directory.

## Report Format

Produce a structured report in this exact shape. Only include sections that have findings.

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
**Issue:** Query data copied to useState via useEffect. The copy won't receive background updates from the cache.
**Source:** https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults
**Fix:**
```diff
- const { data } = useTodos()
- const [todos, setTodos] = useState(data)
- useEffect(() => setTodos(data), [data])
+ const { data: todos } = useTodos()
```

### Warnings
[Same shape — ID, file, issue, source, fix]

### v4 → v5 Migration Opportunities
[Same shape — ID, file, v4 pattern, v5 replacement]

### Recommendations
1. [Highest-impact change, with effort estimate]
2. …
```

Rules for the report:

- Always cite the v5 doc URL under **Source** so the reader can verify.
- Provide concrete `before`/`after` in every finding, not abstract advice.
- Group by severity. Within severity, order by impact.
- Include file paths with line numbers — the reader should be able to jump straight to the code.
- Don't invent findings to fill the report. If the codebase is clean, say so.
