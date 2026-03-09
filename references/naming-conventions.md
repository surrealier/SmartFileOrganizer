# Naming Conventions Reference

Rules for generating file names from content analysis. The agent should read this when deciding how to name files.

## Format

```
[YYYY-MM-DD-]<descriptive-name>.<ext>
```

- `kebab-case` always (lowercase, hyphens between words)
- 3–6 words for the descriptive part
- Date prefix only when the file has a clear associated date
- Original extension preserved

## By File Type

| Type | Pattern | Example |
|------|---------|---------|
| Report/doc | `topic-type` | `quarterly-sales-report-q3.pdf` |
| Meeting notes | `date-meeting-topic` | `2024-03-15-meeting-product-roadmap.md` |
| Code | `purpose-or-module` | `flask-user-auth-middleware.py` |
| Photo | `date-subject` | `2024-03-15-sunset-beach-photo.jpg` |
| Screenshot | `date-app-or-content` | `2024-06-01-vscode-debug-config.png` |
| Data file | `dataset-description` | `monthly-revenue-by-region.csv` |
| Config | `app-config-type` | `nginx-reverse-proxy-config.conf` |

## Avoid

- Generic: `document`, `file`, `untitled`, `new`, `copy`, `temp`
- Camera defaults: `IMG_`, `DSC_`, `DCIM_`, `Screenshot_`
- Numbered copies: `report(1)`, `file - Copy`
- All caps or mixed case in file names

## Conflict Resolution

When a proposed name already exists, append a numeric suffix:

```
quarterly-sales-report-q3.pdf
quarterly-sales-report-q3-2.pdf
quarterly-sales-report-q3-3.pdf
```

## Language

Default to English unless:
- The file content is primarily in another language
- The user explicitly requests a different language

When using non-English names, still use `kebab-case` with romanized or native characters as the user prefers.
