# Authentication Integration

**Scope note:** The TanStack Query docs do not prescribe an authentication pattern. Everything here is community convention (reflected in TanStack examples and TkDodo's blog) for combining the cache with token-based auth. Verify specifics against your HTTP client's own docs.

Related TanStack Query docs:
- [QueryClient.clear()](https://tanstack.com/query/v5/docs/reference/QueryClient#queryclientclear)
- [Disabling / Lazy queries](https://tanstack.com/query/v5/docs/framework/react/guides/disabling-queries)

## Principle

Keep token handling at the **HTTP layer**, not the query layer. React Query should see only resolved Promises (or rejections with meaningful errors). If you leak auth concerns into queries, every query function has to know about refresh tokens.

## Axios Interceptor with Refresh

```typescript
// src/lib/api-client.ts
import axios from 'axios'
import createAuthRefreshInterceptor from 'axios-auth-refresh'

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

apiClient.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

const refreshAuth = async (failedRequest: any) => {
  try {
    const newToken = await fetchNewToken()
    failedRequest.response.config.headers.Authorization = `Bearer ${newToken}`
    setAccessToken(newToken)
  } catch {
    removeAccessToken()
    window.location.href = '/login'
    throw new Error('Session expired')
  }
}

createAuthRefreshInterceptor(apiClient, refreshAuth, {
  statusCodes: [401],
  pauseInstanceWhileRefreshing: true,
})
```

## Gate Queries with `enabled` (or `skipToken`)

```typescript
const useTodos = () => {
  const { user } = useUser()

  return useQuery({
    queryKey: ['todos', user?.id],
    queryFn: user ? () => fetchTodos(user.id) : skipToken,
  })
}
```

`skipToken` is the type-safe v5 primitive — `data` stays properly typed through the disabled path. Use `enabled: !!user` only when you still need a non-skip `queryFn` reference (e.g., for manual `refetch`).

## Cache on Logout — `clear()`, not `invalidateQueries()`

```typescript
const logout = () => {
  removeAccessToken()
  queryClient.clear()   // Drops all cache, no refetches triggered
  navigate('/login')
}
```

`invalidateQueries()` would trigger background refetches of every active query — all of which would fail with 401 because the token is gone. Use `clear()` to both drop cached data and prevent the refetch cascade.

## Disable Retry on 401

Set a custom retry predicate in the default options so auth failures don't burn through three retries before the interceptor can handle them:

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        if (error?.response?.status === 401) return false
        return failureCount < 3
      },
    },
  },
})
```
