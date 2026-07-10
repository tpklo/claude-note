# linked-notes — Obsidian project notes for Claude Code

Every note gets wired into your vault's knowledge graph: wikilinked to its
project, linked to related sibling notes, registered in the project's hub
note, and (optionally) synced to a Notion task database.

## Install

```
/plugin marketplace add tpklo/claude-note
/plugin install linked-notes@claude-note
```

Then run `/linked-notes:note` once — first-run setup auto-detects your
Obsidian vaults (from Obsidian's own registry), asks which one to use, and
saves the answers to `~/.claude/linked-notes.config.json`. No manual editing.

## What it does

- **Note types**: progress logs, plans, client messages, scope docs, research, reviews
- **Full-session sweep**: capture an entire working session — every file, command, error, decision, dead-end
- **Linking**: frontmatter `related` list, `## Links` section, backlinks into top sibling notes, registration in the project hub note
- **Notion sync (optional)**: status summary + deep link back to Obsidian

## Requirements

- [Obsidian](https://obsidian.md) with at least one vault
- Notion sync needs the Notion MCP connector (optional)

## Config

`~/.claude/linked-notes.config.json` — created by first-run setup. Delete it to re-run setup.

## License

MIT
