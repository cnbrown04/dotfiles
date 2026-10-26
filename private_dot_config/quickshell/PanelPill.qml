// A MacTahoe top-bar button (.panel-button): transparent pill that lights up on hover/press.
// Put content inside; it's laid out in a centered row.
import QtQuick

Item {
    id: pill

    default property alias content: row.data
    property int hpadding: 12                 // -natural-hpadding
    property bool active: false               // e.g. a menu is open
    signal clicked(var mouse)
    signal wheel(var wheel)
    property alias acceptedButtons: mouse.acceptedButtons
    readonly property bool hovered: hover.hovered

    implicitWidth: row.implicitWidth + 2 * hpadding
    implicitHeight: Theme.pillHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: mouse.pressed || pill.active ? Theme.panelActive
             : hover.hovered ? Theme.panelHover : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Passive, so hovering child items (tray icons) keeps the pill highlighted
    HoverHandler { id: hover }

    // Below the content, so children with their own MouseArea (tray icons) get their clicks
    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.wheel(w)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
