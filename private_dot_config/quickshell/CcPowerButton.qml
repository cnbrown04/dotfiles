// Round power-action button with a caption. With `confirm`, the first click arms it (white, rippling,
// caption "Confirm") and a second click within 3 s runs it.
import QtQuick

Item {
    id: pb

    property int code
    property string label
    property bool confirm: false
    property bool armed: false
    signal triggered()

    implicitWidth: 64
    implicitHeight: column.implicitHeight

    Timer { id: disarm; interval: 3000; onTriggered: pb.armed = false }

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40

            // Ripple while armed
            Rectangle {
                id: ripple
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                opacity: 0
                SequentialAnimation {
                    running: pb.armed
                    loops: Animation.Infinite
                    onStopped: { ripple.opacity = 0; ripple.scale = 1; }
                    ParallelAnimation {
                        NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.5; duration: 900; easing.type: Easing.OutCubic }
                        NumberAnimation { target: ripple; property: "opacity"; from: 0.7; to: 0; duration: 900; easing.type: Easing.OutCubic }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: pb.armed ? Theme.accent : mouse.containsMouse ? Theme.controlHover : Theme.control
                Behavior on color { ColorAnimation { duration: 200 } }
                scale: mouse.pressed ? 0.86 : 1
                Behavior on scale { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.002 } }

                Glyph {
                    anchors.centerIn: parent
                    code: pb.code
                    size: 18
                    color: pb.armed ? Theme.accentFg : Theme.accent
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!pb.confirm || pb.armed) {
                        pb.armed = false;
                        pb.triggered();
                    } else {
                        pb.armed = true;
                        disarm.restart();
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pb.armed ? "Confirm" : pb.label
            color: pb.armed ? Theme.panelFg : Theme.altFg
            font.family: Theme.font
            font.pixelSize: Theme.fontCaption
            font.weight: pb.armed ? Font.Bold : Font.Normal
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
