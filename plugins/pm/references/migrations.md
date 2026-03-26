# PM Plugin Migrations

Ordered migration changelog. When the context bootstrap detects a version mismatch between `config.md` (`pm_version`) and `plugin.json` (`version`), execute all migration blocks between the two versions in order.

Migrations are:
- **Idempotent** — running the same migration twice doesn't break anything
- **Forward-only** — no downgrades
- **Append-only** — new versions add sections, old sections stay

---

## 1.0.0 -> 2.0.0

### What changed
- Journal system added: sessions now use `YYYY-MM-DD-journal.md` files with machine-parseable event entries
- Estimation protocol updated: `estimates.md` gains a `User Est` column to separate user estimates from actuals
- Config tracks plugin version via `pm_version` field
- Self-reflect validation agent added (no migration impact — new behavior only)
- Context bootstrap standardized across all skills (no migration impact — new behavior only)

### Config changes
- Add `pm_version: 2.0.0` to config.md YAML frontmatter

### File changes
- `estimates.md`: Insert `User Est` column between `Estimated` and `Actual`
- Old format: `| Task | Category | Estimated | Actual | Ratio | Date |`
- New format: `| Task | Category | Estimated | User Est | Actual | Ratio | Date |`

### Migration steps

1. Read `config.md`. Add `pm_version: 2.0.0` to the YAML frontmatter (after `planning_completed`).
2. Read `estimates.md`. If it has rows (not just the header):
   - For each data row, insert `—` in the new `User Est` column position (between Estimated and Actual). Historical data doesn't have this split — the dash indicates "not tracked."
   - Update the header row to include `User Est`.
3. If `estimates.md` has only the header (no data rows), replace the header with the new format.
4. Verify the `sessions/` directory exists. Create it if missing.
5. Report to user: "PM plugin migrated to v2.0.0. Changes: journal system enabled, estimation tracking expanded."
