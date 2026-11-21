// A clickable row in a page's list (networks, devices, servers, menu entries): small circle glyph, title
// (bold while `current`), optional caption, optional trailing text/glyph. Emits clicked(). code 0 = no circle.
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: item

    property int code: 0
    property string title
    property string subtitle
    property bool current: false      // connected / selected: filled circle, bold title
    property bool busy: false
    property bool interactive: true
    property bool dimmed: false       // offline device, disabled menu entry
    property string trailing: ""      // small text on the right ("Copied")
    property int trailingCode: 0      // or a glyph on the right (lock, check)
    signal clicked()

    // Keyboard navigation (ControlCenter.qml): Enter = navActivate(), Space = navToggle()
    readonly property bool ccNav: interactive
    readonly property int navRadius: Theme.rowRadius
    function navActivate() { clicked(); }
    function navToggle() { clicked(); }

    Layout.fillWidth: true
    implicitHeight: subtitle !== "" ? 44 : 38

    Rectangle {
        anchors.fill: parent
        radius: Theme.rowRadius
        color: !item.interactive ? "transparent"
             : mouse.pressed ? Theme.rowPressed : mouse.containsMouse ? Theme.rowHover : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: item.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }

    RowLayout {
        x: 6
        width: parent.width - 12
        height: parent.height
        spacing: 10
        opacity: item.dimmed ? 0.45 : 1

        CcToggle {
            visible: item.code !== 0   // code 0: plain text row (menu entries)
            size: 28
            interactive: false
            checked: item.current
            busy: item.busy
            code: item.code
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CcText {
                Layout.fillWidth: true
                text: item.title
                font.weight: item.current ? Font.Bold : Font.Normal
            }
            CcText {
                Layout.fillWidth: true
                kind: "caption"
                visible: text !== ""
                text: item.subtitle
            }
        }
        CcText {
            visible: item.trailing !== ""
            Layout.rightMargin: 4
            kind: "caption"
            text: item.trailing
        }
        Glyph {
            visible: item.trailingCode !== 0
            Layout.rightMargin: 8
            code: item.trailingCode
            size: 12
            color: Theme.dim
        }
    }
}
