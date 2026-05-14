---
name: comment-conventions
description: Language-agnostic code commenting and docblock conventions. Trigger on every source-code Edit/Write in any language (JS/TS, Python, PHP, Ruby, Go, Rust, Java, Kotlin, Swift, C/C++, C#, Elixir, Lua, Shell, etc.) — even when the user has not mentioned comments, docblocks, JSDoc/TSDoc/PHPDoc, docstrings, or documentation. Governs every comment authored or modified, every new function/method/class/component (which must get a compliant docblock), every inline comment (which must stay terse — no prose walls, no business-logic essays, no "step 1 / step 2" narration in the code path), and any non-compliant docblock encountered in the file being edited (which must be fixed in place — no need to ask first, except when the existing docblock is unusually long and clearly intentional, in which case leave it alone). Apply to all code authoring across all languages, every time source code is touched. When in doubt whether this skill applies to a code edit, invoke it. Skip only for non-code files (JSON/YAML/TOML configs, markdown, lockfiles) or trivial one-character edits.
---

# Comment Conventions

Language-agnostic rules for writing code comments and docblocks. They apply to any language and any comment syntax — inline `//`, block `/* */`, JSDoc, TSDoc, PHPDoc, Python docstrings, Rustdoc `///`, GoDoc, KDoc, Elixir `@doc`, Ruby YARD, etc.

These rules govern *how* a comment is written when one exists, plus *when* a docblock is required. They do not push for more comments overall — terse, well-named code with no inline comments is still preferred.

## Rule 1 — Comments describe what is, not what was

Comments live in the present tense of the current implementation. The reader is asking "what does this do?" — they don't care that an earlier version did something else.

**Wrong** — narrates implementation history:

```js
// We used to use a Map here but it didn't preserve insertion order
// reliably across runtimes, so we switched to an array of tuples.
const entries = [];
```

**Right** — describes what the code does now:

```js
// Stored as tuples to preserve insertion order.
const entries = [];
```

The exception: reference past context only when the *reference itself* adds explanation a developer would want today — typically a ticket, RFC, ADR, or commit hash that has the full story.

**OK** — pointer adds value:

```js
// Tuple form required by the upstream consumer; see issue #123.
const entries = [];
```

Why this matters: implementation history rots. A reader two years from now sees no trace of the "old way" — the comment becomes archaeological noise. Git blame and the issue tracker are the right home for that history; the source file is for what is.

## Rule 2 — Comments are for developers

When a comment exists, it explains the code to the next developer who has to read it. It should answer "what does this do?" or "why is this here?" — it should not market the feature, narrate the user-facing experience, or restate what the function name already says.

**Wrong** — restates the obvious:

```python
# Calculate the total
def calculate_total(items): ...
```

**Wrong** — written for a non-developer audience:

```python
# Our amazing new pricing engine handles all the edge cases!
def calculate_total(items): ...
```

**Right** — explains a non-obvious mechanic:

```python
# Rounds at the line-item level to match the legacy invoice format.
def calculate_total(items): ...
```

## Rule 3 — New functions, methods, and components get a docblock

Every new function, method, class, or component is introduced with a docblock above it, in the language's idiomatic form (JSDoc/TSDoc, Python docstring, PHPDoc, Rustdoc `///`, GoDoc, KDoc, etc.).

The bar, in increasing order of value:

- **Minimum** — a one-line prose description of *what the function does and why it exists*, plus the parameters / props / fields and the return value (or thrown errors).
- **Better** — extend the description with a second (shorter) sentence that adds context the name doesn't carry, e.g. invariants, pairing with another function, or non-obvious behaviour.
- **Bonus** — include a short usage example.

A docblock that contains only tag annotations (`@param`, `@returns`, `:param:`, `Args:`, `Returns:`, etc.) with no prose description is **non-compliant**. The tags restate the signature; the description carries the meaning. Without it the docblock is noise around information the reader can already see in the function header.

**Wrong** — tag-only docblock, no prose description:

```js
/**
 * @param {function} t - i18next translate function
 * @param {() => void} onPress - callback when the action button is pressed
 * @returns {{ icon: string, label: string, color: string, ... }} SwipeableRow action descriptor
 */
export function makeDeleteAction(t, onPress) { ... }
```

**Right** — prose description first, then tags:

```js
/**
 * Builds the delete-action descriptor for a SwipeableRow with shared red styling.
 * Centralises colours and icon across every swipe-to-delete row.
 * Pairs with `makeEditAction`.
 *
 * @param {function} t - i18next translate function
 * @param {() => void} onPress - callback when the action button is pressed
 * @returns {{ icon: string, label: string, color: string, ... }} SwipeableRow action descriptor
 */
export function makeDeleteAction(t, onPress) { ... }
```

A "component" here means whatever the language calls its UI unit: a React component, a Vue SFC, a Svelte component, a Web Component, an Angular component, etc. The same rule applies — document props, briefly describe purpose, optionally show a usage snippet.

This rule fires only on *new* functions/methods/components you are introducing in the current change. Don't retroactively docblock an entire untouched file just because you opened it. (The detection rule below covers the case where you do encounter a non-compliant existing function.)

## Rule 4 — Docblock prose: at most 3 lines, each shorter than the last

The prose description inside a docblock has at most 3 source lines of text. Each line is strictly shorter than the one before it, measured in characters. No "close enough" and no "the trend is downward overall" — if any line is the same length as or longer than the line above it, the rule is violated and the prose must be rewritten.

**This rule applies only to the prose description block inside a docblock.** It does not apply to inline comments (`//`, `#`, `--`), to standalone block comments outside docblocks, or to the structured tag section of a docblock (`@param`, `@returns`, `:param:`, `Args:`, `Returns:`, `@example`, etc.). Tags are not part of the line count and are not subject to descending length.

This forces precision and caps the visual footprint: a docblock should be skim-able at a glance, not a 6-line wall. The first line carries the weight; each follow-up trims rather than adds.

**Wrong** — more than 3 lines of prose, or flat / ascending line lengths:

```js
/**
 * Formats a price.
 * Handles currency conversion as needed.
 * It also supports localization for different regions and accepts an optional
 * configuration object that lets the caller override defaults.
 * Falls back to USD when no currency is configured.
 */
```

**Wrong** — only 3 sentences, but they wrap into 6+ lines of prose:

```js
/**
 * Self-contained date picker for react-hook-form: read-only Input with a calendar
 * icon that opens a `DateTimePickerModal` when tapped, with full keyboard support
 * and accessibility labels.
 * Reads and writes the field via `useFormContext`, handles employer-timezone shifting,
 * and clamps the selected date to the configured min/max range.
 * Owns its own open/closed state and exposes an imperative ref for parent control.
 */
```

**Wrong** — one sentence per line wastes the available column width and turns the docblock into a stack of short, ragged lines (even though each line is technically shorter than the previous):

```js
/**
 * Formats a price for display, applying currency conversion and locale rules.
 * Accepts an options object to override defaults.
 * Falls back to USD.
 */
```

**Right** — write prose as continuous text and choose wrap points so each line is packed close to the surrounding column width; the taper comes from the wrap points moving slightly leftward line by line, with line 3 being whatever spills over:

```js
/**
 * Formats a price for display, applying currency conversion and locale
 * rules. Accepts an options object to override defaults. Falls back
 * to USD.
 */
```

Sentence breaks live wherever they fall — mid-line is fine, even encouraged. The line breaks (not the sentence breaks) are what create the descending shape. If you can't say it in 3 packed lines that taper, cut content; don't sprawl over more lines and don't shrink lines 1 and 2 to make a short third line look "right."

A one-line or two-line docblock prose block is fine — descending length only matters when a line follows another.

**Validate before considering a docblock edit done.** Models are bad at counting characters in their own output, so do not rely on your own line-length judgment. After writing or modifying any docblock, run the validator that ships with this skill against the file you touched:

```bash
node <this-skill-dir>/scripts/validate-docblocks.mjs <file>
```

(`<this-skill-dir>` is the directory containing this `SKILL.md`.) If it flags any line, rewrite that line shorter and re-run. The edit is not complete until the script prints `OK: no docblock violations`. The validator currently parses `/** ... */` blocks (JS, TS, PHP, Java, Kotlin, Swift, C#, C/C++, Rust block form); for files in languages it does not parse (e.g. Python triple-quote docstrings, Rustdoc `///`), verify Rule 4 manually.

## Rule 5 — Inline comments stay terse; no prose walls in the code path

The default for an inline comment (`//`, `#`, `--`, single-line `/* ... */`) is **none**. Write one only when the *why* of the next line or two is non-obvious — a hidden constraint, a subtle invariant, a workaround for a specific bug, behaviour that would surprise a reader. If removing the comment wouldn't confuse a future reader, don't write it. Well-named identifiers already say *what* the code does; an inline comment exists to carry the *why* a reader cannot see.

When you do add one, keep it tight — typically a single line, at most two. **Inline comments are not a place for business-logic essays, "how this feature works" narration, "step 1 / step 2" walkthroughs, multi-paragraph rationale, or section banners introducing the next block of code.** This is the chatter to avoid. If an explanation genuinely needs a paragraph, it belongs in the function's docblock (where Rule 4 caps it at 3 descending lines), in a referenced ticket / RFC / ADR, or in the commit message — not as a wall of `//` lines wedged into a function body.

**Wrong** — prose wall narrating what the next block of code does:

```ts
// Step 1: We need to validate the input before processing it. The user may have
// passed in undefined or an empty string, in which case we should bail out early
// rather than continue with the rest of the function. This pattern is used
// throughout the codebase to keep error handling consistent.
// Step 2: Once we know the input is valid, we extract the relevant fields and
// pass them to the downstream service. Note that the downstream service expects
// fields in a specific order, so we have to be careful here.
if (!input) return null;
const { id, name } = input;
service.send(id, name);
```

**Wrong** — narrating what well-named code already says:

```js
// Loop over each user and send them a welcome email.
for (const user of users) {
  sendWelcomeEmail(user);
}
```

**Wrong** — section banner introducing a block:

```ts
// ============================================================
// PAYMENT PROCESSING
// This section handles the core payment flow for the checkout
// page, including validation, charging, and receipt generation.
// ============================================================
function processPayment(order) { ... }
```

**Right** — single-line inline comment carrying the non-obvious *why*:

```ts
// Order matters: legacy consumer requires id before name.
service.send(id, name);
```

**Right** — no comment at all, because the code is self-explanatory:

```js
for (const user of users) {
  sendWelcomeEmail(user);
}
```

The test for any inline comment is: would a reader two years from now, with no context, be *surprised* or *confused* by this line without it? If yes, write a tight comment carrying that one piece of context. If no, delete it. Business-logic context that doesn't pass this test isn't an inline-comment problem — it's a docblock, ADR, or commit-message problem, and stuffing it into the code path makes the file harder to read, not easier.

## Rule 6 — When you encounter a non-compliant existing function, fix it in place

When reading or modifying code, scan for functions/methods/components that either lack a docblock entirely or have one that violates the rules above, and fix them directly. Don't ask first. Common offenders to fix:

- No docblock at all on a function/method/component.
- Docblock with only tag annotations (`@param`, `@returns`, etc.) and no prose description — see Rule 3.
- Prose that narrates implementation history (Rule 1) or restates the function name / markets the feature (Rule 2).
- Docblock prose with flat or ascending line lengths, or more than 3 lines (Rule 4).
- Prose walls of inline comments narrating business logic, "step 1 / step 2" walkthroughs, or section banners inside a function body (Rule 5) — collapse them to the one or two lines of *why* that actually carry value, or delete them outright when the code is self-explanatory.

Apply this detection *only to functions/methods/components inside the file or region you are currently working on*. Don't grep the entire repo and rewrite a wall of docblocks — that's noise. The point is to catch the ones a developer would naturally see while doing the current task.

**Exception — leave intentionally long docblocks alone.** If a non-compliant docblock is unusually long and reads as deliberately written (multi-paragraph prose, dedicated sections like "Edge cases" / "Notes" / "Caveats", multiple `@example` blocks, or detailed narrative that clearly took effort), don't chop it down to fit Rule 4. Excessive description is a signal the author cared about that block — leave it untouched. The 3-line cap is a default for ordinary docblocks, not a hammer for existing thoughtful ones.

Don't touch generated code, vendored dependencies, or third-party files. Don't touch a function the user has explicitly told you to leave alone.

## Putting it together

A short before/after on a single function:

**Before:**

```ts
// Originally we computed this on the server but that was too slow
// so now it runs in the browser.
function priceFor(item, qty) {
  return item.unit * qty;
}
```

**After:**

```ts
/**
 * Returns the line-item price for `qty` units of `item`. Multiplies unit
 * price by quantity. No tax applied.
 *
 * @param item - The catalog item with a `unit` price.
 * @param qty - Quantity ordered.
 * @returns The line-item subtotal.
 *
 * @example
 *   priceFor({ unit: 9.99 }, 3) // 29.97
 */
function priceFor(item: Item, qty: number): number {
  return item.unit * qty;
}
```

Note: the historical narrative is gone, the docblock prose is packed continuous text wrapped to two descending lines, and `@param` / `@returns` / `@example` carry the structural detail outside the line-count rule.
