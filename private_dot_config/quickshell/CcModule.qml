// A Control Center module: rounded white-7% tile that drops into place when `shown` turns on,
// `delay` ms after the panel starts opening (staggered by the caller).
import QtQuick

Rectangle {
    id: module

    property bool shown: false
    property int delay: 0
    property int padding: 10
    default property alias content: inner.data

    implicitWidth: 2 * padding                       // callers size modules via layouts
    implicitHeight: inner.childrenRect.height + 2 * padding
    radius: Theme.moduleRadius
    color: Theme.moduleBg
    border.width: 1
    border.color: Theme.moduleBorder

    opacity: 0
    scale: 0.94
    transform: Translate { id: drop; y: -10 }

    states: State {
        name: "shown"
        when: module.shown
        PropertyChanges { target: module; opacity: 1; scale: 1 }
        PropertyChanges { target: drop; y: 0 }
    }
    transitions: [
        Transition {
            to: "shown"
            SequentialAnimation {
                PauseAnimation { duration: module.delay }
                ParallelAnimation {
                    NumberAnimation { target: module; property: "opacity"; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: module; property: "scale"; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    NumberAnimation { target: drop; property: "y"; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }
            }
        },
        Transition {
            from: "shown"
            NumberAnimation { targets: [module, drop]; properties: "opacity,scale,y"; duration: 140; easing.type: Easing.InCubic }
        }
    ]

    Item {
        id: inner
        x: module.padding
        y: module.padding
        width: module.width - 2 * module.padding
        height: module.height - 2 * module.padding
    }
}
