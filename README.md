# linked-notes — Obsidian project notes for AI coding agents

[![skills.sh](https://skills.sh/b/tpklo/claude-note)](https://skills.sh/tpklo/claude-note)

Every note gets wired into your vault's knowledge graph: wikilinked to its
project, linked to related sibling notes, registered in the project's hub
note, and (optionally) synced to a Notion task database.

![demo](assets/demo.gif)

The skill uses the cross-platform [Agent Skills](https://agentskills.io)
`SKILL.md` format — it works in Claude Code, Codex CLI, Gemini CLI, Cursor,
and any other agent that reads the standard.

## Install

### Claude Code (plugin)

```
/plugin marketplace add tpklo/claude-note
/plugin install linked-notes@claude-note
```

Then run `/linked-notes:note` once.

### Any agent via skills.sh

```bash
npx skills add tpklo/claude-note
```

### Codex CLI / Gemini CLI / Cursor / other agents (manual)

Copy the skill folder into your agent's skills directory:

```bash
git clone --depth 1 https://github.com/tpklo/claude-note /tmp/claude-note
# Codex CLI
cp -r /tmp/claude-note/plugins/linked-notes/skills/note ~/.codex/skills/note
# Gemini CLI
cp -r /tmp/claude-note/plugins/linked-notes/skills/note ~/.gemini/skills/note
```

Then invoke the `note` skill (e.g. `/note` or "note this session", depending on your agent).

First-run setup auto-detects your Obsidian vaults (from Obsidian's own
registry), asks which one to use, and saves the answers to
`~/.config/linked-notes/config.json`. No manual editing.

## What it does

- **Note types**: progress logs, plans, client messages, scope docs, research, reviews
- **Full-session sweep**: capture an entire working session — every file, command, error, decision, dead-end
- **Linking**: frontmatter `related` list, `## Links` section, backlinks into top sibling notes, registration in the project hub note
- **Notion sync (optional)**: status summary + deep link back to Obsidian

## Requirements

- [Obsidian](https://obsidian.md) with at least one vault
- Notion sync needs a Notion MCP connector (optional)

## Config

`~/.config/linked-notes/config.json` — created by first-run setup, shared
across all agents. Delete it to re-run setup.

## License

MIT
