// Night Shift (NightShift.qml -> nightshift + hyprsunset): status, color temperature, From/To schedule.
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

CcPage {
    id: page

    title: "Night Shift"
    checked: NightShift.active
    onToggled: NightShift.toggle()

    // Schedule time: label, − time +, 15-minute steps (scroll the time to step too)
    component TimeRow: RowLayout {
        id: timeRow

        property string label
        property string which           // "from" | "to"

        Layout.fillWidth: true
        Layout.leftMargin: 30
        Layout.rightMargin: 2
        spacing: 2
        enabled: NightShift.schedule
        opacity: enabled ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 180 } }

        CcText {
            Layout.fillWidth: true
            kind: "caption"
            font.pixelSize: Theme.fontSizeSmall
            text: timeRow.label
        }
        CcIconButton {
            code: 0xF0374  // minus
            size: 26
            glyphSize: 14
            onClicked: NightShift.shiftTime(timeRow.which, -15)
        }
        CcText {
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignHCenter
            kind: "heading"
            text: NightShift.clock(NightShift[timeRow.which])

            MouseArea {
                anchors.fill: parent
                onWheel: w => NightShift.shiftTime(timeRow.which, w.angleDelta.y > 0 ? 15 : -15)
            }
        }
        CcIconButton {
            code: 0xF0415  // plus
            size: 26
            glyphSize: 14
            onClicked: NightShift.shiftTime(timeRow.which, 15)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 10

        CcToggle {
            size: 36
            code: 0xF0594  // weather-night
            checked: NightShift.active
            onClicked: NightShift.toggle()
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            CcText { Layout.fillWidth: true; kind: "heading"; text: NightShift.summary }
            CcText {
                Layout.fillWidth: true
                kind: "caption"
                text: !NightShift.running ? "hyprsunset isn't running"
                    : NightShift.schedule ? "Scheduled " + NightShift.clock(NightShift.from) + " – " + NightShift.clock(NightShift.to)
                    : "Stays on until you turn it off"
            }
        }
    }

    CcDivider { Layout.topMargin: 4 }

    // Color temperature
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 6

        CcText { kind: "section"; text: "Color Temperature" }
        CcSlider {
            Layout.fillWidth: true
            code: 0xF050F  // thermometer
            value: NightShift.warmth(NightShift.temperature)
            label: NightShift.temperature + "K"
            onMoved: v => NightShift.setTemperature(NightShift.kelvin(v))
            onIconClicked: NightShift.toggle()
        }
        RowLayout {
            Layout.fillWidth: true
            CcText { Layout.fillWidth: true; kind: "hint"; text: "Less Warm" }
            CcText { kind: "hint"; text: "More Warm" }
        }
    }

    CcDivider { Layout.topMargin: 2 }

    CcSwitchRow {
        code: 0xF0150  // clock-outline
        label: "Scheduled"
        checked: NightShift.schedule
        onToggled: NightShift.setSchedule(!NightShift.schedule)
    }
    TimeRow { label: "From"; which: "from" }
    TimeRow { label: "To"; which: "to"; Layout.bottomMargin: 4 }
}
