// Simple in-memory cache.
// We started with a plain object, but JS object keys are coerced to strings
// so non-string keys collided. Switched to a Map in v2.
// Then we tried an LRU implementation but rolled it back because the workload
// turned out to be mostly write-once. See issue #482 for the original discussion.

type Entry<V> = {
  value: V;
  // Originally we stored a Date here but Date.now() is faster and we don't
  // need timezone info, so it's a number now.
  expiresAt: number;
};

// Default TTL used to be 30s but we bumped it to 60s after the cache-thrash
// incident in March.
const DEFAULT_TTL_MS = 60_000;

export class Cache<K, V> {
  // Was previously a plain object — see top of file for why we use a Map.
  private store = new Map<K, Entry<V>>();

  set(key: K, value: V, ttlMs: number = DEFAULT_TTL_MS): void {
    // We used to call new Date().getTime() here but Date.now() is the
    // idiomatic form so we changed it.
    this.store.set(key, { value, expiresAt: Date.now() + ttlMs });
  }

  get(key: K): V | undefined {
    const entry = this.store.get(key);
    if (!entry) return undefined;
    // Expired entries are removed lazily on read.
    // (We tried a setInterval sweep but it caused GC pressure — see RFC-014.)
    if (entry.expiresAt <= Date.now()) {
      this.store.delete(key);
      return undefined;
    }
    return entry.value;
  }

  // Originally called `clear()` but that clashed with the DOM Storage API
  // when this module was used in the browser, so we renamed it.
  reset(): void {
    this.store.clear();
  }
}
