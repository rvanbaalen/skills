---
name: design-principles
description: Trigger this skill whenever the user wants to design, review, critique, or improve a user interface, screen, flow, component, or product experience — including mockups, prototypes, web/app UI, and design feedback. Use it when the user says things like "review this design", "is this good UX", "help me design a screen/flow", "what's wrong with this interface", or asks for design direction. Do NOT trigger for purely backend, data, or non-UI work.
---

# Design Principles

Design is **making something with intention** — focusing on what matters most to people so you build something they truly value. Good design serves people, respects and adapts to their lives, is clear and considered, and at its best is a genuine joy to use.

These are eight principles for getting there: **Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight.** Use them to review an interface or to give direction on a new one.

**There is no formula.** No "right" combination of these principles guarantees the perfect solution, and leaning into one often means compromising another — more control costs simplicity, familiarity costs novelty, flexibility costs focus. Resolving that tension with judgment *is* the work. So whenever honoring one principle costs another, surface the trade-off explicitly: name the tension, name the call you're making, and name why. That reasoning matters more than the verdict.

## How to use this skill

**When reviewing or critiquing**, walk the eight principles in order (Purpose → Delight). For each: say whether the interface honors or violates it, point at the specific element or moment, and give a concrete fix — measuring it against the examples below. Flag every place where one principle is being traded against another. Don't invent a finding for a principle that isn't at stake; say it's fine and move on.

**When creating or designing**, use the principles as direction, not a post-hoc audit. Start at Purpose and work down. For each key choice, explain the intent behind it in these terms, and call out the trade-offs you accepted and why.

Keep output specific and actionable for the interface in front of you — this screen, this flow, this component. Never deliver a generic lecture on the principles.

## The eight principles

### 1. Purpose — make something with intention
Every feature asks something of the user: their time, their attention, and their trust. All are valuable; none should be wasted. So choosing what to build is mostly deciding what *not* to include.
- Before a single sketch or line of code, confirm what you're making has a clear purpose. If you can't name the job in one sentence, it's a candidate to cut.
- Does this earn its place, or is it here because it was easy to add or someone asked? The strongest design move is often removal.

### 2. Agency — put people in control
People feel in control when you let them do things *their* way, and offering choices is the best way to bring agency in. The interface should never stand in the way of what someone is trying to do — instead of marching them down a predetermined path, let them dive in and explore at their own pace.
- **Forgiveness:** people accidentally send, change, and delete things constantly. Make undo easy. When someone is about to do something destructive, double-check it's intended.
- Interruptions can help, but use them carefully — only when someone's about to make a *big* mistake. Over-confirming routine actions trains people to dismiss dialogs without reading.
- Forgiveness gives people confidence they can recover from anything, so they feel capable, secure, and free to explore.

### 3. Responsibility — act in people's best interest
- **Privacy is a human right.** Picture someone walking up and saying "give me your phone number." "For what?" "I'll tell you once you give it to me." You wouldn't trust that person — yet interfaces do exactly this with permission prompts the second you launch, before you even know what the app does. Responsible interfaces wait for the right moment, ask only for what's necessary, and are transparent about what the data is for.
- **Safety.** For every feature ask: how could this be misused? who would be harmed? how do I prevent it? Anticipate that AI features can generate something unexpected or inaccurate. *Example: a recipe app where someone logs an allergy — the model might suggest an ingredient that causes a severe reaction.* That's real-world harm you can't leave to chance. Previews, confirmations, and disclaimers help; if the risk to safety outweighs the value, remove the feature entirely. Done right, this earns trust.

### 4. Familiarity — build on what people know
Your audience arrives with a lifetime of real-world experience and conventions learned from other interfaces.
- **Metaphors** tap into that. *A trash can means "stuff I don't want goes here — and I can pull it back out if I made a mistake."* Keep metaphors neither too literal nor too abstract — *an "inspector" that shows details of the current selection fails if it's so literal people don't recognize it, or so abstract the idea never lands.* And don't reinvent common metaphors: *a trash icon that means anything other than delete breaks recognition.*
- **Consistency:** things that look the same should behave the same. Placement matters too — *on Mac you always close a window from the top-left corner, the same spot every time*, so people don't have to think.

### 5. Flexibility — adapt to people's actual lives
People use your design in ways as unique as they are, and the same task shifts with context. *Controlling music looks one way through home speakers, another via AirPods and a watch on a run, and fully hands-free while driving.* Devices differ too — *on iPhone people want quick touch interactions; on Mac they expect deep workflows and precise pointer control.*
- Get curious about your audience: how old are they, what languages do they speak, are they pros or novices, do they rely on accessibility features? Treat accessibility as a baseline, not a setting.
- When no single layout fits everyone, let people **personalize** — rearrange controls, hide the ones they never use. Flexibility is an investment, but it proves you designed with them in mind.

### 6. Simplicity — exactly enough, not minimal
Simple is **not** minimal. Burying all functionality in one place looks minimal but isn't simple. Simple is frictionless and intuitive — people find what they need without effort.
- **Concise:** plain language, no jargon, no redundancy, fewer steps. Respect people's time.
- **Clear:** clarity is built with hierarchy — order, spacing, and contrast — so the most important item is always the most obvious. A clear design answers three questions: *what do I pay attention to? what can I interact with? how do I interact?* Distill where you can — complex data often reads better as a graphic; summarize so people focus on what they care about.
- Sometimes simplicity means *adding* context. *A play/pause control is familiar, but showing where you are and how much time is left lets people make informed decisions.* You've arrived at simplicity when you have exactly enough — no less, no more.

### 7. Craft — attention to detail that signals you care
Everyone knows a cheap product: a rickety door that won't close, a shirt that unravels in the wash. Software is the same — *a button you tap and then just wait, jittery scrolling, misaligned icons, a layout that breaks on rotation.* It feels fragile, and makes people question the quality of the results. Well-crafted design inspires confidence.
- Its ingredients: beautiful fonts that hold up across devices, thoughtful colors that adapt across light and dark, clear graphics and iconography, responsive animations that feel fluid and give immediate, natural feedback — all on reliable, secure SDKs.
- Craft is felt in the small things and comes from iteration. It's ongoing: great design has longevity, so keep evolving it as new features and hardware arrive. It is never "done."

### 8. Delight — the emotional payoff
Hard to define, instantly recognizable. Delightful interfaces are satisfying, enriching, and forge a real emotional connection — which starts when an experience feels human.
- You don't get there with confetti or flourishes tacked on at the end. You get there by identifying the emotion you want people to feel — relaxed, confident, excited — and reinforcing it throughout.
- Delight is the natural result of getting the other seven principles right. If a flow feels flat, look upstream before adding ornament.

## Trade-offs to name explicitly

These principles routinely conflict. When they do, state the tension and your call — don't pretend it's free.

| Tension | The judgment call |
|---|---|
| Agency vs. Responsibility | A confirmation or guardrail protects the user but interrupts their control. Interrupt only for serious, hard-to-reverse harm. |
| Simplicity vs. Flexibility | Fewer options is simpler but fits fewer people. Add personalization only where one default genuinely can't serve everyone. |
| Simplicity vs. Clarity | "Minimal" can hide information people need. If a decision is consequential, *add* the context — that's the simpler outcome. |
| Familiarity vs. Delight/Craft | Convention is learnable instantly; novelty can feel fresh but raises the cost of understanding. Break a convention only when the payoff clearly beats the relearning cost. |
| Purpose vs. Delight | Don't add a feature or animation *for* delight. Delight follows purpose; it doesn't justify scope. |
| Flexibility vs. Familiarity | Adapting per context can break the consistency people rely on. Adapt the layout, keep the mental model stable. |

## Output shape

**Reviews:** one short pass per principle in order, each with verdict → specific element → fix; then a short "Trade-offs" section naming the conflicts you found; then the 2–3 highest-impact changes.

**Designs:** lead with Purpose (what this is for and what you're leaving out), then the key choices with their intent, then the trade-offs you accepted and why.

A worked review and a worked design walkthrough are in [reference.md](reference.md).

## Common mistakes

- **Treating it as a scorecard.** The value is in the trade-off reasoning, not in eight checkmarks.
- **Generic lecturing.** "Be consistent" helps no one. "Close is top-left here but top-right on the previous screen" does.
- **Confusing minimal with simple.** Removing necessary information, or burying everything in one place, isn't simplicity.
- **Bolting on delight.** Confetti on a confusing flow makes it worse. Fix the upstream seven.
- **Forgetting Responsibility on AI features.** Always ask how output could be wrong or harmful (the recipe-allergy case) and design the guardrail before shipping.
- **Silent trade-offs.** If a recommendation costs another principle and you don't say so, you've hidden the most important part of the decision.
