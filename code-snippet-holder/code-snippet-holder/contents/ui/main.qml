import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt.labs.platform as Platform
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    // This makes it show as an icon in the panel
    preferredRepresentation: compactRepresentation
    
    // Store groups and snippets in plasmoid configuration
    property var groups: []
    property var snippets: []
    property bool isPinned: false
    property int fontSize: 10
    property var currentPath: [] // Stack to track navigation path
    property int currentGroupId: -1 // -1 means root level
    property int pathDepth: 0 // Track navigation depth for UI reactivity
    
    // Control whether clicking outside closes the popup
    hideOnWindowDeactivate: !isPinned
    
    Component.onCompleted: {
        loadData()
        fontSize = plasmoid.configuration.fontSize || 10
    }
    
    onFontSizeChanged: {
        plasmoid.configuration.fontSize = fontSize
    }

    Connections {
        target: plasmoid.configuration
        function onCustomFilePathChanged() {
            loadData()
        }
        function onStorageFormatChanged() {
            loadData()
        }
    }
    
    function loadData() {
        var customPath = plasmoid.configuration.customFilePath
        var storageFormat = plasmoid.configuration.storageFormat || "json"
        console.log("Loading data. Custom path:", customPath, "Format:", storageFormat)
        
        if (customPath && customPath.length > 0) {
            if (storageFormat === "markdown") {
                // Load from markdown directory structure
                loadFromMarkdown(customPath)
            } else {
                // Load from JSON file using executable data source
                var cmd = "cat '" + customPath.replace(/'/g, "'\\''" ) + "'"
                executable.isLoadingCustom = true
                executable.isLoadingMarkdown = false
                executable.connectSource(cmd)
            }
        } else {
            // Load groups from config
            var savedGroups = plasmoid.configuration.groupsData
            if (savedGroups) {
                try {
                    groups = JSON.parse(savedGroups)
                } catch (e) {
                    groups = []
                }
            }
            
            // Load snippets from config
            var savedSnippets = plasmoid.configuration.snippetsData
            if (savedSnippets) {
                try {
                    snippets = JSON.parse(savedSnippets)
                } catch (e) {
                    snippets = []
                }
            }
            
            // Add example data if empty
            if (groups.length === 0 && snippets.length === 0) {
                groups = [
                    {
                        id: 1,
                        name: "JavaScript",
                        parentId: -1
                    }
                ]
                snippets = [
                    {
                        id: 1,
                        title: "Example Snippet",
                        code: "console.log('Hello World!');",
                        groupId: 1
                    },
                    {
                        id: 2,
                        title: "Ungrouped Snippet",
                        code: "// This snippet has no group",
                        groupId: -1
                    }
                ]
                saveData()
            }
            
            refreshView()
        }
    }
    
    function saveData() {
        var customPath = plasmoid.configuration.customFilePath
        var storageFormat = plasmoid.configuration.storageFormat || "json"
        
        if (customPath && customPath.length > 0) {
            if (storageFormat === "markdown") {
                // Save as markdown directory structure
                saveAsMarkdown(customPath)
            } else {
                // Save as JSON file
                var exportData = {
                    version: "1.0",
                    groups: groups,
                    snippets: snippets
                }
                var jsonData = JSON.stringify(exportData, null, 2)
                
                // Convert to path if it's a URL (just in case)
                var filePath = customPath.toString().replace(/^file:\/\//, '')
                
                // Escape for shell
                var escapedData = jsonData.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`')
                
                var cmd = 'printf "%s" "' + escapedData + '" > "' + filePath + '"'
                executable.connectSource(cmd)
            }
        } else {
            // Save to config
            plasmoid.configuration.groupsData = JSON.stringify(groups)
            plasmoid.configuration.snippetsData = JSON.stringify(snippets)
        }
    }
    
    function refreshView() {
        displayModel.clear()
        
        var searchText = ""
        if (typeof searchField !== 'undefined' && searchField) {
            searchText = searchField.text.toLowerCase()
        }
        
        // If searching, show all matching items
        if (searchText !== "") {
            // Add matching groups
            for (var i = 0; i < groups.length; i++) {
                var group = groups[i]
                if (group.name.toLowerCase().includes(searchText)) {
                    displayModel.append({
                        itemType: "group",
                        itemId: group.id,
                        title: group.name,
                        code: "",
                        groupId: group.parentId
                    })
                }
            }
            
            // Add matching snippets
            for (var j = 0; j < snippets.length; j++) {
                var snippet = snippets[j]
                if (snippet.title.toLowerCase().includes(searchText) || 
                    snippet.code.toLowerCase().includes(searchText)) {
                    displayModel.append({
                        itemType: "snippet",
                        itemId: snippet.id,
                        title: snippet.title,
                        code: snippet.code,
                        groupId: snippet.groupId
                    })
                }
            }
        } else {
            // Show items at current level: groups first, then snippets
            // Add groups at current level
            for (var k = 0; k < groups.length; k++) {
                var grp = groups[k]
                if (grp.parentId === currentGroupId) {
                    displayModel.append({
                        itemType: "group",
                        itemId: grp.id,
                        title: grp.name,
                        code: "",
                        groupId: grp.parentId
                    })
                }
            }
            
            // Add snippets at current level
            for (var l = 0; l < snippets.length; l++) {
                var snip = snippets[l]
                if (snip.groupId === currentGroupId) {
                    displayModel.append({
                        itemType: "snippet",
                        itemId: snip.id,
                        title: snip.title,
                        code: snip.code,
                        groupId: snip.groupId
                    })
                }
            }
        }
    }
    
    function getNextId(array) {
        var maxId = 0
        for (var i = 0; i < array.length; i++) {
            if (array[i].id > maxId) {
                maxId = array[i].id
            }
        }
        return maxId + 1
    }
    
    function navigateToGroup(groupId, groupName) {
        currentPath.push({id: currentGroupId, name: getCurrentGroupName()})
        currentGroupId = groupId
        pathDepth = currentPath.length
        refreshView()
    }
    
    function navigateBack() {
        if (currentPath.length > 0) {
            var prev = currentPath.pop()
            currentGroupId = prev.id
            pathDepth = currentPath.length
            refreshView()
        }
    }
    
    function getCurrentGroupName() {
        if (currentGroupId === -1) {
            return "Root"
        }
        for (var i = 0; i < groups.length; i++) {
            if (groups[i].id === currentGroupId) {
                return groups[i].name
            }
        }
        return "Unknown"
    }
    
    function findGroupById(groupId) {
        for (var i = 0; i < groups.length; i++) {
            if (groups[i].id === groupId) {
                return i
            }
        }
        return -1
    }
    
    function findSnippetById(snippetId) {
        for (var i = 0; i < snippets.length; i++) {
            if (snippets[i].id === snippetId) {
                return i
            }
        }
        return -1
    }
    
    // Helper function to sanitize filenames
    function sanitizeFilename(name) {
        // Replace invalid characters with underscores
        return name.replace(/[<>:"/\\|?*]/g, '_').replace(/\s+/g, ' ').trim()
    }
    
    // Helper function to build group path
    function getGroupPath(groupId, basePath) {
        if (groupId === -1) {
            return basePath + "/_ungrouped"
        }
        
        var pathParts = []
        var currentId = groupId
        
        while (currentId !== -1) {
            var found = false
            for (var i = 0; i < groups.length; i++) {
                if (groups[i].id === currentId) {
                    pathParts.unshift(sanitizeFilename(groups[i].name))
                    currentId = groups[i].parentId
                    found = true
                    break
                }
            }
            if (!found) break
        }
        
        return basePath + "/" + pathParts.join("/")
    }
    
    // Save data as markdown directory structure
    function saveAsMarkdown(basePath) {
        basePath = basePath.toString().replace(/^file:\/\//, '').replace(/\/$/, '')
        
        // Build the complete save script
        var script = "#!/bin/bash\n"
        script += "set -e\n"
        script += "BASE_PATH='" + basePath.replace(/'/g, "'\\''") + "'\n"
        
        // Create base directory
        script += "mkdir -p \"$BASE_PATH\"\n"
        
        // Track which directories we need
        var dirsNeeded = {}
        dirsNeeded[basePath + "/_ungrouped"] = true
        
        // Create directories for all groups
        for (var i = 0; i < groups.length; i++) {
            var group = groups[i]
            var groupPath = getGroupPath(group.id, basePath)
            dirsNeeded[groupPath] = true
        }
        
        // Create all directories
        for (var dir in dirsNeeded) {
            script += "mkdir -p '" + dir.replace(/'/g, "'\\''") + "'\n"
        }
        
        // Write each snippet as a markdown file
        for (var j = 0; j < snippets.length; j++) {
            var snippet = snippets[j]
            var snippetPath = getGroupPath(snippet.groupId, basePath)
            var filename = sanitizeFilename(snippet.title) + ".md"
            var fullPath = snippetPath + "/" + filename
            
            // Create markdown content with frontmatter
            var mdContent = "---\n"
            mdContent += "title: " + snippet.title.replace(/:/g, "\\:") + "\n"
            mdContent += "id: " + snippet.id + "\n"
            mdContent += "---\n\n"
            mdContent += "```\n"
            mdContent += snippet.code + "\n"
            mdContent += "```\n"
            
            // Escape for shell
            var escapedContent = mdContent.replace(/\\/g, '\\\\').replace(/'/g, "'\\''").replace(/\$/g, '\\$')
            
            script += "cat > '" + fullPath.replace(/'/g, "'\\''") + "' << 'SNIPPET_EOF'\n"
            script += mdContent
            script += "SNIPPET_EOF\n"
        }
        
        // Execute the script
        var cmd = "bash -c '" + script.replace(/'/g, "'\\''") + "'"
        executable.connectSource(cmd)
    }
    
    // Load data from markdown directory structure
    function loadFromMarkdown(basePath) {
        basePath = basePath.toString().replace(/^file:\/\//, '').replace(/\/$/, '')
        
        // Use find to get all .md files and directory structure
        var cmd = "find '" + basePath.replace(/'/g, "'\\''") + "' -type f -name '*.md' -exec sh -c 'echo \"FILE_START\"; echo \"{}\" ; echo \"FILE_CONTENT_START\"; cat \"{}\" ; echo \"FILE_CONTENT_END\"' \\;"
        
        executable.isLoadingMarkdown = true
        executable.isLoadingCustom = false
        executable.markdownBasePath = basePath
        executable.connectSource(cmd)
    }
    
    // Parse markdown files output and reconstruct data
    function parseMarkdownOutput(output, basePath) {
        var newGroups = []
        var newSnippets = []
        var groupIdMap = {} // path -> id
        var nextGroupId = 1
        var nextSnippetId = 1
        
        // Parse each file
        var files = output.split("FILE_START")
        
        for (var i = 1; i < files.length; i++) {
            var fileBlock = files[i]
            var pathMatch = fileBlock.indexOf("FILE_CONTENT_START")
            if (pathMatch === -1) continue
            
            var filePath = fileBlock.substring(0, pathMatch).trim()
            var contentStart = pathMatch + "FILE_CONTENT_START".length
            var contentEnd = fileBlock.indexOf("FILE_CONTENT_END")
            if (contentEnd === -1) contentEnd = fileBlock.length
            
            var content = fileBlock.substring(contentStart, contentEnd).trim()
            
            // Get relative path from base
            var relativePath = filePath.replace(basePath + "/", "")
            var pathParts = relativePath.split("/")
            var filename = pathParts.pop() // Remove filename
            
            // Create groups for path parts
            var parentId = -1
            var currentPath = basePath
            
            for (var p = 0; p < pathParts.length; p++) {
                var part = pathParts[p]
                currentPath += "/" + part
                
                // Skip _ungrouped folder
                if (part === "_ungrouped") {
                    parentId = -1
                    continue
                }
                
                if (!groupIdMap.hasOwnProperty(currentPath)) {
                    var newGroupId = nextGroupId++
                    groupIdMap[currentPath] = newGroupId
                    newGroups.push({
                        id: newGroupId,
                        name: part,
                        parentId: parentId
                    })
                }
                parentId = groupIdMap[currentPath]
            }
            
            // Parse markdown content
            var title = filename.replace(/\.md$/, '')
            var code = ""
            var snippetId = nextSnippetId++
            
            // Parse frontmatter
            if (content.startsWith("---")) {
                var frontmatterEnd = content.indexOf("---", 3)
                if (frontmatterEnd !== -1) {
                    var frontmatter = content.substring(3, frontmatterEnd)
                    var lines = frontmatter.split("\n")
                    for (var l = 0; l < lines.length; l++) {
                        var line = lines[l].trim()
                        if (line.startsWith("title:")) {
                            title = line.substring(6).trim().replace(/^["']|["']$/g, '').replace(/\\:/g, ':')
                        }
                        if (line.startsWith("id:")) {
                            var parsedId = parseInt(line.substring(3).trim())
                            if (!isNaN(parsedId)) {
                                snippetId = parsedId
                                if (parsedId >= nextSnippetId) nextSnippetId = parsedId + 1
                            }
                        }
                    }
                    content = content.substring(frontmatterEnd + 3).trim()
                }
            }
            
            // Extract code from code block
            var codeBlockStart = content.indexOf("```")
            if (codeBlockStart !== -1) {
                var codeStart = content.indexOf("\n", codeBlockStart) + 1
                var codeEnd = content.indexOf("```", codeStart)
                if (codeEnd === -1) codeEnd = content.length
                code = content.substring(codeStart, codeEnd).trim()
            } else {
                code = content
            }
            
            newSnippets.push({
                id: snippetId,
                title: title,
                code: code,
                groupId: parentId
            })
        }
        
        groups = newGroups
        snippets = newSnippets
        refreshView()
        
        if (newSnippets.length > 0 || newGroups.length > 0) {
            showNotification("Loaded " + newGroups.length + " groups and " + newSnippets.length + " snippets")
        }
    }
    
    // DataSource for executing shell commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        // Flag to distinguish import vs export vs loading operations
        property bool isImporting: false
        property bool isImportingMarkdown: false
        property bool isLoadingCustom: false
        property bool isLoadingMarkdown: false
        property string markdownBasePath: ""

        
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            var exitCode = data["exit code"]
            
            disconnectSource(sourceName)
            
            if (isImporting) {
                isImporting = false
                if (exitCode === 0 && stdout) {
                    try {
                        var importedData = JSON.parse(stdout)
                        if (importedData.groups && importedData.snippets) {
                            // Merge imported data with existing data instead of replacing
                            var maxGroupId = getNextId(groups) - 1
                            var maxSnippetId = getNextId(snippets) - 1
                            
                            // Create a map of old group IDs to new group IDs
                            var groupIdMap = {}
                            
                            // Import groups with new IDs
                            for (var i = 0; i < importedData.groups.length; i++) {
                                var importedGroup = importedData.groups[i]
                                var oldId = importedGroup.id
                                var newId = ++maxGroupId
                                groupIdMap[oldId] = newId
                                
                                groups.push({
                                    id: newId,
                                    name: importedGroup.name,
                                    parentId: importedGroup.parentId // Will be remapped below
                                })
                            }
                            
                            // Remap parent IDs for imported groups
                            for (var j = 0; j < groups.length; j++) {
                                var grp = groups[j]
                                if (groupIdMap.hasOwnProperty(grp.parentId)) {
                                    grp.parentId = groupIdMap[grp.parentId]
                                }
                            }
                            
                            // Import snippets with new IDs and remapped group IDs
                            for (var k = 0; k < importedData.snippets.length; k++) {
                                var importedSnippet = importedData.snippets[k]
                                var newSnippetId = ++maxSnippetId
                                var newGroupId = importedSnippet.groupId
                                
                                // Remap groupId if it was an imported group
                                if (groupIdMap.hasOwnProperty(newGroupId)) {
                                    newGroupId = groupIdMap[newGroupId]
                                }
                                
                                snippets.push({
                                    id: newSnippetId,
                                    title: importedSnippet.title,
                                    code: importedSnippet.code,
                                    groupId: newGroupId
                                })
                            }
                            
                            saveData()
                            refreshView()
                            var importedCount = importedData.groups.length + importedData.snippets.length
                            showNotification("Imported " + importedCount + " items!")
                        } else {
                            showNotification("Invalid file format!")
                        }
                    } catch (e) {
                        showNotification("Error parsing file: " + e)
                    }
                } else {
                    showNotification("Failed to read file: " + (stderr || "No data"))
                }
        } else if (isLoadingMarkdown) {
                isLoadingMarkdown = false
                if (exitCode === 0 && stdout) {
                    parseMarkdownOutput(stdout, markdownBasePath)
                } else if (exitCode !== 0) {
                    console.warn("Failed to load markdown directory: " + stderr)
                    // Initialize empty if directory doesn't exist
                    groups = []
                    snippets = []
                    refreshView()
                }
            } else if (isImportingMarkdown) {
                isImportingMarkdown = false
                if (exitCode === 0 && stdout) {
                    // Parse the markdown and merge with existing data
                    var importedGroups = []
                    var importedSnippets = []
                    var groupIdMap = {}
                    var nextGroupId = 1
                    var nextSnippetId = 1
                    
                    // Parse each file (similar to parseMarkdownOutput)
                    var files = stdout.split("FILE_START")
                    
                    for (var i = 1; i < files.length; i++) {
                        var fileBlock = files[i]
                        var pathMatch = fileBlock.indexOf("FILE_CONTENT_START")
                        if (pathMatch === -1) continue
                        
                        var filePath = fileBlock.substring(0, pathMatch).trim()
                        var contentStart = pathMatch + "FILE_CONTENT_START".length
                        var contentEnd = fileBlock.indexOf("FILE_CONTENT_END")
                        if (contentEnd === -1) contentEnd = fileBlock.length
                        
                        var content = fileBlock.substring(contentStart, contentEnd).trim()
                        
                        // Get relative path from base
                        var relativePath = filePath.replace(markdownBasePath + "/", "")
                        var pathParts = relativePath.split("/")
                        var filename = pathParts.pop()
                        
                        // Create groups for path parts
                        var parentId = -1
                        var currentPath = markdownBasePath
                        
                        for (var p = 0; p < pathParts.length; p++) {
                            var part = pathParts[p]
                            currentPath += "/" + part
                            
                            if (part === "_ungrouped") {
                                parentId = -1
                                continue
                            }
                            
                            if (!groupIdMap.hasOwnProperty(currentPath)) {
                                var newGroupId = nextGroupId++
                                groupIdMap[currentPath] = newGroupId
                                importedGroups.push({
                                    id: newGroupId,
                                    name: part,
                                    parentId: parentId
                                })
                            }
                            parentId = groupIdMap[currentPath]
                        }
                        
                        // Parse markdown content
                        var title = filename.replace(/\.md$/, '')
                        var code = ""
                        var snippetId = nextSnippetId++
                        
                        if (content.startsWith("---")) {
                            var frontmatterEnd = content.indexOf("---", 3)
                            if (frontmatterEnd !== -1) {
                                var frontmatter = content.substring(3, frontmatterEnd)
                                var lines = frontmatter.split("\n")
                                for (var l = 0; l < lines.length; l++) {
                                    var line = lines[l].trim()
                                    if (line.startsWith("title:")) {
                                        title = line.substring(6).trim().replace(/^["']|["']$/g, '').replace(/\\:/g, ':')
                                    }
                                }
                                content = content.substring(frontmatterEnd + 3).trim()
                            }
                        }
                        
                        var codeBlockStart = content.indexOf("```")
                        if (codeBlockStart !== -1) {
                            var codeStart = content.indexOf("\n", codeBlockStart) + 1
                            var codeEnd = content.indexOf("```", codeStart)
                            if (codeEnd === -1) codeEnd = content.length
                            code = content.substring(codeStart, codeEnd).trim()
                        } else {
                            code = content
                        }
                        
                        importedSnippets.push({
                            id: snippetId,
                            title: title,
                            code: code,
                            groupId: parentId
                        })
                    }
                    
                    // Merge with existing data (remap IDs to avoid conflicts)
                    var maxGroupId = getNextId(groups) - 1
                    var maxSnippetId = getNextId(snippets) - 1
                    var mergeGroupIdMap = {}
                    
                    for (var gi = 0; gi < importedGroups.length; gi++) {
                        var importedGrp = importedGroups[gi]
                        var oldGrpId = importedGrp.id
                        var newGrpId = ++maxGroupId
                        mergeGroupIdMap[oldGrpId] = newGrpId
                        
                        groups.push({
                            id: newGrpId,
                            name: importedGrp.name,
                            parentId: importedGrp.parentId
                        })
                    }
                    
                    // Remap parent IDs
                    for (var gj = 0; gj < groups.length; gj++) {
                        if (mergeGroupIdMap.hasOwnProperty(groups[gj].parentId)) {
                            groups[gj].parentId = mergeGroupIdMap[groups[gj].parentId]
                        }
                    }
                    
                    for (var si = 0; si < importedSnippets.length; si++) {
                        var importedSnip = importedSnippets[si]
                        var newSnipId = ++maxSnippetId
                        var newGrpIdForSnip = importedSnip.groupId
                        
                        if (mergeGroupIdMap.hasOwnProperty(newGrpIdForSnip)) {
                            newGrpIdForSnip = mergeGroupIdMap[newGrpIdForSnip]
                        }
                        
                        snippets.push({
                            id: newSnipId,
                            title: importedSnip.title,
                            code: importedSnip.code,
                            groupId: newGrpIdForSnip
                        })
                    }
                    
                    saveData()
                    refreshView()
                    showNotification("Imported " + importedGroups.length + " groups and " + importedSnippets.length + " snippets!")
                } else {
                    showNotification("Failed to import markdown: " + (stderr || "No files found"))
                }
            } else if (isLoadingCustom) {
                 isLoadingCustom = false
                 if (exitCode === 0 && stdout) {
                     try {
                         var data = JSON.parse(stdout)
                         // Support both formats: raw arrays check or wrapped object
                         if (data.groups && data.snippets) {
                             groups = data.groups
                             snippets = data.snippets
                         } else {
                             // Maybe it is a direct file dump? Assuming standard format
                             // Fallback attempts could go here
                             console.warn("Loaded file format unrecognized, expecting {groups: [], snippets: []}")
                         }
                         refreshView()
                         showNotification("Loaded data from file")
                     } catch (e) {
                         showNotification("Error parsing custom file: " + e)
                     }
                 } else {
                    // Start fresh if file doesn't exist or error?
                    // Ideally we might want to create it if empty
                    console.warn("Failed to load custom file" + stderr)
                 }
            } else {
                // Export or Save operation
                if (exitCode === 0) {
                    // If it was a save operation, maybe show nothing to avoid spam
                     console.log("Data saved successfully")
                } else {
                    showNotification("Save/Export failed: " + (stderr || "Unknown error"))
                }
            }
        }
    }
    
    function exportData(fileUrl) {
        var exportData = {
            version: "1.0",
            groups: groups,
            snippets: snippets
        }
        var jsonData = JSON.stringify(exportData, null, 2)
        
        // Convert file:// URL to path
        var filePath = fileUrl.toString().replace(/^file:\/\//, '')
        
        // Escape the JSON data properly for shell
        var escapedData = jsonData.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`')
        
        // Use printf to handle special characters better than echo
        var cmd = 'printf "%s" "' + escapedData + '" > "' + filePath + '"'
        
        executable.connectSource(cmd)
        showNotification("Exported to JSON file")
    }
    
    function exportDataAsMarkdown(folderUrl) {
        // Export as markdown directory structure
        var folderPath = folderUrl.toString().replace(/^file:\/\//, '')
        
        // Use the same saveAsMarkdown logic but to a different location
        var basePath = folderPath.replace(/\/$/, '')
        
        // Build the complete save script
        var script = "#!/bin/bash\n"
        script += "set -e\n"
        script += "BASE_PATH='" + basePath.replace(/'/g, "'\\''" ) + "'\n"
        
        // Create base directory
        script += "mkdir -p \"$BASE_PATH\"\n"
        
        // Track which directories we need
        var dirsNeeded = {}
        dirsNeeded[basePath + "/_ungrouped"] = true
        
        // Create directories for all groups
        for (var i = 0; i < groups.length; i++) {
            var group = groups[i]
            var groupPath = getGroupPath(group.id, basePath)
            dirsNeeded[groupPath] = true
        }
        
        // Create all directories
        for (var dir in dirsNeeded) {
            script += "mkdir -p '" + dir.replace(/'/g, "'\\''" ) + "'\n"
        }
        
        // Write each snippet as a markdown file
        for (var j = 0; j < snippets.length; j++) {
            var snippet = snippets[j]
            var snippetPath = getGroupPath(snippet.groupId, basePath)
            var filename = sanitizeFilename(snippet.title) + ".md"
            var fullPath = snippetPath + "/" + filename
            
            // Create markdown content with frontmatter
            var mdContent = "---\n"
            mdContent += "title: " + snippet.title.replace(/:/g, "\\:") + "\n"
            mdContent += "id: " + snippet.id + "\n"
            mdContent += "---\n\n"
            mdContent += "```\n"
            mdContent += snippet.code + "\n"
            mdContent += "```\n"
            
            script += "cat > '" + fullPath.replace(/'/g, "'\\''" ) + "' << 'SNIPPET_EOF'\n"
            script += mdContent
            script += "SNIPPET_EOF\n"
        }
        
        // Execute the script
        var cmd = "bash -c '" + script.replace(/'/g, "'\\''" ) + "'"
        executable.connectSource(cmd)
        showNotification("Exported as Markdown directory")
    }
    
    function importData(fileUrl) {
        // Convert file:// URL to path
        var filePath = fileUrl.toString().replace(/^file:\/\//, '')
        
        // Mark next operation as import
        executable.isImporting = true
        
        // Use cat to read file (no custom prefix)
        var cmd = "cat '" + filePath + "'"
        executable.connectSource(cmd)
    }
    
    function importDataFromMarkdown(folderUrl) {
        // Import from markdown directory structure
        var folderPath = folderUrl.toString().replace(/^file:\/\//, '').replace(/\/$/, '')
        
        // Use find to get all .md files and directory structure
        var cmd = "find '" + folderPath.replace(/'/g, "'\\''" ) + "' -type f -name '*.md' -exec sh -c 'echo \"FILE_START\"; echo \"{}\" ; echo \"FILE_CONTENT_START\"; cat \"{}\" ; echo \"FILE_CONTENT_END\"' \\;"
        
        executable.isImportingMarkdown = true
        executable.markdownBasePath = folderPath
        executable.connectSource(cmd)
    }
    
    ListModel {
        id: displayModel
    }
    
    // Compact representation - the icon that appears in the panel
    compactRepresentation: Kirigami.Icon {
        source: "code-context"
        active: compactMouse.containsMouse
        
        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }
    
    // Full representation - the popup window
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 25
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: Kirigami.Units.gridUnit * 25
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            
            // Header with Add button
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents3.Button {
                    icon.name: "go-previous"
                    visible: pathDepth > 0
                    onClicked: navigateBack()
                    PlasmaComponents3.ToolTip {
                        text: "Go back to parent"
                    }
                }
                
                Kirigami.Heading {
                    text: currentGroupId === -1 ? "Code Snippets" : getCurrentGroupName()
                    level: 3
                    Layout.fillWidth: true
                    font.pixelSize: fontSize + 4
                }
                
                PlasmaComponents3.Button {
                    icon.name: "zoom-out"
                    enabled: fontSize > 6
                    onClicked: {
                        if (fontSize > 6) fontSize--
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Decrease font size"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: "zoom-in"
                    enabled: fontSize < 24
                    onClicked: {
                        if (fontSize < 24) fontSize++
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Increase font size"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: isPinned ? "window-unpin" : "window-pin"
                    onClicked: {
                        isPinned = !isPinned
                    }
                    PlasmaComponents3.ToolTip {
                        text: isPinned ? "Unpin window" : "Pin window to keep it open"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: "document-import"
                    onClicked: {
                        importFormatDialog.open()
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Import snippets from file or folder"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: "document-export"
                    onClicked: {
                        exportFormatDialog.open()
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Export snippets to file or folder"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: "folder-new"
                    onClicked: {
                        groupDialog.editIndex = -1
                        groupDialog.editName = "New Group"
                        groupDialog.open()
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Create a new group"
                    }
                }
                
                PlasmaComponents3.Button {
                    icon.name: "list-add"
                    onClicked: {
                        editDialog.editIndex = -1
                        editDialog.editTitle = "New Snippet"
                        editDialog.editCode = "// Your code here"
                        editDialog.open()
                    }
                    PlasmaComponents3.ToolTip {
                        text: "Create a new snippet"
                    }
                }
            }
            
            // Search bar
            PlasmaComponents3.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search snippets and groups..."
                clearButtonShown: true
                onTextChanged: refreshView()
                font.pixelSize: fontSize
            }
            
            // Display List
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ListView {
                    id: displayListView
                    model: displayModel
                    spacing: Kirigami.Units.smallSpacing
                    clip: true
                    
                    delegate: Kirigami.AbstractCard {
                        width: displayListView.width - Kirigami.Units.smallSpacing * 2
                        
                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing
                            
                            // Group representation
                            RowLayout {
                                Layout.fillWidth: true
                                visible: model.itemType === "group"
                                
                                Kirigami.Icon {
                                    source: "folder"
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                }
                                
                                Kirigami.Heading {
                                    text: model.title
                                    level: 4
                                    Layout.fillWidth: true
                                    font.pixelSize: fontSize + 2
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: navigateToGroup(model.itemId, model.title)
                                    }
                                }
                                
                                PlasmaComponents3.Button {
                                    icon.name: "document-edit"
                                    text: "Rename"
                                    font.pixelSize: fontSize
                                    onClicked: {
                                        var idx = findGroupById(model.itemId)
                                        if (idx >= 0) {
                                            groupDialog.editIndex = idx
                                            groupDialog.editName = model.title
                                            groupDialog.open()
                                        }
                                    }
                                }
                                
                                PlasmaComponents3.Button {
                                    icon.name: "delete"
                                    text: "Delete"
                                    font.pixelSize: fontSize
                                    onClicked: {
                                        var idx = findGroupById(model.itemId)
                                        if (idx >= 0) {
                                            // Move child items to parent
                                            var deletedGroupId = groups[idx].id
                                            var parentGroupId = groups[idx].parentId
                                            
                                            // Move child groups
                                            for (var i = 0; i < groups.length; i++) {
                                                if (groups[i].parentId === deletedGroupId) {
                                                    groups[i].parentId = parentGroupId
                                                }
                                            }
                                            
                                            // Move snippets in this group
                                            for (var j = 0; j < snippets.length; j++) {
                                                if (snippets[j].groupId === deletedGroupId) {
                                                    snippets[j].groupId = parentGroupId
                                                }
                                            }
                                            
                                            groups.splice(idx, 1)
                                            saveData()
                                            refreshView()
                                        }
                                    }
                                }
                            }
                            
                            // Snippet representation
                            RowLayout {
                                Layout.fillWidth: true
                                visible: model.itemType === "snippet"
                                
                                Kirigami.Icon {
                                    source: "text-x-generic"
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                }
                                
                                Kirigami.Heading {
                                    text: model.title
                                    level: 4
                                    Layout.fillWidth: true
                                    font.pixelSize: fontSize + 2
                                }
                                
                                PlasmaComponents3.Button {
                                    icon.name: "edit-copy"
                                    text: "Copy"
                                    font.pixelSize: fontSize
                                    onClicked: {
                                        clipboardHelper.text = model.code
                                        clipboardHelper.selectAll()
                                        clipboardHelper.copy()
                                        showNotification("Copied!")
                                    }
                                }
                                
                                PlasmaComponents3.Button {
                                    icon.name: "document-edit"
                                    text: "Edit"
                                    font.pixelSize: fontSize
                                    onClicked: {
                                        var idx = findSnippetById(model.itemId)
                                        if (idx >= 0) {
                                            editDialog.editIndex = idx
                                            editDialog.editTitle = model.title
                                            editDialog.editCode = model.code
                                            editDialog.open()
                                        }
                                    }
                                }
                                
                                PlasmaComponents3.Button {
                                    icon.name: "delete"
                                    text: "Delete"
                                    font.pixelSize: fontSize
                                    onClicked: {
                                        var idx = findSnippetById(model.itemId)
                                        if (idx >= 0) {
                                            snippets.splice(idx, 1)
                                            saveData()
                                            refreshView()
                                        }
                                    }
                                }
                            }
                            
                            // Code display (only for snippets)
                            QQC2.ScrollView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(codeText.contentHeight + 20, 150)
                                visible: model.itemType === "snippet"
                                
                                QQC2.TextArea {
                                    id: codeText
                                    text: model.code
                                    readOnly: true
                                    wrapMode: Text.Wrap
                                    font.family: "monospace"
                                    font.pixelSize: fontSize
                                    background: Rectangle {
                                        color: Kirigami.Theme.alternateBackgroundColor
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Notification
            PlasmaComponents3.Label {
                id: notification
                Layout.alignment: Qt.AlignHCenter
                visible: false
                text: ""
                color: Kirigami.Theme.positiveTextColor
                font.pixelSize: fontSize
                
                SequentialAnimation {
                    id: notificationAnimation
                    PropertyAnimation {
                        target: notification
                        property: "visible"
                        to: true
                        duration: 0
                    }
                    PauseAnimation {
                        duration: 2000
                    }
                    PropertyAnimation {
                        target: notification
                        property: "visible"
                        to: false
                        duration: 0
                    }
                }
            }
        }
        
        // Hidden text field for clipboard operations
        TextEdit {
            id: clipboardHelper
            visible: false
        }
        
        // Group Dialog
        QQC2.Dialog {
            id: groupDialog
            title: editIndex === -1 ? "New Group" : "Rename Group"
            modal: true
            standardButtons: QQC2.Dialog.Save | QQC2.Dialog.Cancel
            
            property int editIndex: -1
            property string editName: ""
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Math.min(parent.width * 0.6, Kirigami.Units.gridUnit * 20)
            
            onAccepted: {
                if (editIndex === -1) {
                    // Create new group
                    groups.push({
                        id: getNextId(groups),
                        name: groupNameField.text,
                        parentId: currentGroupId
                    })
                } else {
                    // Rename existing group
                    groups[editIndex].name = groupNameField.text
                }
                saveData()
                refreshView()
            }
            
            onOpened: {
                groupNameField.text = editName
                groupNameField.forceActiveFocus()
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "Group Name:"
                    font.pixelSize: fontSize
                }
                
                PlasmaComponents3.TextField {
                    id: groupNameField
                    Layout.fillWidth: true
                    placeholderText: "Enter group name..."
                    font.pixelSize: fontSize
                }
            }
        }
        
        // Edit Snippet Dialog
        QQC2.Dialog {
            id: editDialog
            title: editIndex === -1 ? "Add Snippet" : "Edit Snippet"
            modal: true
            standardButtons: QQC2.Dialog.Save | QQC2.Dialog.Cancel
            
            property int editIndex: -1
            property string editTitle: ""
            property string editCode: ""
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Math.min(parent.width * 0.9, Kirigami.Units.gridUnit * 30)
            height: Math.min(parent.height * 0.8, Kirigami.Units.gridUnit * 25)
            
            onAccepted: {
                if (editIndex === -1) {
                    // Create new snippet
                    snippets.push({
                        id: getNextId(snippets),
                        title: titleField.text,
                        code: codeField.text,
                        groupId: currentGroupId
                    })
                } else {
                    // Update existing snippet
                    snippets[editIndex].title = titleField.text
                    snippets[editIndex].code = codeField.text
                }
                saveData()
                refreshView()
            }
            
            onOpened: {
                titleField.text = editTitle
                codeField.text = editCode
                titleField.forceActiveFocus()
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "Title:"
                    font.pixelSize: fontSize
                }
                
                PlasmaComponents3.TextField {
                    id: titleField
                    Layout.fillWidth: true
                    placeholderText: "Snippet title..."
                    font.pixelSize: fontSize
                }
                
                PlasmaComponents3.Label {
                    text: "Code:"
                    font.pixelSize: fontSize
                }
                
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    QQC2.TextArea {
                        id: codeField
                        placeholderText: "// Your code here..."
                        wrapMode: Text.Wrap
                        font.family: "monospace"
                        font.pixelSize: fontSize
                    }
                }
            }
        }
        
        // Export File Dialog (JSON)
        Platform.FileDialog {
            id: exportFileDialog
            title: "Export Snippets as JSON"
            fileMode: Platform.FileDialog.SaveFile
            nameFilters: ["JSON files (*.json)"]
            defaultSuffix: "json"
            
            onAccepted: {
                exportData(file)
            }
        }
        
        // Export Folder Dialog (Markdown)
        Platform.FolderDialog {
            id: exportFolderDialog
            title: "Export Snippets as Markdown (select folder)"
            
            onAccepted: {
                exportDataAsMarkdown(folder)
            }
        }
        
        // Import File Dialog (JSON)
        Platform.FileDialog {
            id: importFileDialog
            title: "Import Snippets from JSON"
            fileMode: Platform.FileDialog.OpenFile
            nameFilters: ["JSON files (*.json)"]
            
            onAccepted: {
                importData(file)
            }
        }
        
        // Import Folder Dialog (Markdown)
        Platform.FolderDialog {
            id: importFolderDialog
            title: "Import Snippets from Markdown folder"
            
            onAccepted: {
                importDataFromMarkdown(folder)
            }
        }
        
        // Export Format Selection Dialog
        QQC2.Dialog {
            id: exportFormatDialog
            title: "Export Format"
            modal: true
            standardButtons: QQC2.Dialog.Cancel
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Math.min(parent.width * 0.6, Kirigami.Units.gridUnit * 18)
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "Choose export format:"
                    font.bold: true
                }
                
                PlasmaComponents3.Button {
                    text: "JSON (Single File)"
                    icon.name: "application-json"
                    Layout.fillWidth: true
                    onClicked: {
                        exportFormatDialog.close()
                        exportFileDialog.open()
                    }
                }
                
                PlasmaComponents3.Button {
                    text: "Markdown (Directory Structure)"
                    icon.name: "folder-documents"
                    Layout.fillWidth: true
                    onClicked: {
                        exportFormatDialog.close()
                        exportFolderDialog.open()
                    }
                }
            }
        }
        
        // Import Format Selection Dialog
        QQC2.Dialog {
            id: importFormatDialog
            title: "Import Format"
            modal: true
            standardButtons: QQC2.Dialog.Cancel
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Math.min(parent.width * 0.6, Kirigami.Units.gridUnit * 18)
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "Choose import format:"
                    font.bold: true
                }
                
                PlasmaComponents3.Button {
                    text: "JSON (Single File)"
                    icon.name: "application-json"
                    Layout.fillWidth: true
                    onClicked: {
                        importFormatDialog.close()
                        importFileDialog.open()
                    }
                }
                
                PlasmaComponents3.Button {
                    text: "Markdown (Directory Structure)"
                    icon.name: "folder-documents"
                    Layout.fillWidth: true
                    onClicked: {
                        importFormatDialog.close()
                        importFolderDialog.open()
                    }
                }
            }
        }
    }
    
    function showNotification(message) {
        notification.text = message
        notificationAnimation.restart()
    }
}