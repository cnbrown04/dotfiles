// Centered dim note for an empty list ("Wi-Fi is off", "No exit nodes").
import QtQuick
import QtQuick.Layouts
import qs

CcText {
    Layout.fillWidth: true
    Layout.topMargin: 14
    Layout.bottomMargin: 14
    horizontalAlignment: Text.AlignHCenter
    kind: "hint"
    font.pixelSize: Theme.fontSizeSmall
}
