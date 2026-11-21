// Setting row on a page: glyph, label, switch (e.g. Night Shift's "Scheduled", Tailscale's "Use Tailscale DNS").
import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
    id: sw

    property int code
    property string label
    property bool checked
    property bool busy: false
    signal toggled()

    // Keyboard navigation (ControlCenter.qml): Enter = navActivate(), Space = navToggle()
    readonly property bool ccNav: true
    readonly property int navRadius: Theme.rowRadius
    function navActivate() { toggled(); }
    function navToggle() { toggled(); }

    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.rightMargin: 4
    Layout.preferredHeight: 32
    spacing: 8

    Glyph {
        code: sw.code
        size: 16
        color: Theme.accent
    }
    CcText {
        Layout.fillWidth: true
        text: sw.label
    }
    CcSwitch {
        checked: sw.checked
        opacity: sw.enabled ? (sw.busy ? 0.5 : 1) : 0.4
        onToggled: sw.toggled()
    }
}
