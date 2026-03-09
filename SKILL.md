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
3. **Language** — language for new file names (default: match original or English)
4. **File filter** — specific extensions to include/exclude (default: all files)
5. **Max depth** — how deep to recurse into subdirectories (default: unlimited)

If the user provides a directory without specifying other options, use defaults and proceed.

### Step 2: Scan and Inventory

1. List all files recursively in the target directory
2. Skip hidden files/directories (starting with `.`) and common ignore patterns (`node_modules`, `.git`, `__pycache__`, etc.)
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

For each file, determine a descriptive name based on its content:

**Text-based files** (.txt, .md, .py, .js, .json, .csv, .html, .xml, etc.):
- Read only the **first 10% of the file** (by line count or byte size, whichever is easier to measure). Minimum: 5 lines. Maximum cap: 200 lines.
- Identify the main topic, purpose, or function from this excerpt only

**Encoding detection** — if file content appears garbled or unreadable:
1. Try reading with common encodings in order: `utf-8` → `cp949` (Korean) → `shift_jis` (Japanese) → `gb2312` (Chinese) → `euc-kr` → `latin-1`
2. Use `file` command or `chardet`-style heuristics to detect encoding if available
3. Once readable text is obtained, proceed with content analysis
4. If no encoding produces readable text, mark the file as **unreadable**

**Documents** (.pdf, .docx, .xlsx, .pptx, .hwp, .hwpx):
- Extract text from the **first 10% of pages** (minimum: 1 page)
- If not readable, use metadata (title, author, subject) or fall back to existing name

**Images** (.jpg, .png, .gif, .webp, .svg, .jfif):
- Check EXIF data or embedded metadata if available
- If the agent has vision capability, analyze the image content
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

**Naming rules** — refer to `references/naming-conventions.md` for detailed patterns. Key rules:
- Use `kebab-case` for all file names
- Keep names concise: 3-6 words maximum
- Preserve the original file extension
- Include a date prefix (`YYYY-MM-DD-`) when the file has a clear associated date
- Avoid generic names like `document`, `file`, `untitled`

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

1. Propose a folder structure based on file types and content categories:

```
<target-dir>/
├── documents/
│   ├── reports/
│   └── notes/
├── code/
│   ├── python/
│   └── javascript/
├── images/
│   ├── photos/
│   └── screenshots/
├── data/
│   ├── csv/
│   └── json/
└── other/
```

2. Present the proposed moves to the user for approval
3. After approval, move files and clean up empty directories

### Step 7: Summary Report

Output a summary:
- Files renamed: count
- Files moved: count (if full-organize)
- Files skipped: count and reasons
- Rollback command: `bash <skill-path>/scripts/rename-map.sh rollback <target-dir>`

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
