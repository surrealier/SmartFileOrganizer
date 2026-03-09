<p align="center">
  <img src="https://img.shields.io/badge/Smart%20File%20Organizer-AI%20Skill-4F46E5?style=for-the-badge" alt="Smart File Organizer banner" />
</p>

<h1 align="center">Smart File Organizer</h1>

<p align="center">
  AI skill that analyzes file contents, proposes meaningful filenames, and optionally reorganizes folders with a safe rollback map.
</p>

<p align="center">
  <a href="./SKILL.md"><img src="https://img.shields.io/badge/skill-ready-success" alt="skill ready" /></a>
  <a href="./scripts/rename-map.sh"><img src="https://img.shields.io/badge/rollback-supported-blue" alt="rollback supported" /></a>
  <img src="https://img.shields.io/badge/mode-rename--only%20%7C%20full--organize-orange" alt="modes" />
</p>

---

## ✨ Features

- Recursively scans target directories.
- Reads content with encoding fallback detection.
- Proposes concise, descriptive names based on file content.
- Runs in dry-run approval flow before any rename/move.
- Supports two modes:
  - `rename-only` (default)
  - `full-organize` (rename + folder restructure)
- Moves unreadable files to `_unknown/`.
- Saves rollback map for safe undo.

## 📦 Installation

### 1) Install from local repository (recommended while developing)

```bash
git clone https://github.com/<owner>/SmartFileOrganizer.git
cd SmartFileOrganizer
npx skills add .
```

### 2) Install directly from GitHub

```bash
npx skills add <owner>/SmartFileOrganizer
```

> Replace `<owner>` with the actual GitHub account name.

## 🚀 Quick Usage

Tell your AI agent:

- `Organize the files in ~/Downloads — rename them based on their content.`
- `Clean up /projects/data with full-organize mode, use Korean file names.`
- `Rollback the last file organization in ~/Downloads.`

## 🧭 How It Works

1. Scan files recursively in target directory.
2. Analyze content/metadata by file type.
3. Generate a **dry-run rename map**.
4. Iterate until user explicitly approves.
5. Execute rename (and optional move).
6. Save rollback metadata for undo.

## 🔁 Rollback Commands

```bash
# show current rollback map
bash scripts/rename-map.sh show <target-dir>

# undo all recorded rename/move operations
bash scripts/rename-map.sh rollback <target-dir>

# delete rollback map
bash scripts/rename-map.sh clear <target-dir>
```

## 🗂 Project Structure

```text
SmartFileOrganizer/
├── SKILL.md
├── scripts/
│   └── rename-map.sh
├── references/
│   └── naming-conventions.md
└── README.md
```

## 🤖 Supported Agents

Works with [skills.sh](https://skills.sh)-compatible agents, including Kiro CLI, Claude Code, Cursor, Windsurf, Cline, and others.

## 🛡 Safety Principles

- Never overwrite existing files.
- Always require explicit approval before execution.
- Always save rollback map before renaming/moving.
- Preserve extension and naming consistency.

## 🔄 Version & Changelog

Current version: **v1.1.0**

> Skills are copied as a snapshot at install time. To update, run `npx skills add surrealier/SmartFileOrganizer` again.

| Version | Date | Changes |
|---------|------|---------|
| v1.1.0 | 2026-03-09 | Naming convention overhaul: `_` separator, preserve person names / versions / status markers, allow uppercase for acronyms. Skip source code and executable files from renaming. Auto-generate changelog.md after execution. |
| v1.0.0 | 2026-03-06 | Initial release: rename-only / full-organize modes, rollback support, encoding detection. |
