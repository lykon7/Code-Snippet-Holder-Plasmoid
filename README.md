# Code Snippet Holder Plasmoid

A KDE Plasma widget that allows you to store, organize, and quickly copy code snippets (Not just code snippets, but SQL queries, other notes, configs, etc... ) directly from your desktop panel.

![License](https://img.shields.io/badge/license-GPL--2.0%2B-blue.svg)
![KDE Plasma](https://img.shields.io/badge/KDE%20Plasma-6.0%2B-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.6-green.svg)


## Screenshots

<p align="center">
  <img src="assets/Screenshot_1.png" width="45%" />
  <img src="assets/Screenshot_2.png" width="45%" />
</p>

## Features

- **Store Code Snippets**: Save your frequently used code snippets with custom titles
- **Search & Filter**: Quickly find snippets using the built-in search functionality
- **Versatile Sorting & Reordering**:
  - **Manual Order**: Drag and drop snippets or groups using the edge drag handle
  - **Alphabetical**: Sort items by title (A-Z or Z-A)
  - **Date Created**: Sort by creation date (Newest or Oldest first)
- **Hierarchical Groups**: Organize snippets into nested folders/groups, and easily re-parent snippets across groups using the Move dialog
- **Collapsible Snippet Cards**: Hide or show individual code display boxes via title click/arrow toggle, or use global toolbar buttons to collapse/expand all snippets at once
- **Interactive Vertical Resizing**: Drag the bottom grip bar of any open snippet vertically to customize its code box height (50px to 800px), or double-click to reset to auto-fit
- **One-Click Copy**: Copy snippets to clipboard with a single click
- **Edit & Delete**: Modify existing snippets or remove ones you no longer need
- **Customizable Font Size**: Adjust font size for better readability with zoom controls
- **Pin Window**: Keep the widget window open while working
- **Persistent Storage**: Snippets are automatically saved in Plasma configuration
- **Custom Storage Location**: Optionally store and load your snippets from a custom file or folder
- **Multiple Storage Formats**:
  - **JSON**: Single file storage (default)
  - **Markdown**: Directory-based storage where groups become folders and snippets become individual `.md` files with YAML frontmatter
- **Import/Export**: Import or export snippets in JSON or Markdown format
- **Native Integration**: Seamlessly integrates with KDE Plasma theme

## Installation

### Method 1: KDE Plasma Store

1. Open your KDE desktop and right-click on the panel.
2. Select "Add Widgets...".
3. Search for "Code Snippet Holder" in the widget list.
4. If not found, click "Get New Widgets" and search for "Code Snippet Holder".
5. Install directly from the KDE Plasma Store:
   [Code Snippet Holder on KDE Store](https://www.pling.com/p/2333778/)
6. Add the widget to your panel as usual.

### Method 2: Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/LoneWolf728/Code-Snippet-Holder-Plasmoid.git
   cd Code-Snippet-Holder-Plasmoid
   ```

2. Install the plasmoid:
   ```bash
   kpackagetool6 --install code-snippet-holder/package --type Plasma/Applet
   ```

3. Restart Plasmashell:
   ```bash
   kquitapp6 plasmashell && kstart plasmashell
   ```

4. Add the widget to your panel:
   - Right-click on your panel
   - Select "Add Widgets..."
   - Search for "Code Snippets"
   - Drag it to your panel

## Usage

### Adding Snippets

1. Click the Code Snippets icon in your panel
2. Click the "Add" button
3. Enter a title and your code snippet
4. Click "Save"

### Managing Snippets

- **Search**: Use the search bar to filter snippets by title or content
- **Sort & Reorder**: Select sorting mode (Manual Order, Title A-Z/Z-A, or Date Created) from the dropdown next to the search bar. In Manual Order mode, drag items via their edge grip handle to reorder
- **Collapse & Expand**: Click the arrow button or title heading on any snippet to collapse or expand it. Use the "Collapse All" and "Expand All" toolbar buttons for quick mass layout toggling
- **Resize Height**: Drag the bottom handle of any expanded snippet card vertically to customize its display height, or double-click the handle to reset to auto-fit
- **Move**: Click the "Move" button on any snippet or folder to move it to another group
- **Copy**: Click the "Copy" button to copy code to clipboard
- **Edit**: Click "Edit" to modify existing snippets
- **Delete**: Click "Delete" to remove snippets
- **Font Size**: Use the +/- buttons to adjust text size
- **Pin**: Click the pin button to keep the window open

### Keyboard Shortcuts

- The search field supports standard text navigation
- Use Tab to navigate between interface elements

## Configuration

You can configure the widget via its settings dialog:

- **Storage Format**: Choose between JSON (single file) or Markdown (directory structure)
- **Custom Storage Location**: 
  - For JSON: Set a custom file path to store snippets
  - For Markdown: Set a custom folder path where groups become subfolders and snippets become `.md` files
- **Font Size**: Stored in `fontSize` configuration key (range: 6-24)
- **Auto-save**: All changes are automatically persisted

### Markdown Storage Format

When using Markdown format, snippets are stored as individual files with YAML frontmatter:

```markdown
---
title: Example Snippet
id: 1
collapsed: false
customHeight: 250
---

```
console.log('Hello World!');
```
```

Directory structure example:
```
snippets_folder/
├── _ungrouped/
│   └── Ungrouped Snippet.md
└── JavaScript/
    ├── Example Snippet.md
    └── Nested Group/
        └── Another Snippet.md
```

## Technical Details

### Requirements

- KDE Plasma 6.0 or higher
- Qt 6.0 or higher
- QML modules: QtQuick, QtQuick.Layouts, QtQuick.Controls

### Architecture

- **Main Component**: `main.qml` - Core widget logic and UI
- **Configuration**: `main.xml` - Configuration schema
- **Metadata**: `metadata.json` - Widget information and metadata

### File Structure

```
code-snippet-holder/
└── package/
    ├── metadata.json          # Widget metadata and information
    └── contents/
        ├── config/
        │   └── main.xml       # Configuration schema
        └── ui/
            └── main.qml       # Main widget interface
```

## Troubleshooting

### Widget Not Appearing

If the widget doesn't appear after installation:

1. Restart Plasma:
   ```bash
   killall plasmashell
   plasmashell &
   ```

2. Check installation:
   ```bash
   kpackagetool6 --list --type Plasma/Applet | grep codesnippets
   ```

### Removing the Widget

To uninstall:
```bash
kpackagetool6 --remove org.kde.plasma.codesnippets --type Plasma/Applet
```

### Configuration Issues

If snippets aren't being saved:
1. Check Plasma configuration permissions
2. Try removing and re-adding the widget
3. Check system logs for any error messages

## License

This project is licensed under the GPL-2.0+ License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- KDE Plasma development team for the excellent framework
- Qt project for the QML framework
- Contributors and users who provide feedback and suggestions

## Changelog
See [CHANGELOG.md](CHANGELOG.md)

---

**Note**: This widget is designed for KDE Plasma 6.0+. For older Plasma versions, you may need to modify the QML imports and API calls accordingly.
