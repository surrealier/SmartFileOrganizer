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
  <img src="https://img.shields.io/badge/mode-rename--only%20%7C%20full--organize%20%7C%20collect-orange" alt="modes" />
</p>

---

## ✨ Features

- Recursively scans target directories.
- **Content-based renaming** — reads every file's actual content and generates normalized names from scratch, never relying on original filenames.
- Encoding fallback detection (UTF-8 → CP949 → Shift_JIS → GB2312 → EUC-KR → Latin-1).
- **Language preference** — choose allowed languages at start; non-allowed languages are auto-translated (e.g., 日本語 → 한국어).
- **Rename strictness** — choose between `recovery` (fix only broken names) and `uniform` (standardize all names).
- **Dataset folder detection** — suspects bulk dataset directories and asks user to confirm skip or include.
- Supports `.hwpx` (ZIP/XML extraction), `.hwp`, `.pdf`, `.docx`, `.xlsx`, `.pptx` and more.
- Dry-run approval flow — iterates until user explicitly approves.
- Supports two modes:
  - `rename-only` (default)
  - `full-organize` (rename + create/rename/merge folders)
  - `collect` (gather files matching a purpose into one folder)
- Skips source code and executable files by default.
- Moves unreadable files to `_unknown/`.
- Saves rollback map for safe undo.

## 📦 Installation

### 1) Install from local repository (recommended while developing)

```bash
git clone https://github.com/surrealier/SmartFileOrganizer.git
cd SmartFileOrganizer
npx skills add .
```

### 2) Install directly from GitHub

```bash
npx skills add surrealier/SmartFileOrganizer
```

## 🚀 Quick Usage

Tell your AI agent:

- `Organize the files in ~/Downloads — rename them based on their content.`
- `Clean up /projects/data with full-organize mode, use Korean file names.`
- `Rollback the last file organization in ~/Downloads.`

## 🧭 How It Works

1. Ask user for target directory, mode, **allowed languages**, and **rename strictness**.
2. Scan files recursively; **detect suspected dataset folders** and ask user to confirm skip/include.
3. Analyze content/metadata by file type (including `.hwpx` ZIP/XML extraction).
4. Generate a **dry-run rename map** and **save rollback map immediately** after approval (crash-safe).
5. Iterate until user explicitly approves.
6. Execute rename (and optional folder create/rename/merge/move).
7. **Reconcile** rollback map against actual state, save changelog for undo.

## 🔁 Rollback Commands

```bash
# show current rollback map
bash scripts/rename-map.sh show <target-dir>

# undo all recorded rename/move operations
bash scripts/rename-map.sh rollback <target-dir>

# reconcile map after interrupted execution
bash scripts/rename-map.sh reconcile <target-dir>

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

Current version: **v1.4.0**

> Skills are copied as a snapshot at install time. To update, run `npx skills add surrealier/SmartFileOrganizer` again.

| Version | Date | Changes |
|---------|------|---------|
| v1.4.0 | 2026-03-10 | Large-directory optimization: recovery-mode pre-filter skips content reading for already-descriptive names, summary-first dry-run for 30+ files, batch merge deduplication, content reading byte caps (text 4 KB / docs 8 KB), progress reporting every 25 files. |
| v1.3.0 | 2026-03-09 | Pre-execution rollback map for crash safety with post-execution reconcile. Rename strictness option: `recovery` (default, fix broken names only) vs `uniform` (standardize all names). |
| v1.2.0 | 2026-03-09 | Dataset folder detection with user confirmation prompt. Language preference setting (auto-translate non-allowed languages). Full-organize mode now supports folder creation, renaming, and merging. Enforced content-based rename for all non-code files — partially descriptive names are also renamed from scratch. Added `.hwpx` ZIP/XML and `.hwp` text extraction guidance. |
| v1.1.0 | 2026-03-09 | Naming convention overhaul: `_` separator, preserve person names / versions / status markers, allow uppercase for acronyms. Skip source code and executable files from renaming. Auto-generate changelog.md after execution. |
| v1.0.0 | 2026-03-06 | Initial release: rename-only / full-organize modes, rollback support, encoding detection. |
