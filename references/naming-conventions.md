# Naming Conventions Reference

Rules for generating file names from content analysis. The agent should read this when deciding how to name files.

## Format

```
[YYMMDD_]<attribute1>_<attribute2>[_...<attributeN>].<ext>
```

- Attributes are separated by `_` (underscore)
- Words within a single attribute use `-` (hyphen) if needed: `IP-RD`, `AI-모델`
- Date format: `YYMMDD` (6-digit, no separators)
- 3–6 attributes maximum
- Original extension preserved

## Attribute Order

Attributes follow this priority order (include only what's relevant):

```
[date]_[person]_[org/project]_[topic/description]_[version].<ext>
```

Examples:
- `260309_봉기정_발표자료.pptx` → date + person + topic
- `마크애니_AI-신뢰성_심사자료_v3.pptx` → org + topic + description + version
- `250530_중기부_비식별화_연구개발계획서_v1.0.hwp` → date + org + topic + description + version
- `IITP_지능형홈_연구개발계획서.pdf` → org + project + description

## Preserve Rules

The following MUST be kept as-is from the original file name:

- **Person names** — `봉기정`, `남지인`, `조명돌`, `이동수`, etc.
- **Version strings** — `v1.0`, `v0.60`, `Rev 04`, `R3`, etc.
- **Status markers** — `(최종)`, `(초안)`, `(간소화)`, etc.
- **Acronyms & proper nouns** — `IITP`, `PRD`, `SOREST`, `AIHUB`, `AWS`, `CUDA`, `YOLOv8`, etc.

## Case Rules

- Default to lowercase
- Use uppercase when required for:
  - Acronyms: `AWS`, `IITP`, `PRD`, `CCTV`, `AI`
  - Proper nouns / product names: `MarkAny`, `YOLOv8`, `SageMaker`
  - Version/status markers: `Rev`, `(최종)`

## By File Type

| Type | Pattern | Example |
|------|---------|---------|
| Report/doc | `[date_][org_]topic[_version]` | `250530_중기부_비식별화_단계보고서_v1.0.hwp` |
| Meeting notes | `date_topic_회의[_version]` | `250327_마크애니_IP-RD_3차회의_v3.pptx` |
| Presentation | `[date_][person_]topic` | `250901_이동수_DeepCompression_기술세미나.pptx` |
| Certificate/form | `[person_]document-type` | `봉기정_학위증명서.pdf` |
| Photo | `date_subject` | `251001_KakaoTalk_photo.jpg` |
| Screenshot | `date_subject` | `250609_capture.jpg` |
| Data file | `dataset_description` | `AIHUB_train_dataset-paths.txt` |
| Config | `app_config-type` | `argos_v7.1.2_model-config.yaml` |
| Archive (zip) | `[date_]content-description` | `251028_쓰레기장_불연기합성_200장.zip` |
| Model weights | `model_version[_variant]` | `INDO_v0.0.0_best_dynamic.onnx` |

## Do Not Rename

- **Source code files**: `.py`, `.cpp`, `.c`, `.h`, `.js`, `.ts`, `.java`, `.go`, `.rs`, `.rb`, `.sh`, etc.
- **Executable/installer files**: `.exe`, `.msi` — keep original name exactly
- **CI/CD configs**: `Jenkinsfile*`, `Makefile`, `Dockerfile`

## Avoid

- Generic: `document`, `file`, `untitled`, `new`, `copy`, `temp`
- Camera defaults: `IMG_`, `DSC_`, `DCIM_`, `Screenshot_`
- Numbered copies: `report(1)`, `file - Copy`
- Parenthesized duplicate suffixes: `(1)`, `(2)` → replace with `_2`, `_3`

## Conflict Resolution

When a proposed name already exists, append a numeric suffix with `_`:

```
마크애니_CCTV_시험신청서.pdf
마크애니_CCTV_시험신청서_2.pdf
마크애니_CCTV_시험신청서_3.pdf
```

## Language

Default to English unless:
- The file content is primarily in another language
- The user explicitly requests a different language

When using non-English names, still use `_` between attributes with native characters.
