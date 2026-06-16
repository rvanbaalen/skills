# Worked examples

Two short walkthroughs showing how to apply the eight principles end to end — how to walk them in order and name the trade-offs. They illustrate the *shape* of the reasoning; adapt it to the real interface in front of you. The canonical per-principle examples (trash can, recipe allergy, Mac close button, play/pause time-remaining, music-while-running) live in `SKILL.md`.

## Example A — Reviewing a screen

**Interface:** A "Delete account" settings screen. One red **Delete my account** button, no confirmation, a paragraph of legal text above it, and the same red used for a "Save changes" button elsewhere in settings.

A review walks the principles in order:

1. **Purpose** — The screen has a clear job (let people leave). Fine.
2. **Agency** — A destructive, irreversible action fires on a single tap with no confirmation and no undo. This is the opposite of forgiveness. Violation. Add a confirmation that requires intent (type the account name, or a two-step "Delete → confirm"), and explain what is and isn't recoverable — like a trash can, people should understand whether they can pull it back out.
3. **Responsibility** — Account deletion is high-stakes. State plainly what gets deleted, what's retained (and why), and when it becomes permanent. It's currently buried in legal prose → surface the consequences in plain language at the point of action.
4. **Familiarity** — Red means "Save" elsewhere in this same settings area and "Delete" here. Same look, different behavior — a broken convention. Reserve red for destructive actions; restyle Save.
5. **Flexibility** — Is the legal text legible at large font sizes, translated, and screen-reader friendly? Verify; don't assume.
6. **Simplicity** — Here, *more* context is the simpler outcome: a one-line summary of what deletion does beats a wall of legalese. Add the summary; keep the full terms a tap away.
7. **Craft** — Check the confirmation's loading and failure states (what if deletion fails mid-way?) and the success/empty state afterward. A button you tap and then just wait erodes confidence.
8. **Delight** — Not the goal on a destructive screen. The emotion to reinforce is *calm confidence*, not fun. Don't add flourish.

**Trade-off named:** Agency vs. Responsibility — the confirmation deliberately interrupts the user's control, justified because the action is serious and irreversible. That's the rare case where an interruption earns its cost.

**Top changes:** (1) add an intentful confirmation with clear, recoverable-or-not consequences, (2) stop using the destructive red for Save, (3) replace the legal wall with a plain-language summary plus a link to full terms.

## Example B — Designing a flow

**Brief:** "Add an AI 'summarize this thread' button to a messaging app."

A design response leads with Purpose and reasons down:

- **Purpose** — The job: let someone catch up on a long thread fast. If threads are usually short, this may not earn its place — confirm the need first, and scope it to threads above some length.
- **Responsibility** — An AI summary can be wrong, can omit something safety-critical, or can misrepresent private messages — the same class of risk as the recipe app suggesting an allergen. Design the guardrail first: label the output as AI-generated, keep the original one tap away, never auto-send or auto-act on the summary, and never summarize messages the user can't already see.
- **Agency** — Summarizing is opt-in (a button), never automatic. The user can dismiss it and always reach the raw thread, and can re-summarize rather than being stuck with one result.
- **Familiarity** — Place and style the entry point like other thread actions; present the result in a familiar message/card pattern, not a novel surface people have to learn.
- **Simplicity** — One clear action ("Summarize"), one clear result. Resist tone/length/format options up front; add them only if real use shows one default can't serve people. Exactly enough.
- **Flexibility** — Make the summary readable at large text sizes and by screen readers, and handle non-English threads.
- **Craft** — Design the loading state (it takes time), the error state (model unavailable), and the edge case (thread too short to summarize) — not just the happy path.
- **Delight** — The emotion to reinforce is *relief* — "I'm caught up." That comes from speed, accuracy, and a trustworthy "see original," not from animation.

**Trade-offs named:** Purpose vs. scope creep — hold back tone/length controls until they're proven necessary (Simplicity wins until evidence says otherwise). Responsibility vs. friction — the "AI-generated, view original" affordance adds a step but is non-negotiable for a feature that can be confidently wrong.
