// Borderless glyph button with a round hover highlight (media controls, back arrow).
import QtQuick

Item {
    id: btn

    property int code
    property int size: 32
    property int glyphSize: 18
    property bool enabledLook: true
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    opacity: enabledLook ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: mouse.pressed ? Theme.controlPressed : mouse.containsMouse ? Theme.hoverFill : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Glyph {
        id: glyph
        anchors.centerIn: parent
        code: btn.code
        size: btn.glyphSize
        color: Theme.accent
        scale: mouse.pressed ? 0.8 : 1
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (btn.enabledLook) btn.clicked()
    }
}
