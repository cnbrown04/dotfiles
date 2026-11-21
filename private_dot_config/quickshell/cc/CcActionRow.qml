// Plain clickable row on a page: glyph circle + label (AirDrop's "Send File…", "Open Proton VPN").
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: action

    property int code
    property string label
    signal clicked()

    // Keyboard navigation (ControlCenter.qml): Enter = navActivate(), Space = navToggle()
    readonly property bool ccNav: true
    readonly property int navRadius: Theme.rowRadius
    function navActivate() { clicked(); }
    function navToggle() { clicked(); }

    Layout.fillWidth: true
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.rowRadius
        color: mouse.pressed ? Theme.rowPressed : mouse.containsMouse ? Theme.rowHover : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: action.clicked()
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 10

        CcToggle {
            size: 28
            interactive: false
            code: action.code
        }
        CcText {
            Layout.fillWidth: true
            text: action.label
        }
    }
}
