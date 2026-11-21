// Any tray app's menu as a Control Center page, so an app with a tray icon gets controls without new code:
//   CcRow { title: "Vicinae"; page: "TrayMenu"; pageProps: ({ trayId: "vicinae" }) }
// Entries run on click and the page stays open (menus that update, like radio choices, show the change).
// Submenus aren't followed; those entries show disabled.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.cc

CcPage {
    id: page

    property string trayId                 // StatusNotifierItem id (busctl … RegisteredStatusNotifierItems)
    readonly property var tray: SystemTray.items.values.find(i => i.id === trayId) ?? null

    title: tray?.title || tray?.tooltipTitle || trayId
    showSwitch: false

    QsMenuOpener { id: opener; menu: page.tray?.menu ?? null }

    CcPlaceholder {
        visible: page.tray === null || opener.children.values.length === 0
        text: page.tray === null ? "The app isn't running" : "Nothing in this menu"
    }

    Repeater {
        model: opener.children
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 0

            CcDivider {
                visible: modelData.isSeparator
                Layout.topMargin: 3
                Layout.bottomMargin: 3
            }
            CcListRow {
                visible: !modelData.isSeparator
                title: modelData.text
                interactive: modelData.enabled && !modelData.hasChildren
                dimmed: !interactive
                trailingCode: modelData.checkState === Qt.Checked ? 0xF012C : 0   // check
                onClicked: modelData.triggered()
            }
        }
    }
}
