// Loads one framework file (a module, row or page) by its path under cc/, e.g. "rows/Wifi",
// handing it the Control Center (`cc`) plus any extra `props`. Hidden while the item's `available` is false,
// so a row or module can drop out (AirPods while disconnected, Ethernet without a wired card).
import QtQuick
import QtQuick.Layouts

Loader {
    id: slot

    property var cc
    property string file
    property var props: ({})
    readonly property bool available: status === Loader.Ready && (item.available ?? true)

    Layout.fillWidth: true
    Layout.preferredHeight: item ? item.implicitHeight : 0
    visible: available

    Component.onCompleted: setSource(Qt.resolvedUrl(file + ".qml"), Object.assign({ cc: slot.cc }, slot.props))
    onStatusChanged: if (status === Loader.Error) console.warn("ControlCenter: couldn't load", file)
}
