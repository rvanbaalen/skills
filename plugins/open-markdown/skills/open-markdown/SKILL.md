---
name: open-markdown
description: Offer to open markdown documents in mdreader after writing them. Trigger this skill whenever you write or create a markdown file that is a plan, spec, design document, architecture doc, implementation guide, proposal, RFC, or any substantive document meant to be read (not just a config snippet or small edit). Also trigger when the user asks to "open", "view", or "preview" a markdown file. Do NOT trigger for trivial edits to existing files (like fixing a typo in a README), code comments, or CLAUDE.md updates.
---

# Open Markdown in mdreader

After writing a markdown document that's meant to be read as a standalone document, offer to open it in mdreader so the user can read it comfortably in a rendered view.

## What qualifies as a "document"

This skill applies to markdown files that are substantive, standalone documents someone would want to sit down and read. Think:

- Implementation plans
- Technical specs or RFCs
- Architecture or design documents
- Project proposals
- Status reports or summaries
- Any file the user explicitly asks to view

This skill does NOT apply to:

- Small edits to existing files (typo fixes, appending a line)
- CLAUDE.md or configuration files
- Code files that happen to have markdown comments
- Commit messages or PR descriptions
- Memory files

The distinction is simple: if you just wrote something the user will want to *read through*, offer to open it. If it's a quick edit they already know about, don't.

## Workflow

### 1. Check if mdreader is available

Before offering to open anything, verify mdreader is installed:

```bash
which mdreader
```

If mdreader is not found, install it:

```bash
brew tap rvanbaalen/mdreader
brew install mdreader
```

If brew is not available or the install fails, tell the user mdreader couldn't be installed and provide the GitHub link: https://github.com/rvanbaalen/mdreader

### 2. Ask the user

After writing or creating a qualifying markdown document, use `AskUserQuestion` to ask:

**Question:** "I've written `<filename>` — would you like to open it in mdreader?"

**Options:**
- **Yes** — open it now
- **No** — continue without opening

Keep it lightweight. One question, two options. Don't over-explain what mdreader is.

### 3. Open in mdreader

If the user says yes, run:

```bash
mdreader <absolute-path-to-file>
```

mdreader runs as a background process (it opens in the user's default browser), so this won't block the session. After opening, continue with whatever comes next — don't wait for confirmation that it opened.

## Multiple files in one session

If you write several qualifying documents in quick succession (e.g., a plan and a spec), batch them into a single question rather than asking repeatedly:

**Question:** "I've written these documents — want to open any in mdreader?"

**Options:**
- **All** — open all of them
- **Pick** — let me choose (then list them individually)
- **None** — skip

## When the user asks to open a file

If the user explicitly asks to "open", "view", or "preview" a markdown file, skip the question and open it directly with mdreader. They already told you what they want.
