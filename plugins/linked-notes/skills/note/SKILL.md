---
name: note
description: "Create linked notes in your Obsidian vault, optionally synced to Notion. Every new note gets wikilinked to its project, to sibling notes in the same folder, and registered in the project's main note — so any future session can discover related context by reading one file. Supports progress logs, plans, client messages, scope docs, research notes, and any project artifact. Use this skill whenever the user types /note, wants to log progress, save session context, capture what happened and what's next, document project status, draft a plan, or create any project-related note. Also triggers on 'note this', 'save progress', 'log this', 'จด', 'บันทึก'."
---

# /note — Linked Note Creator

Create notes in Obsidian that are wired into the project's knowledge graph — every note links to its project, discovers related sibling notes, and registers itself so future sessions find it instantly.

Two layers:
- **Obsidian** — detailed note inside the project folder, linked to siblings (always)
- **Notion** — task/status update in your configured database (only when enabled in config)

## Flow

```
User input → Identify project → Determine note type
           → Scan project folder for existing notes
           → Create note with wikilinks to related siblings
           → Register note in project's main note
           → Update sibling notes with backlink (if highly related)
           → Sync to Notion (if enabled)
           → Confirm with link map
```

## Step 0: Load Config (every run)

Read `~/.config/linked-notes/config.json`. If it exists and `vault_path` points to an existing directory → load it and skip to Step 1. If config exists but `vault_path` no longer exists: re-detect/re-ask ONLY the vault path (and recompute `vault_name`); preserve all other config keys.

**Config schema:**

```json
{
  "vault_path": "/absolute/path/to/vault",
  "vault_name": "vault-folder-name",
  "projects_dir": "10-Projects",
  "inbox_dir": "00-Inbox",
  "archive_dir": "40-Archive",
  "mocs_dir": "50-MOCs",
  "notion": { "enabled": false, "database_id": "" }
}
```

### First-run setup (config missing)

1. **Detect vaults** — read Obsidian's registry (first path that exists):
   - macOS: `~/Library/Application Support/obsidian/obsidian.json`
   - Linux: `~/.config/obsidian/obsidian.json`
   - Windows: `%APPDATA%\obsidian\obsidian.json`

   Parse `vaults` — each entry has `path`; the one with `"open": true` is the currently-open vault (recommend it first). If the registry is missing, ask the user for their vault path directly.
2. **Ask which vault** (present the detected vaults as choices; recommended = the `open: true` one).
3. **Ask folder layout:**
   - "PARA (scaffold for me)" → create `00-Inbox/ 10-Projects/ 40-Archive/ 50-MOCs/` in the vault, use defaults above
   - "I already have a projects folder" → ask for its name, set `projects_dir` (leave the others as defaults but do not create them)
   - "Flat vault" → set `projects_dir` to `""` (projects become top-level folders)
4. **Notion (optional):** only if Notion MCP tools are available in the session, ask "Sync note status to a Notion database?" If yes, ask for the database ID (from the DB URL). Otherwise write `"notion": { "enabled": false, "database_id": "" }`.
5. **Write the config file** (create the directory if needed; `vault_name` = basename of `vault_path`), show the user the saved JSON, then continue to Step 1.

Never hardcode paths — every later step interpolates from this config.

When `projects_dir` is `""`, drop that path segment AND its adjacent slash in every interpolation — paths become `{vault_path}/<project>/…` and the Obsidian URI becomes `file=<project>/<note-filename>`.

## Step 1: Understand What to Capture

If the user gives enough context after `/note`, extract and proceed. Otherwise ask briefly:

1. **Which project?** — match to existing project in `{projects_dir}/`. If new, create project folder first.
2. **What type of note?** — detect from context (see Note Types below). Don't ask if obvious.
3. **Content** — what happened, what was decided, what's next

Don't over-ask. If the conversation already contains the answers, extract them.

### Full-Session Sweep (default for session logs)

When the note captures a working session — the default for `/note` after a stretch of work — do not summarize from memory. **Walk the entire conversation from the first message to the last, in order, and mine it exhaustively.** A summary that loses detail defeats the purpose; the note exists so a future session can reconstruct exactly what happened without re-reading the transcript.

Sweep for every one of these and carry them into the note verbatim where it matters:

- **Every file touched** — full paths, what changed in each, and why
- **Every command run** — the exact command line, plus whether it worked or failed
- **Every error** — the literal error text (quote it), the cause found, and the fix applied
- **Every decision** — what was chosen, what was rejected, and the reasoning behind it
- **Every dead-end** — approaches tried that failed, so they're not retried next time
- **Every user correction or preference** — when the user redirected, pushed back, or stated how they want things done
- **Config / credential / environment facts** — values set, where they live, ports, URLs, IDs
- **Open threads** — anything left mid-air, half-done, or explicitly deferred

The longer and messier the session, the more valuable this sweep is — that's exactly when memory-based summaries drop the details that turn out to matter. Bias toward over-capturing: a note that's too detailed costs a few extra lines; a note that's too thin costs a future session hours of rediscovery.

### Note Types

| Type | Filename pattern | When |
|------|-----------------|------|
| `progress` | `progress/YYYY-MM-DD.md` | Session log, what changed, next steps |
| `plan` | `plan-<slug>.md` | Implementation plan, architecture decision |
| `client-msg` | `client-msg-<slug>.md` | Draft or sent message to client |
| `scope` | `scope-<slug>.md` | Scope doc, status summary, requirements |
| `research` | `research-<slug>.md` | Investigation, findings, reference material |
| `review` | `review-<slug>.md` | Code review, audit, retrospective |
| `general` | `<descriptive-slug>.md` | Anything that doesn't fit above |

The type determines the filename and template sections, but every type gets the same linking treatment.

## Step 2: Identify or Create Project Structure

Check if the project folder exists:

```
{vault_path}/{projects_dir}/<project-name>/
├── <project-name>.md          ← main project note
├── progress/                  ← session logs
│   └── YYYY-MM-DD.md
├── plan-*.md                  ← plans, decisions
├── client-msg-*.md            ← client communication
├── scope-*.md                 ← scope & status docs
└── *.md                       ← other project artifacts
```

**If project folder exists**: use it.
**If only `<project-name>.md` exists** (flat file, no folder): restructure — create folder, move the .md inside, create `progress/` subfolder.
**If nothing exists**: create the full structure using the main project note template below.

### Main project note template (`<project-name>.md`)

```markdown
---
tags: [project, <project-tag>]
status: active
created: YYYY-MM-DD
---

# <Project Name>

## Goal

## Progress Log

## Notes

## Done
```

### Multiple entries same day (progress only)

If `progress/YYYY-MM-DD.md` already exists, append a new section with timestamp:

```markdown
---
## HH:MM — <brief title>
...
```

## Step 3: Scan Project Folder for Related Notes

**This is the critical step that makes notes discoverable.** Before writing the new note, scan the project folder to find what already exists and what's relevant.

### How to scan

1. List all `.md` files in the project folder (recursive, exclude `backups/`)
2. For each file, read the frontmatter (`tags`, `project`, `related`) and the first heading
3. Identify related notes by matching:
   - **Shared tags** — notes with overlapping tags are related
   - **Topic overlap** — the new note's subject matches keywords in existing note titles/headings
   - **Explicit references** — existing notes that already mention the same concepts
   - **Temporal proximity** — recent notes in the same project are likely related

### Output: a related-notes list

Produce a list of related notes ranked by relevance. This list feeds into:
- The new note's `related` frontmatter field
- The new note's `## Links` section
- Backlinks injected into highly-related sibling notes

Don't link everything — link notes that someone reading the new note would actually want to open. A progress note about fixing the gateway is related to the plan that designed the gateway, not to a client message about pricing.

## Step 4: Write the Note

### Universal Frontmatter (all note types)

```yaml
---
tags: [<type>, <project-tag>, <topic-tags>]
project: "[[<project-name>]]"
created: YYYY-MM-DD HH:MM
related:
  - "[[sibling-note-1]]"
  - "[[sibling-note-2]]"
notion_url: <if applicable> (omit this field entirely when `notion.enabled` is false)
---
```

The `related` field is the key addition — it's a machine-readable list of wikilinks that any future session can parse to quickly load context. Keep it to 3-5 most relevant notes max.

### Progress Note Template

```markdown
---
tags: [progress, <project-tag>]
project: "[[<project-name>]]"
created: YYYY-MM-DD HH:MM
related:
  - "[[related-note]]"
---

# <Date> — <Brief Title>

## Context
Where the project stands right now. What state things are in.
Include: current architecture decisions, config state, what's deployed/running, environment details — anything someone needs to know to pick this up cold.

## What Changed
What was done in this session or since last note.
- Decisions made and why
- Problems encountered and how they were resolved
- Key files or configs changed
- Commands or workflows that worked (or didn't)

## Current State
Snapshot of where things are RIGHT NOW:
- What's working
- What's broken or incomplete
- Active branches, running services, pending PRs

## Next Steps
Concrete actions to take next, ordered by priority:
- [ ] First thing to do
- [ ] Then this
- [ ] And this

## Blockers
Anything preventing progress (skip if none):
- Waiting on X
- Need to figure out Y

## Links
- Project: [[<project-name>]]
- Related: [[note-1]], [[note-2]]
- Previous: [[{projects_dir}/<project-name>/progress/YYYY-MM-DD|previous progress note]]
```

### Plan Note Template

```markdown
---
tags: [plan, <project-tag>, <topic>]
project: "[[<project-name>]]"
created: YYYY-MM-DD HH:MM
related:
  - "[[related-note]]"
---

# Plan — <Title>

## Goal
What this plan achieves.

## Approach
How to do it. Steps, architecture, trade-offs.

## Dependencies
What needs to happen first, what this blocks.

## Open Questions
Unresolved decisions.

## Links
- Project: [[<project-name>]]
- Related: [[note-1]], [[note-2]]
```

### Client Message Template

```markdown
---
tags: [client-msg, <project-tag>, <draft|sent>]
project: "[[<project-name>]]"
created: YYYY-MM-DD HH:MM
related:
  - "[[related-note]]"
---

# Client Message — <Topic> [DRAFT|SENT]

## Message
<the actual message content>

## Context
Why this message, what it's responding to.

## Links
- Project: [[<project-name>]]
- Related: [[note-1]], [[note-2]]
```

### General Note Template

For scope, research, review, or anything else — use the appropriate sections but always include frontmatter with `project`, `related`, and a `## Links` section at the bottom.

### Writing guidelines
- Write as if explaining to yourself in 2 weeks who forgot everything
- Include specific file paths, command examples, config values — not vague descriptions
- "Changed the auth config" is bad. "Set `AUTH_METHOD=jwt` in `.env`, added `jwt-secret` to vault at `secret/hermes/auth`" is good
- Capture the WHY behind decisions, not just the WHAT
- If there was a tricky bug or non-obvious solution, document the full debugging path — what was tried, what failed, what finally worked. The dead-ends are as valuable as the fix; they stop the next session repeating them.
- Prefer completeness over brevity for session logs. This is the one place where longer is better — quote exact errors, paste the working command, list every file. Don't compress detail away to make the note look tidy.
- Use prose where reasoning matters and bullets/tables where it's a list of facts (files, commands, config). Pick whatever loses the least information.

## Step 5: Register Note in Project's Main Note

The project's main note (`<project-name>.md`) is the hub — every note in the project must be reachable from it. After creating the new note, update the main project note:

### For progress notes
If the project note has a `## Progress Log` section, append:
```markdown
- [[{projects_dir}/<project-name>/progress/YYYY-MM-DD|YYYY-MM-DD — Brief title]]
```
(Use the full vault-relative path so the wikilink is unambiguous — subject to the empty-`projects_dir` join rule from Step 0.)
If no `## Progress Log` section exists, create one.

### For all other note types
Find or create a section that matches the note type. Use these section names:

| Note type | Section in project note |
|-----------|----------------------|
| plan | `## Plans & Decisions` |
| client-msg | `## Client Messages (log)` |
| scope | `## Scope & Status` |
| research | `## Research` |
| review | `## Reviews` |
| general | `## Notes` |

Append a link entry:
```markdown
- [[<filename>|Brief description]] — YYYY-MM-DD
```

If the section doesn't exist, create it in a logical position (before `## Done` or at the end).

## Step 6: Backlink Highly Related Notes

For the top 1-2 most related sibling notes, add a backlink from them to the new note. This makes navigation bidirectional.

### How to add backlinks

1. Read the sibling note's `related` frontmatter field
2. Add the new note's wikilink to the list (if not already there)
3. If the sibling has a `## Links` section, add the new note there too

Only do this for notes that are strongly related — don't spam backlinks into every file. A good test: would someone reading the sibling note benefit from knowing this new note exists?

### Don't backlink these
- `backups/` files
- Old progress notes (only the most recent one)
- Notes with no semantic overlap

## Step 7: Update Notion

**Skip this entire step if `notion.enabled` is `false` in config, or if no Notion MCP tools are available.**

Use Notion MCP tools to create or update a task in the configured database (`{notion.database_id}`).

**Database ID**: `{notion.database_id}` from config

### New task or existing?
- Search the configured database for an existing task matching the project name
- **If exists**: update the page content with latest summary + next steps
- **If not**: create new task

After creating or updating the Notion task, edit the new note's frontmatter to set `notion_url` to the Notion page URL.

### Notion page content

```
## Latest Update (YYYY-MM-DD)
<2-3 sentence summary>

## Next Steps
- [ ] Priority actions

## Obsidian
obsidian://open?vault={vault_name}&file={projects_dir}/<project-name>/<note-filename>
```

URL-encode the `file` value (spaces etc.).

Keep Notion lean — it's for status at a glance + reminders. The full context lives in Obsidian.

## Step 8: Confirm with Link Map

Show the user what was created and how it's connected:

```
Created: {projects_dir}/<project>/<filename>.md

Links:
  ← project: [[<project-name>]] (registered in ## <Section>)
  ↔ related: [[sibling-1]], [[sibling-2]]
  → notion: updated "<Task Name>" (omit this line when Notion sync is disabled)
```

This confirmation doubles as a quick sanity check — the user can spot if a link is wrong or missing.

## Edge Cases

- **No clear project**: ask which project, or create in `{inbox_dir}/` as a standalone note — if `{inbox_dir}` doesn't exist, ask before creating it, or fall back to the vault root (still scan Inbox for related notes)
- **Multiple projects in one session**: create separate notes for each, ask user to confirm split
- **Quick capture** (user just wants to jot something fast): still use frontmatter + links, but keep content sections minimal
- **Existing progress note same day**: append with timestamp header, don't overwrite
- **Project in `{archive_dir}/`**: warn user the project is archived, ask if they want to reactivate (move back to `{projects_dir}/`, set `status: active`) (skip this check if the folder doesn't exist)
- **Cross-project reference**: if the new note relates to a different project, add a wikilink to that project's main note too (but don't register it there — that's the other project's responsibility)
- **No related notes found**: that's fine — just link to the project and skip the related field

## Important

- Always use today's date and current time
- Never delete or overwrite existing notes — append or create new
- Tags: lowercase, kebab-case
- Every note must be self-contained — readable without needing to open 5 other files
- The `related` frontmatter field is for machine consumption — keep it clean, use wikilink format
- Link to MOCs in `{mocs_dir}/` if a relevant topic hub exists (skip if the folder doesn't exist)
- If capturing from an active agent session, run the **Full-Session Sweep** (see Step 1) — walk the whole conversation start to finish and extract every file path, command, error, decision, and dead-end. Never summarize a working session from memory; that's where the details that matter get dropped.
- The scan step (Step 3) is what makes this skill valuable — don't skip it, even for quick captures
