# ClassTrack GitHub Release Note & Changelog Guidelines

To ensure the in-app updater, GitHub Release pages, and changelog viewers parse and display release notes consistently without broken sections or dropped entries, all future releases must strictly follow this contract.

---

## 1. Release Title Specification

Format:
```text
ClassTrack v<major>.<minor>.<patch>[-<prerelease>.<build>] (<Key Feature Highlights / Theme>)
```

### Rules:
- Must begin with `ClassTrack v`.
- Version string must strictly follow Semantic Versioning (`1.0.0-alpha.8`, `1.0.0-beta.1`, `1.0.0`).
- The parenthesized theme must highlight 2–3 major improvements separated by commas or ampersands.
- Do not add emojis to the release title (emojis belong in the release body markdown).

### Examples:
- ✅ `ClassTrack v1.0.0-alpha.8 (GitHub Releases Engine, Calendar Slider & Subject Picker)`
- ✅ `ClassTrack v1.0.0-alpha.7 (Notifications Hub & Multi-Channel Fix)`
- ❌ `v1.0.0-alpha.8` (Missing `ClassTrack` prefix and highlight theme)
- ❌ `ClassTrack Update 8` (Missing semver version)

---

## 2. Release Tag Specification

Format:
```text
v<major>.<minor>.<patch>[-<prerelease>.<build>]
```

### Examples:
- ✅ `v1.0.0-alpha.8`
- ✅ `v1.0.0`
- ❌ `1.0.0-alpha.8` (Always include leading `v` for tags)

---

## 3. Release Body Markdown Specification

The release description on GitHub Releases and `CHANGELOG.md` must follow this structure:

```markdown
> [!WARNING]
> Mandatory update required for ... (Only include if release is mandatory)

### ✨ Features & Improvements
- **Feature Name**: Clear, concise explanation of the enhancement.
- **Another Feature**: Explanation of the second enhancement.

### 🧩 Bug Fixes & Polish
- **Fix Name**: Clear description of what bug was fixed and the resulting behavior.
- **Visual Polish**: Description of design, animation, or UX polish.
```

### Formatting Rules for Bullets:
1. **Always use Level-3 Headers (`### `)** with the standard emojis:
   - `### ✨ Features & Improvements` (or `### ✨ Features`)
   - `### 🧩 Bug Fixes & Polish` (or `### 🧩 Bug Fixes`)
   - Optional: `### 🛠️ Architecture & System`
2. **Every bullet must start with a bold title**:
   - Format: `- **Title**: Description text.`
   - This ensures the in-app updater can bold the title while rendering the description cleanly.
3. **Do not use raw HTML** (`<br>`, `<div>`, `<b>`). Use pure GitHub Flavored Markdown.
4. **No nested sub-bullets**: Keep all bullet points on a single flat level per section.

---

## 4. Parser Guarantees in `AppUpdateService`

The in-app updater implements:
1. **Section Header Detection**:
   - Lines starting with `### ` containing `Feature` or `✨` switch active parser mode to `FEATURES`.
   - Lines starting with `### ` containing `Fix` or `Bug` or `🧩` switch active parser mode to `FIXES`.
2. **Zero-Drop Guarantee**:
   - Any item that cannot be automatically classified into fixes or features will be categorized as improvements and rendered—never hidden or dropped.
3. **Clean Markdown Rendering**:
   - Strips raw markdown syntax (`**Title**: ` &rarr; styled Title + Description) to avoid displaying raw asterisks on the user's phone.
