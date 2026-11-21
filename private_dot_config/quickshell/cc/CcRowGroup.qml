// A module holding a stack of rows from rows/ (by file name), e.g. rows: ["Tailscale", "ProtonVpn"].
// This is what a nested list in ControlCenter.qml's `screens` turns into.
import QtQuick
import QtQuick.Layouts
import qs

CcModule {
    id: group

    property var cc
    property var rows: []
    // Shown while at least one of its rows is
    readonly property bool available: {
        for (let i = 0; i < rowRepeater.count; i++)
            if (rowRepeater.itemAt(i)?.available) return true;
        return false;
    }

    padding: 4
    shown: cc?.open ?? false

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 2

        Repeater {
            id: rowRepeater
            model: group.rows
            delegate: CcSlot {
                required property string modelData
                cc: group.cc
                file: "rows/" + modelData
            }
        }
    }
}
