# Smart File Organizer

AI agent skill that analyzes file contents and renames them to meaningful names. Optionally reorganizes files into a logical folder structure.

## Install

```bash
npx skills add <your-github-username>/SmartFileOrganizer
```

## What it does

1. Scans a target directory recursively
2. Reads file contents (with automatic encoding detection)
3. Proposes descriptive file names based on content
4. Shows a dry-run preview for iterative approval
5. Renames (and optionally moves) files after user confirms
6. Moves unreadable files to `_unknown/`
7. Saves a rollback map for undo

## Modes

- `rename-only` — rename files in place (default)
- `full-organize` — rename + reorganize into categorized folders

## Usage Examples

Tell your AI agent:

> "Organize the files in ~/Downloads — rename them based on their content"

> "Clean up /projects/data with full-organize mode, use Korean file names"

> "Rollback the last file organization in ~/Downloads"

## Rollback

```bash
bash scripts/rename-map.sh show <dir>      # view the map
bash scripts/rename-map.sh rollback <dir>   # undo all changes
bash scripts/rename-map.sh clear <dir>      # delete the map
```

## Structure

```
SmartFileOrganizer/
├── SKILL.md                          # Skill definition
├── scripts/
│   └── rename-map.sh                 # Rollback helper
├── references/
│   └── naming-conventions.md         # Naming rules reference
└── README.md
```

## Supported Agents

Works with any [skills.sh](https://skills.sh) compatible agent: Kiro CLI, Claude Code, Cursor, Windsurf, Cline, and more.
