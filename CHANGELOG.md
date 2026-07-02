# Changelog

All notable changes to this project are documented here.  
Adheres to [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

---

## [1.0.5] - 2026-07-02
### Added & Improved
- **Manual Drag-to-Reorder**: Replaced up/down buttons with a sleek drag handle grip indicator at the edge of each snippet and group card. Smoothly drag and drop items vertically to arrange custom order.
- **Versatile Sorting Modes**:
  - **Manual Order**: Custom ordering via drag handle.
  - **Alphabetical Sorting**: Sort snippets and groups by title (`Title (A-Z)` and `Title (Z-A)`).
  - **Date Created Sorting**: Sort items by creation timestamp (`Date Created (Newest)` and `Date Created (Oldest)`). Automatically falls back to sequential IDs for legacy items.
- **Hierarchical Move Dialog**: Added a dedicated "Move" button on snippets and groups, opening a hierarchical dropdown selector to re-parent items across groups.
- **Creation Timestamps & Frontmatter Order**: Stored creation date and custom order position in JSON and Markdown YAML frontmatter (`created: <timestamp>`, `order: <index>`).

---

## [1.0.4] - 2025-12-19
### Added
- **Markdown Storage Format**: New storage option that saves snippets as individual `.md` files with YAML frontmatter
  - Groups become folders in the directory structure
  - Snippets become markdown files with title and code in frontmatter
  - Ungrouped snippets are stored in `_ungrouped/` folder
- **Storage Format Selection**: Choose between JSON (single file) or Markdown (directory) in widget settings
- **Folder Picker**: When using Markdown format, browse for a folder instead of a file
- **Enhanced Import/Export**: Import and export dialogs now let you choose between JSON or Markdown formats
- **Markdown Import**: Import snippets from existing markdown directory structures

---

## [1.0.3] - 2025-12-12
### Added / Improved
- Custom Storage File: Store/load snippets from a custom JSON file path. So multiple instances of the plasmoid can share the same file. Useful for user's with multiple monitors who used multiple instances of the plasmoid. (Community Suggestion.)
- Configuration UI improvements

---

## [1.0.2] - 2025-12-05
### Added
- Import/Export: Ability to import/export saved snippets as a JSON file
- Group management functionality

---

## [1.0.1] - 2025-10-11
### Added
- Customizable Font Size: Adjust font size for better readability with zoom controls
- Pin Window: Keep the widget window open while working
- Search & Filter: Quickly find snippets using the built-in search functionality

---

## [1.0.0] - 2025-10-11
### Added
- Initial Release
- Store Code Snippets: Save your frequently used code snippets with custom titles
- One-Click Copy: Copy snippets to clipboard with a single click
- Edit & Delete: Modify existing snippets or remove ones you no longer need
- Persistent Storage: Snippets are automatically saved in Plasma configuration
- Native Integration: Seamlessly integrates with KDE Plasma theme