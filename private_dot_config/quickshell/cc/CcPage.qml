// Base for a detail page (pages/*.qml): a column with the standard header (back chevron, title, optional
// power switch) and a divider; put the page's content inside. `active` is true while it's the page on top
// and the panel is open (use it to start scans/polls only while visible).
//   CcPage { title: "Wi-Fi"; checked: …; onToggled: …; CcListRow { … } }
// Set showSwitch: false for pages with nothing to switch.
import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
    id: page

    property var cc
    property bool active: false
    property string title
    property bool showSwitch: true
    property bool checked: false
    property bool switchBusy: false
    signal toggled()

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        CcIconButton {
            code: 0xF0141  // chevron-left
            navigable: false   // h / ← / Esc go back
            size: 30
            glyphSize: 16
            onClicked: page.cc.back()
        }
        CcText {
            Layout.fillWidth: true
            kind: "title"
            text: page.title
        }
        CcSwitch {
            Layout.rightMargin: 4
            visible: page.showSwitch
            checked: page.checked
            opacity: page.switchBusy ? 0.5 : 1
            onToggled: page.toggled()
        }
    }
    CcDivider {}
}
