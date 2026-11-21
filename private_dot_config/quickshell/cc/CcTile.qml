// Small square-ish module: toggle circle + one-line label (Keep Awake, Night Shift); on/off shows in the circle.
// Clicking the circle emits toggled(); with `page` set, clicking the rest of the tile opens that page,
// otherwise the whole tile toggles.
import QtQuick
import QtQuick.Layouts
import qs

CcModule {
    id: tile

    property var cc
    property int code
    property string label
    property bool checked
    property bool busy: false
    property string page: ""
    property var pageProps: ({})
    signal toggled()

    // Keyboard navigation (ControlCenter.qml): Enter = navActivate(), Space = navToggle()
    readonly property bool ccNav: true
    readonly property int navRadius: Theme.moduleRadius
    function navActivate() { if (page !== "") cc.push(page, pageProps); else toggled(); }
    function navToggle() { toggled(); }

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 56
    shown: cc?.open ?? false
    color: tileMouse.containsMouse ? Theme.hoverFill : Theme.moduleBg
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: tileMouse
        width: tile.width - 2 * tile.padding
        height: tile.height - 2 * tile.padding
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.page !== "" ? tile.cc.push(tile.page, tile.pageProps) : tile.toggled()
    }

    RowLayout {
        width: tile.width - 2 * tile.padding
        height: tile.height - 2 * tile.padding
        spacing: 8

        CcToggle {
            code: tile.code
            checked: tile.checked
            busy: tile.busy
            onClicked: tile.toggled()
        }
        CcText {
            Layout.fillWidth: true
            kind: "heading"
            font.pixelSize: Theme.fontSizeSmall
            text: tile.label
        }
    }
}
