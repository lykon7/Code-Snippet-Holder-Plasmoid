import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kcmutils as KCM
import Qt.labs.platform as Platform

KCM.SimpleKCM {
    id: page
    
    property string cfg_customFilePath
    property string cfg_storageFormat
    property int cfg_fontSize
    
    Kirigami.FormLayout {
        
        // Storage Format Selection
        QQC2.ComboBox {
            id: formatCombo
            Kirigami.FormData.label: "Storage Format:"
            model: ["JSON (Single File)", "Markdown (Directory)"]
            currentIndex: plasmoid.configuration.storageFormat === "markdown" ? 1 : 0
            onCurrentIndexChanged: {
                var format = currentIndex === 1 ? "markdown" : "json"
                plasmoid.configuration.storageFormat = format
                cfg_storageFormat = format
            }
        }
        
        PlasmaComponents3.Label {
            text: formatCombo.currentIndex === 0 
                ? "All snippets stored in a single JSON file."
                : "Groups become folders. Snippets become individual .md files with frontmatter."
            font.italic: true
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        // Custom File/Folder Path Selection
        RowLayout {
            Kirigami.FormData.label: formatCombo.currentIndex === 0 ? "Custom Storage File:" : "Custom Storage Folder:"
            
            PlasmaComponents3.TextField {
                id: pathField
                placeholderText: formatCombo.currentIndex === 0 
                    ? "/path/to/my_snippets.json" 
                    : "/path/to/my_snippets/"
                Layout.fillWidth: true
                text: plasmoid.configuration.customFilePath
                onTextChanged: {
                    plasmoid.configuration.customFilePath = text
                    cfg_customFilePath = text
                }
            }
            
            PlasmaComponents3.Button {
                icon.name: "folder-open"
                text: "Browse..."
                onClicked: {
                    if (formatCombo.currentIndex === 0) {
                        fileDialog.open()
                    } else {
                        folderDialog.open()
                    }
                }
            }
        }
        
        PlasmaComponents3.Label {
            text: "Leave empty to use default internal storage. If set, snippets will be loaded from and saved to this location."
            font.italic: true
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // Font Size Configuration
        QQC2.SpinBox {
            id: fontSizeSpin
            Kirigami.FormData.label: "Font Size:"
            from: 6
            to: 32
            stepSize: 1
            value: plasmoid.configuration.fontSize
            onValueModified: {
                plasmoid.configuration.fontSize = value
                cfg_fontSize = value
            }
        }
    }
    
    // File dialog for JSON format
    Platform.FileDialog {
        id: fileDialog
        title: "Select Storage File"
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        fileMode: Platform.FileDialog.SaveFile
        onAccepted: {
            var path = file.toString().replace(/^file:\/\//, '')
            pathField.text = path
        }
    }
    
    // Folder dialog for Markdown format
    Platform.FolderDialog {
        id: folderDialog
        title: "Select Storage Folder"
        onAccepted: {
            var path = folder.toString().replace(/^file:\/\//, '')
            pathField.text = path
        }
    }
}