---
name: smart-file-organizer
description: >
  Analyze file contents in a directory tree and intelligently rename files based on what they contain,
  optionally reorganizing them into a logical folder structure. Use this skill whenever the user wants to
  clean up messy file names, organize downloaded files, sort documents by content, rename files that have
  meaningless names (like IMG_20240101.jpg or document(3).pdf), or tidy up any folder where file names
  don't reflect their actual content. Also triggers when users mention bulk renaming, file cleanup,
  content-based organization, or folder restructuring.
---

# Smart File Organizer

Analyze file contents in a target directory (including all subdirectories), rename files to reflect their content, and optionally reorganize them into a logical folder structure.

## Modes

- **rename-only** (default): Rename files in place based on content analysis
- **full-organize**: Rename files AND move them into a categorized folder structure

## Procedure

### Step 1: Gather Parameters

Ask the user for:

1. **Target directory** — absolute path to scan (required)
2. **Mode** — `rename-only` or `full-organize` (default: rename-only)
3. **Allowed languages** — which languages to keep in file names (default: match original or English). Ask explicitly:
   ```
   파일명에 사용할 언어를 선택해주세요:
     허용 언어: (예: 한국어, English)
     그 외 언어 처리: 허용 언어 중 하나로 번역 (예: 日本語 → 한국어)
   ```
   - When file content is in a non-allowed language, translate the generated name into the user's preferred allowed language
   - Example: a Japanese PDF → analyze content in Japanese → generate Korean file name
   - Acronyms and proper nouns are exempt from translation (`IITP`, `YOLOv8`, etc.)
4. **File filter** — specific extensions to include/exclude (default: all files)
5. **Max depth** — how deep to recurse into subdirectories (default: unlimited)

If the user provides a directory without specifying other options, use defaults and proceed.

### Step 2: Scan and Inventory

1. List all files recursively in the target directory
2. Skip hidden files/directories (starting with `.`) and common ignore patterns (`node_modules`, `.git`, `__pycache__`, etc.)
3. **Skip source code files** by default — renaming these breaks import paths, include directives, and build systems. Excluded extensions: `.py`, `.cpp`, `.c`, `.h`, `.hpp`, `.js`, `.ts`, `.jsx`, `.tsx`, `.java`, `.go`, `.rs`, `.rb`, `.cs`, `.swift`, `.kt`, `.scala`, `.sh`, `.bat`, `.ps1`, and CI/CD config files (`Jenkinsfile*`, `Makefile`, `Dockerfile`, `*.cmake`). The user can override this with an explicit `--include-code` flag or request.
4. **Skip executable/installer files** — keep `.exe`, `.msi`, `.appimage`, `.dmg` files with their original names.
5. **Detect suspected dataset directories** — before processing, identify directories that may contain bulk datasets. A directory is suspected if ANY of the following is true:
   - It contains **100+ files with the same extension**
   - Files follow sequential or hash-based naming patterns (e.g., `img_0001.jpg`…`img_9999.jpg`, `a3f8c2.png`)
   - Its name matches common dataset patterns (case-insensitive): `train`, `val`, `valid`, `validation`, `test`, `dataset`, `datasets`, `images`, `labels`, `annotations`, `samples`, `corpus`, `raw`, `processed`
   - It contains annotation/manifest files alongside bulk data (e.g., `*.json`/`*.csv` annotation + 50+ image/text files)
   
   For each suspected directory, **ask the user** before deciding:
   ```
   ⚠ 다음 폴더가 데이터셋으로 의심됩니다:
     📁 train/ — 1523 .jpg files, sequential naming pattern
     📁 annotations/ — 1523 .json files + manifest.csv
   
   각 폴더에 대해 스킵할지 포함할지 선택해주세요:
     [S] 스킵 (데이터셋이므로 건드리지 않음)
     [I] 포함 (일반 폴더로 처리)
   ```
   - User-confirmed dataset directories are excluded entirely and logged with reason "dataset directory (user confirmed)"
   - User-confirmed non-dataset directories proceed to normal processing
3. Create an inventory with: current path, file size, extension, last modified date
4. Report the inventory summary to the user:
   - Total file count
   - Breakdown by extension
   - Total size

If there are more than 100 files, ask the user to confirm before proceeding or suggest narrowing the scope with filters.

**Batch processing** — to avoid context overflow and tool-call failures:

- Maximum batch size: **50 files** per batch
- When total files exceed 50, split the inventory into batches of up to 50
- Process each batch as an independent sub-agent (or sequential batch if sub-agents are unavailable):
  1. Each batch receives its own file list and performs Steps 3–4 independently
  2. Merge all batch results into a single unified rename map before presenting to the user
- Sub-agent batches may run in parallel (up to 4 concurrent batches)
- Each batch must return its partial rename map as JSON for merging

### Step 3: Analyze File Contents

**⚠ CRITICAL: ALL non-code files MUST be renamed to a normalized format based on their actual content. No exceptions.**

- The original file name is UNRELIABLE — treat it as if it were random characters
- You MUST read/analyze the file content first, then generate a name from scratch
- Files with partially descriptive but non-standard names (e.g., `073_재난안전_증강생성기술_XR증강.hwpx`, `report_v2_final.docx`, `김대리_보고서3.pdf`) MUST still be renamed after reading their content
- The ONLY reason to keep an original name is if it already perfectly matches the naming convention format AND accurately describes the specific content

**Rename criteria** — a file MUST be renamed if ANY of the following is true:
- Contains meaningless prefixes, serial numbers, or codes (`073_`, `IMG_`, `DSC_`, `001_`, `(3)`)
- Name is vague, abbreviated, or doesn't capture the document's specific subject
- Doesn't follow the `[YYMMDD_]<attr1>_<attr2>[_...<attrN>].<ext>` format from `references/naming-conventions.md`
- Contains non-allowed language characters (per Step 1 language settings)
- Contains generic words (`document`, `file`, `untitled`, `report`, `보고서`) without specific context

For each file, read its content and determine a descriptive name:

**Text-based files** (.txt, .md, .json, .csv, .html, .xml, .log, .yaml, .yml, .ini, .cfg, .conf, .toml, etc.):
- Read the **first 10% of the file** (by line count or byte size). Minimum: 5 lines. Maximum cap: 200 lines.
- Identify the main topic, purpose, or subject matter from the actual text content
- The proposed name must reflect what the text is about, not the file format

**Encoding detection** — if file content appears garbled or unreadable:
1. Try reading with common encodings in order: `utf-8` → `cp949` (Korean) → `shift_jis` (Japanese) → `gb2312` (Chinese) → `euc-kr` → `latin-1`
2. Use `file` command or `chardet`-style heuristics to detect encoding if available
3. Once readable text is obtained, proceed with content analysis
4. If no encoding produces readable text, mark the file as **unreadable**

**Documents** (.pdf, .docx, .xlsx, .pptx, .hwp, .hwpx):
- Extract text from the **first 10% of pages** (minimum: 1 page)
- Read the extracted text and identify the document's subject, title, or purpose
- For `.hwpx` files: these are ZIP archives containing XML — unzip and parse `Contents/section*.xml` to extract body text
- For `.hwp` files: use `hwp5txt` or `pyhwp` if available, otherwise try `strings` command with Korean encoding
- If text extraction fails, use metadata (title, author, subject) as fallback
- Only fall back to the existing name as a last resort, and flag it for user review with `⚠ content unreadable — name based on metadata/original`

**Images** (.jpg, .png, .gif, .webp, .svg, .jfif):
- Check EXIF data or embedded metadata if available
- If the agent has vision capability, **analyze the image content directly** and name based on what is depicted
- Otherwise, attempt **contextual inference** in this order:
  1. **Sibling files** — check other files in the same directory for topic/project clues
  2. **Timestamps** — compare creation/modification time with nearby files to find temporal clusters (files within minutes of each other likely share context)
  3. **File name fragments** — extract any meaningful parts from the original name (dates, sequence numbers, app names)
  4. **Parent directory name** — use the folder name as a category hint
- If none of the above yields a confident name, move to `_unknown/`

**Binary/unknown files**:
- Use file metadata and extension only
- Do not attempt to read binary content

**Unreadable files** — files that cannot be analyzed (corrupted, encrypted, unsupported format, all encoding attempts failed):
- Move to `<target-dir>/_unknown/` preserving the original file name
- Log the reason for failure (e.g., "encoding detection failed", "binary with no metadata")
- Include these in the dry-run preview so the user can override the decision

**Language handling** — apply the allowed languages setting from Step 1:
- Detect the language of the file content
- If the content language is not in the allowed list, translate the proposed name into the user's preferred allowed language
- Keep acronyms and proper nouns untranslated

**Naming rules** — refer to `references/naming-conventions.md` for detailed patterns. Key rules:
- Use `_` separator between attributes, `-` within multi-word attributes
- Keep names concise: 3-6 attributes maximum
- Preserve the original file extension
- Include a date prefix (`YYMMDD_`) when the file has a clear associated date
- Avoid generic names like `document`, `file`, `untitled`
- **Always generate a fresh name from content analysis** — never copy the original file name. Even if the original name contains relevant words, rebuild the name from scratch following the naming convention format

### Step 4: Generate Rename Map (Dry Run)

Build a rename map as JSON and present it to the user:

```
Current Name                    → Proposed Name
────────────────────────────────────────────────
IMG_20240315_142356.jpg         → 2024-03-15-sunset-beach-photo.jpg
document(3).pdf                 → quarterly-sales-report-q3.pdf
asdfgh.py                       → flask-user-auth-middleware.py
notes.txt                       → meeting-notes-product-roadmap.txt

⚠ Unreadable (→ _unknown/):
corrupted-data.bin              → _unknown/corrupted-data.bin (reason: binary, no metadata)
```

**Iterative approval loop** — repeat until the user explicitly approves:

1. Present the full rename map
2. The user may:
   - **Approve all** — proceed to Step 5
   - **Request changes** — e.g., "use Korean names", "make names shorter", "keep the date prefix on photos only", "don't move file X to _unknown"
   - **Edit specific entries** — modify individual proposed names
   - **Exclude files** — skip certain files
   - **Cancel** — abort the operation
3. If the user requests changes, revise the affected entries and present the updated map again
4. Go back to step 1 of this loop

Do NOT proceed to execution until the user gives explicit approval.

### Step 5: Execute Renames

After user approval:

1. Save the rollback map to a JSON file using the helper script:
   ```bash
   bash <skill-path>/scripts/rename-map.sh save <target-dir>
   ```
   This creates `<target-dir>/.file-organizer-map.json` for rollback purposes.
2. Rename files one by one
3. Report progress and any errors (e.g., name conflicts, permission issues)
4. On name conflict, append a numeric suffix: `report-q3-2.pdf`

### Step 6: Reorganize (full-organize mode only)

If the user chose `full-organize`, after renaming:

1. Analyze existing folder structure and file content categories
2. Propose a new folder structure — this may include:
   - **Creating new folders** for categories that don't exist yet
   - **Renaming existing folders** to more descriptive names (e.g., `misc/` → `reports/`, `새 폴더/` → `presentations/`)
   - **Merging folders** that contain similar content
   - **Removing empty folders** after files are moved out

   Example proposal:
   ```
   📁 Folder changes:
     [NEW]    documents/reports/
     [NEW]    images/screenshots/
     [RENAME] misc/ → data/csv/
     [RENAME] 새 폴더/ → presentations/
     [DELETE] old-stuff/ (empty after move)

   📁 Proposed structure:
   <target-dir>/
   ├── documents/
   │   ├── reports/
   │   └── notes/
   ├── images/
   │   ├── photos/
   │   └── screenshots/
   ├── data/
   │   ├── csv/
   │   └── json/
   └── other/
   ```

3. Folder naming follows the same conventions as file naming (see `references/naming-conventions.md`), using `kebab-case` and descriptive names
4. Present the proposed folder changes AND file moves to the user for approval
5. After approval, execute folder operations first (create/rename), then move files, then clean up empty directories
6. All folder rename/move operations are recorded in the rollback map for undo

### Step 7: Summary Report

Output a summary:
- Files renamed: count
- Files moved: count (if full-organize)
- Files skipped: count and reasons
- Rollback command: `bash <skill-path>/scripts/rename-map.sh rollback <target-dir>`

**Save change log** — write a Markdown file at `<target-dir>/.file-organizer-changelog.md` with:

```markdown
# File Organizer Change Log

- **Date**: YYYY-MM-DD HH:MM
- **Mode**: rename-only | full-organize
- **Target**: <target-dir>

## Changes (N files)

| # | Before | After |
|---|--------|-------|
| 1 | `old-name.pdf` | `new-name.pdf` |
| ... | ... | ... |

## Skipped (M files)

| # | File | Reason |
|---|------|--------|
| 1 | `some-file.py` | Source code (excluded) |
| 2 | `train/` (1523 files) | Dataset directory |
| ... | ... | ... |

## Moved to _unknown/ (K files)

| # | File | Reason |
|---|------|--------|
| 1 | `hash-image.webp` | Unreadable content |
| ... | ... | ... |
```

This file is overwritten on each run (previous logs are not preserved).

## Rollback

The rollback map (`.file-organizer-map.json`) records every rename/move operation for undo purposes. The user can manage it with these commands:

```bash
# Save current rename map (done automatically before execution, but can be triggered manually)
bash <skill-path>/scripts/rename-map.sh save <target-dir>

# Show the current rollback map contents
bash <skill-path>/scripts/rename-map.sh show <target-dir>

# Undo all renames/moves recorded in the map
bash <skill-path>/scripts/rename-map.sh rollback <target-dir>

# Clear the rollback map (after confirming changes are correct)
bash <skill-path>/scripts/rename-map.sh clear <target-dir>
```

The user can also ask the agent directly: "rollback the last file organization", "show me what was renamed", or "clear the rollback history".

## Safety Rules

- NEVER overwrite existing files — always check for conflicts first
- ALWAYS save the rollback map before making any changes
- ALWAYS show the dry-run preview and get explicit user approval before executing
- Skip files that are currently open or locked
- Preserve file permissions and timestamps when renaming/moving
