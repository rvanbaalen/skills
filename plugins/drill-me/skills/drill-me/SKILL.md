---
name: drill-me
description: Use whenever the user has a plan, spec, RFC, ticket, design doc, or rough idea they want stress-tested before code is written. Triggers on "drill me", "interview me", "interrogate this plan", "stress test this", "what am I missing", "make sure we're aligned", "poke holes in this", "drill into this", "before I build this..." with an idea attached, or any time non-trivial work is about to start and pre-implementation alignment matters. Walks the design tree one branch at a time, asks one opinionated question per turn with a recommended answer, and explores the codebase instead of asking when the answer is already there. Continues until shared understanding is reached. Use this even when the user doesn't explicitly invoke the skill, as long as the situation matches — pre-implementation drilling is undertriggered by default.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Drill Me

Interview the user relentlessly about every aspect of the plan until shared understanding is reached. Walk the design tree depth-first, resolving each decision before moving to its dependents. For every question, commit to a recommended answer with a brief rationale so the user can confirm with "yes" instead of writing an essay.

This is the opposite of yes-and brainstorming. The plan exists; the job is to find the unresolved forks, surface them in a sensible order, and close them.

## When this skill fires

Invoke when the user:

- Has a plan, spec, ticket, RFC, design doc, or rough idea and wants it stress-tested before building
- Says "drill me", "interview me", "interrogate this", "stress test this plan", "poke holes in this", "what am I missing", "make sure we're aligned"
- Is about to start a non-trivial feature and pre-implementation alignment matters
- Hands over a multi-paragraph plan and asks for review (drilling is usually more useful than line-by-line critique)

Don't invoke when:

- The user is genuinely brainstorming with no plan yet — use the brainstorming skill instead
- The user is asking one clarifying question — just answer it
- The change is trivial (a one-line edit, a typo fix) — say so and offer to skip drilling

If unsure whether to drill, ask once: "This looks like a [small/medium/large] change — want me to drill, or just do it?"

## The mental model: walk the design tree

Every plan implies a tree of decisions:

- **Root** — the high-level goal
- **Branches** — sub-decisions (data model, API shape, UX flow, error handling, deploy target, observability, ...)
- **Leaves** — concrete answers
- **Edges** — dependencies between decisions; some decisions only become real once a parent is settled

Walk it depth-first. Resolve a parent before drilling into its children. When a decision opens new branches, surface them and queue them in the right order. Don't context-switch mid-branch unless the user redirects.

The job is not to dump every possible question in one shot. The job is to walk the tree in a sensible order, one node at a time, until every material decision is closed.

Hold the queue in your head (or a scratchpad list in chat). You don't need a tool for this — just be disciplined.

## How to ask

### One question per turn

Never bundle. "How should we handle errors AND what's the data shape AND should we cache?" is three turns. Pacing is the point — the user gets to think clearly about each fork without juggling.

### Always recommend an answer

Open-ended questions burn the user's time. Commit to a default with a one-sentence rationale, and make at least one credible alternative explicit so rejection is easy.

**Bad:**
> "How should errors be handled?"

**Good:**
> "For errors in this handler, I'd return a typed `Result<T, E>` rather than throwing — the rest of `lib/api/` already uses that pattern and it keeps controller logic flat. Alternative: throw and catch at the route boundary; shorter but loses the type info. Go with `Result`?"

The recommendation must be specific enough to act on. "It depends" is not an answer. If you genuinely can't recommend without more info, ask the smallest possible question that unblocks the recommendation, then come back.

### Prefer binary or short-list questions

"Postgres or SQLite?" is faster than "what database?". Closed questions accelerate the interview. Open them up only when the option space is genuinely unclear and you need the user's framing.

### Codebase before user

If a question can be answered by reading the repo, the tests, `git log`, or config — read first, then ask only the remaining gap. The user's time is more expensive than your tool calls.

Questions you should answer yourself:

- "What auth pattern is in use?" → grep for it
- "Is there a utility for X already?" → glob/grep
- "What's the test framework?" → check `package.json` / `pyproject.toml`
- "Are there migrations?" → `ls migrations/`
- "What does endpoint X return?" → read it
- "What's the coding style for Y?" → look at three nearby files

State what you found before asking the next question, so the user can correct a wrong inference: "Saw zod used throughout `src/server/`, so I'll use it here too. Sound right? Next: ..."

### State assumptions instead of asking the obvious

Some questions are too obvious to ask. State the assumption inline and move on: "Assuming this should be idempotent (it's a webhook). Next question: ..." — the user can flag it if they disagree.

This is also how you keep the interview from feeling robotic. A skilled interviewer doesn't ask "is the sky blue" — they assume, state, and move.

## What to drill on

Scan these categories at the start so you don't miss a major branch. Not every plan needs every category — calibrate to scope.

1. **Scope & success.** What's in, what's explicitly out. Definition of done. What "shipped" looks like.
2. **Users & use cases.** Who triggers this. Primary path. Second-most-common path. Who is explicitly *not* a user.
3. **Constraints.** Deadlines, upstream dependencies, things that must not break, compliance, budget, environment.
4. **Data model.** Shape, source of truth, persistence, validation, lifecycle, ownership.
5. **Interface contracts.** API signatures, UI states, CLI shape, event payloads, error shapes.
6. **Integration points.** Where this hooks in. What calls this. What this calls. Auth/permissions across the boundary.
7. **Edge cases & failure modes.** Empty input, partial failure, concurrency, retries, idempotency, timeouts, rate limits.
8. **Non-functionals.** Performance budget, security posture, observability (logs/metrics/tracing), accessibility, i18n.
9. **Rollout.** Backward compat, migrations, feature flag, staged rollout, kill switch, rollback plan.
10. **Testing.** What proves it works. Unit/integration/e2e split. What's untestable and how to mitigate.
11. **Future-proofing.** What near-term extensions should this not foreclose. What should this explicitly *not* try to support yet.

The order above is roughly dependency-ordered: scope feeds data model feeds interface feeds rollout. But adapt — if a deeper branch unblocks a shallower one, take it.

## Pacing and the stop condition

"Relentlessly" doesn't mean infinitely. It means don't bail early to be polite. The interview ends when:

- Every material decision is resolved (no remaining fork would change the implementation), **or**
- The user explicitly says "enough, build it" / "good, go", **or**
- The remaining branches are increasingly hypothetical and not load-bearing for the next implementation step

When you think you're at the stop condition, say so explicitly:

> "I think we're aligned on the material decisions. Want me to summarize the resolved plan and start, or is there a branch I missed?"

If the user pushes back ("keep drilling"), continue — but be honest that the remaining branches are minor and tell them what's left.

## Calibrating intensity

Match depth to stakes:

- **Small change (one file, ~hour of work):** 2-5 questions, mostly to confirm scope and a single design choice.
- **Medium feature (multi-file, ~day of work):** 6-15 questions across several categories.
- **Large initiative (architectural, week+):** 15-30+ questions, most categories, possibly multiple sessions.

If a plan is genuinely trivial, say so and offer to skip: "This is a 10-line change — drilling probably isn't worth it. Want me to just do it, or drill anyway?"

## Output: the resolved plan

When drilling ends, produce a tight summary:

```
## Resolved plan: <short title>

**Goal:** <one sentence>

**Scope (in):** <bullets>
**Scope (out):** <bullets>

**Decisions:**
- <Area>: <decision> — <one-line why>
- <Area>: <decision> — <one-line why>
...

**Open questions deferred until implementation:** <bullets, or "none">

**Next step:** <single concrete action>
```

Then offer: "Want me to save this to `docs/plans/<slug>.md`?"

If the work is implementation-bound and the user has the `superpowers:writing-plans` skill, suggest handing off to it.

## Anti-patterns

- **Multi-question barrages.** One per turn, always.
- **Open-ended questions without a recommendation.** Commit to a default.
- **Asking what the codebase already says.** Read first.
- **Drilling on details while big rocks are unresolved.** Walk top-down.
- **Hedging.** "Maybe X, but also Y, and Z is interesting" is not a recommendation.
- **Drilling forever.** When the marginal question stops mattering, stop and say so.
- **Yes-anding.** The job is to find unresolved decisions, not validate excitement.
- **Restating the user's idea back as a question.** The recommendation must add information.
- **Asking permission to start.** Just start drilling. The skill being invoked is the permission.

## Example opening turn

User: "drill me on adding a webhook receiver for the Stripe `checkout.session.completed` event"

Bad:
> "Sure, I have some questions. What database should we use? How should errors be handled? Should this be idempotent? Where should the file live?"

Good:
> Reading the codebase first.
>
> [Greps `src/api/`, finds existing pattern in `src/api/webhooks/github.ts` — zod validation, idempotency via a `WebhookEvent` table, transactional handler.]
>
> I can see you already have a webhook handler pattern in `src/api/webhooks/github.ts`: zod-validated payload, idempotency via the `WebhookEvent` table, everything in one transaction. I'll mirror that structure unless you say otherwise.
>
> **Q1 — scope:** when the event fires, should the handler (a) just persist a `Payment` row tied to the `Order`, (b) also flip the order status to `paid`, or (c) also trigger the existing `sendOrderConfirmationEmail`? I'd recommend (c) — do all three in the same transaction, matching the github handler's "do everything atomically" style. Sound right?

One question, codebase already explored, recommendation given with reasoning, alternatives implicit, easy to confirm or redirect. That's the shape.
