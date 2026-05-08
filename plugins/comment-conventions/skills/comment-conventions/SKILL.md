---
name: comment-conventions
description: Language-agnostic code commenting and docblock conventions. Apply whenever writing or editing code comments, JSDoc/TSDoc/PHPDoc/Python docstrings/Rustdoc/GoDoc/KDoc/etc., or adding any new function, method, class, or component. Also apply when reading or modifying existing code that contains functions/methods without a compliant docblock — surface them and ask the user whether to update. Trigger even when the user does not explicitly mention comments or docblocks; these rules apply to all code authoring across all languages.
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

The prose description inside a docblock has at most 3 source lines of text. Each line is strictly shorter than the one before it (measured in characters — close calls are fine, but the trend has to be downward).

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

**Right** — at most 3 lines, each line shorter than the previous:

```js
/**
 * Formats a price for display, applying currency conversion and locale rules.
 * Accepts an options object to override defaults.
 * Falls back to USD.
 */
```

Pack each line as full as the surrounding line-length convention allows — a sentence can finish mid-line and the next one can start on the same line, as long as the visible source lines stay within the 3-line cap and each line is shorter than the previous. If you can't say it in 3 lines that taper, cut content; don't wrap a long sentence over multiple lines to look compliant.

A one-line or two-line docblock prose block is fine — descending length only matters when a line follows another.

## Rule 5 — When you encounter a non-compliant existing function, ask before updating

When reading or modifying code, scan for functions/methods/components that either lack a docblock entirely or have one that violates the rules above. Common offenders to flag:

- No docblock at all on a function/method/component.
- Docblock with only tag annotations (`@param`, `@returns`, etc.) and no prose description — see Rule 3.
- Prose that narrates implementation history (Rule 1) or restates the function name / markets the feature (Rule 2).
- Docblock prose with flat or ascending line lengths, or more than 3 lines (Rule 4).

Don't silently rewrite them — flag and ask.

Use the `AskUserQuestion` tool with one question per offender (or grouped if there are many in one file). Each question's options are exactly:

- `Update docblock` — apply the conventions to that function/method/component.
- `Skip` — leave it as-is and move on.

Apply this detection *only to functions/methods/components inside the file or region you are currently working on*. Don't grep the entire repo and surface a wall of questions — that's noise. The point is to catch the ones a developer would naturally see while doing the current task.

If there are many offenders in the working file (say, more than ~5), batch them into a single question with `multiSelect: true` so the user can tick all the ones to update in one pass. The header should be the file name.

**Example invocation pattern:**

```
AskUserQuestion({
  questions: [
    {
      question: "Update docblock on `calculateTotal` (src/pricing.ts)?",
      header: "calculateTotal",
      multiSelect: false,
      options: [
        { label: "Update docblock", description: "Add/rewrite to follow comment-conventions rules" },
        { label: "Skip", description: "Leave as-is" }
      ]
    }
  ]
})
```

If the user picks `Update docblock`, apply rules 1–4. If they pick `Skip`, move on without complaint and don't ask about that function again in the same session.

Don't ask about a function the user has explicitly told you to leave alone, and don't ask about generated code, vendored dependencies, or third-party files.

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
 * Returns the line-item price for `qty` units of `item`.
 * Multiplies unit price by quantity.
 * No tax applied.
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

Note: the historical narrative is gone, the docblock prose is three lines with descending length, and `@param` / `@returns` / `@example` carry the structural detail outside the line-count rule.
