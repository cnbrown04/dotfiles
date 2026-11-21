// Scrolling list for a page, capped at `maxHeight` (then it scrolls). Rows slide in as they appear.
//   CcList { model: ScriptModel { values: … }; delegate: CcListRow { required property var modelData; … } }
import QtQuick
import QtQuick.Layouts

ListView {
    property int maxHeight: 360

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, maxHeight)
    visible: count > 0
    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
        NumberAnimation { property: "x"; from: 16; to: 0; duration: 320; easing.type: Easing.OutCubic }
    }
    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic }
    }
    move: displaced
}
