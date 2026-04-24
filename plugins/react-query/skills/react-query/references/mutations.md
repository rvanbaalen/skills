# Mutations & Optimistic Updates

**Authoritative sources:**
- [Mutations](https://tanstack.com/query/v5/docs/framework/react/guides/mutations)
- [Optimistic Updates](https://tanstack.com/query/v5/docs/framework/react/guides/optimistic-updates)
- [Invalidations from Mutations](https://tanstack.com/query/v5/docs/framework/react/guides/invalidations-from-mutations)
- [`useMutation` reference](https://tanstack.com/query/v5/docs/framework/react/reference/useMutation)

## Important v5 Notes

- `useQuery` lost `onSuccess` / `onError` / `onSettled`. **`useMutation` still has them** — these are the idiomatic place for side effects after a mutation.
- Mutation statuses: `isPending` (in-flight), `isSuccess`, `isError` — mirrors query naming.

## Basic Mutation

```typescript
export function useCreateTodo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (newTodo: CreateTodoDTO) =>
      api.post('/todos', newTodo).then(res => res.data),
    onSuccess: (data) => {
      queryClient.setQueryData(['todos', data.id], data)
      // Return the promise so the mutation stays pending until caches are fresh.
      return queryClient.invalidateQueries({ queryKey: ['todos', 'list'] })
    },
  })
}
```

**Return the invalidation promise from `onSuccess`.** Without `return`, the mutation transitions to `success` before the refetch completes, causing a stale-data flash in the UI.

## Callback Separation

Mutations support callbacks in **two places**: the hook definition and the `mutate()` call-site. Use both:

- **Definition callbacks** — shared logic: cache updates, invalidations, analytics.
- **Call-site callbacks** — UI logic: navigation, toast messages, form resets.

```typescript
// Definition — shared across call sites
const createTodo = useMutation({
  mutationFn: postTodo,
  onSuccess: (data) => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

// Call site — component-specific
createTodo.mutate(input, {
  onSuccess: () => {
    toast.success('Todo created')
    navigate('/todos')
  },
})
```

This also avoids stale-closure bugs where values captured in the definition are outdated by the time the mutation resolves.

## Optimistic Updates — Pattern 1: Via `variables`

The simplest approach, per the official docs: render `mutation.variables` inline while pending.

```typescript
const addTodo = useMutation({
  mutationFn: (text: string) => axios.post('/api/todos', { text }),
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

const { isPending, variables, mutate, isError } = addTodo

return (
  <ul>
    {todoQuery.data?.map(t => <li key={t.id}>{t.text}</li>)}
    {isPending && <li style={{ opacity: 0.5 }}>{variables}</li>}
    {isError && (
      <li style={{ color: 'red' }}>
        {variables}
        <button onClick={() => mutate(variables!)}>Retry</button>
      </li>
    )}
  </ul>
)
```

Use this when the mutation and its rendering live in the same component. For cross-component awareness, use `useMutationState` with a `mutationKey`.

## Optimistic Updates — Pattern 2: Cache Manipulation

Use when multiple UI surfaces need to reflect the change immediately. Source: [optimistic-updates](https://tanstack.com/query/v5/docs/framework/react/guides/optimistic-updates).

```typescript
useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    // Cancel in-flight refetches to avoid clobbering the optimistic write
    await queryClient.cancelQueries({ queryKey: ['todos'] })

    // Snapshot for rollback
    const previousTodos = queryClient.getQueryData<Todo[]>(['todos'])

    // Optimistic update — return a NEW reference, never mutate in place
    queryClient.setQueryData<Todo[]>(['todos'], (old) =>
      old?.map(t => t.id === newTodo.id ? newTodo : t)
    )

    return { previousTodos }
  },
  onError: (err, newTodo, context) => {
    // Rollback
    queryClient.setQueryData(['todos'], context?.previousTodos)
    toast.error('Update failed. Changes reverted.')
  },
  onSettled: () => {
    // Always refetch so client matches server eventually
    queryClient.invalidateQueries({ queryKey: ['todos'] })
  },
})
```

Non-negotiables:

- **Cancel first** — otherwise an in-flight fetch can overwrite your optimistic write.
- **Snapshot before updating** so rollback has a known-good state.
- **Invalidate in `onSettled`**, not `onSuccess`. On error you still want eventual consistency.
- **Never mutate cached data in place.** Updaters must return new references — structural sharing relies on it.

## When Optimistic UI Is (and Isn't) a Good Fit

Good: toggles, likes, inline edits, reactions — interactions where the optimistic success rate is very high and rollback is visually unsurprising.

Poor: form submissions that navigate away, dialogs that close on submit, mutations that produce server-generated IDs the UI immediately needs. Rollback UX is confusing when the user is already on another screen.
