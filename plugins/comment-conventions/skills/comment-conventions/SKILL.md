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

- **Minimum** — list parameters / props / fields and the return value (or thrown errors), so the signature reads at a glance.
- **Better** — add a one-line description of the purpose.
- **Bonus** — include a short usage example.

A "component" here means whatever the language calls its UI unit: a React component, a Vue SFC, a Svelte component, a Web Component, an Angular component, etc. The same rule applies — document props, briefly describe purpose, optionally show a usage snippet.

This rule fires only on *new* functions/methods/components you are introducing in the current change. Don't retroactively docblock an entire untouched file just because you opened it. (The detection rule below covers the case where you do encounter a non-compliant existing function.)

## Rule 4 — Docblock prose: at most 3 sentences, each shorter than the last

The prose description inside a docblock has at most 3 sentences. Each sentence is strictly shorter than the one before it (measured in words or characters — close calls are fine, but the trend has to be downward).

This forces precision: the first sentence carries the weight, each follow-up trims rather than adds. It also mirrors how docblocks are actually read — the eye lands on line one, and bails as soon as it has enough.

**Wrong** — flat or growing sentence lengths:

```js
/**
 * Formats a price.
 * Handles currency conversion as needed.
 * It also supports localization for different regions and accepts an optional
 * configuration object that lets the caller override defaults.
 */
```

**Right** — descending lengths, each sentence shorter than the last:

```js
/**
 * Formats a price for display, applying currency conversion and locale rules.
 * Accepts an options object to override defaults.
 * Falls back to USD.
 */
```

This rule applies only to the prose description. Parameter listings (`@param`, `:param:`, `Args:`, etc.), return-type descriptions, and `@example` blocks are not part of the sentence count and are not subject to descending length.

A one-sentence or two-sentence docblock is fine — descending length only matters when a sentence follows another.

## Rule 5 — When you encounter a non-compliant existing function, ask before updating

When reading or modifying code, scan for functions/methods/components that either lack a docblock entirely or have one that violates the rules above (e.g., flat sentence lengths, history-narrating prose, marketing copy). Don't silently rewrite them — flag and ask.

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

Note: the historical narrative is gone, the docblock prose is three sentences with descending length, and `@param` / `@returns` / `@example` carry the structural detail outside the sentence-count rule.
