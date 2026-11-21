// A row in a row group (Wi-Fi, Bluetooth, VPNs…): toggle circle + title, with the state as a caption under it.
// Clicking the circle emits toggled(); with `page` set, clicking the rest of the row opens that page
// (e.g. page: "Wifi" -> pages/Wifi.qml, with `pageProps` passed to it).
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: row

    property var cc
    property bool available: true
    property int code
    property string title
    property string subtitle
    property bool checked
    property bool toggleable: true
    property bool busy: false
    property string page: ""
    property var pageProps: ({})
    signal toggled()

    // Keyboard navigation (ControlCenter.qml): Enter = navActivate(), Space = navToggle()
    readonly property bool ccNav: toggleable || page !== ""
    readonly property int navRadius: Theme.rowRadius
    function navActivate() { if (page !== "") cc.push(page, pageProps); else if (toggleable) toggled(); }
    function navToggle() { if (toggleable) toggled(); }

    Layout.fillWidth: true
    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius: Theme.rowRadius
        color: rowMouse.pressed ? Theme.rowPressed : rowMouse.containsMouse ? Theme.rowHover : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        enabled: row.page !== ""
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.cc.push(row.page, row.pageProps)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 10

        CcToggle {
            code: row.code
            checked: row.checked
            busy: row.busy
            interactive: row.toggleable
            onClicked: row.toggled()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CcText { Layout.fillWidth: true; kind: "heading"; text: row.title }
            CcText { Layout.fillWidth: true; kind: "caption"; text: row.subtitle; visible: text !== "" }
        }

        Glyph {
            visible: row.page !== ""
            code: 0xF0142  // chevron-right
            size: 14
            color: Theme.altFg
            opacity: rowMouse.containsMouse ? 1 : 0
            transform: Translate { x: rowMouse.containsMouse ? 0 : -6; Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
