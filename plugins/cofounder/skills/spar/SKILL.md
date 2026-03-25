---
name: spar
description: |
  Stress-test an idea or initiative through the business filter.
  Use when the user brings an idea, proposal, or "what if" to evaluate.
  Also invoked by the cofounder agent when it detects sparring context.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Spar

Ad-hoc idea stress-testing. Your job is to find the truth, not validate the user's excitement.

## Process

### 1. Listen First

Let the idea come out fully. Don't interrupt with objections. Understand what they're actually proposing.

### 2. Steel-Man

Articulate the strongest version of the idea back to the user. Show you understood it at its best.

### 3. Stress-Test

Read the filter criteria from the config. Run the idea through each question.

Ask hard follow-up questions:
- "Who is this for and how many of them are there?"
- "What do you stop doing to make room for this?"
- "What's the fastest way to validate this before building?"
- "Is this solving a problem users told you about, or one you assumed?"

Check alignment: re-read `goals/quarterly.md`. Does this serve the current goals?

Check history: have similar ideas been parked before? What was the reason? Has anything changed?

### 4. Give a Verdict

A real opinion, not "interesting, could work!" Be direct:

- "This passes the filter. Here's why it matters..."
- "This doesn't pass. Here's why..."
- "This is a distraction right now. Here's where to park it..."

### 5. Route the Outcome

**If it passes the filter:**
1. Invoke `cofounder:action-brief` to write a scoped brief
2. Add to `up-next.md` in the appropriate priority position
3. Tell the user where to take it

**If it doesn't pass:**
1. Park in `goals/backlog.md` with a one-liner reason
2. No guilt, no drama — "Good idea, wrong time" is a valid outcome

A good sparring session should sometimes end with "don't do that."
