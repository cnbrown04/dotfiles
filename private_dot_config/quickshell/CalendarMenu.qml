// Calendar that drops down from the bar's clock (click it; Esc or a click outside closes it).
// Same Popover + staggered modules as the Control Center.
//   - big live clock with the full date, ISO week and day of the year
//   - month grid: today in a white circle, click a day to select it (footer says how far away it is),
//     arrows / scroll to change month (the grid slides in the direction you went), "Today" jumps back
//   - how much of today / this week / this year has gone by
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
    id: cal

    required property var bar
    property bool open: false

    function close() { open = false; }
    function toggle() { open = !open; }

    readonly property int panelWidth: 660
    readonly property int sideWidth: 270     // clock + progress column
    readonly property int pad: 12

    SystemClock {
        id: clock
        precision: cal.open ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property date now: clock.date
    readonly property date today: new Date(now.getFullYear(), now.getMonth(), now.getDate())

    // Month being shown, and the selected day (null = none)
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property var selected: null

    // Opening always starts on this month with nothing selected
    onOpenChanged: if (open) {
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
        selected = null;
        grid.x = 0;
        grid.opacity = 1;
    }

    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek % 7   // 0 = Sunday (en_US)
    readonly property bool showingThisMonth: viewYear === now.getFullYear() && viewMonth === now.getMonth()

    // 42 cells (6 weeks) starting on the week containing the 1st
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const offset = (first.getDay() - firstDayOfWeek + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(viewYear, viewMonth, 1 - offset + i));
        return out;
    }

    function sameDay(a, b) {
        return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    function dayOfYear(d) {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1;
    }

    function relative(d) {
        const days = Math.round((d - today) / 86400000);
        if (days === 0) return "Today";
        if (days === 1) return "Tomorrow";
        if (days === -1) return "Yesterday";
        const n = Math.abs(days);
        const span = n >= 60 ? Math.round(n / 30.44) + " months" : n >= 14 ? Math.round(n / 7) + " weeks" : n + " days";
        return days > 0 ? "In " + span : span + " ago";
    }

    // Change month: slide the grid out, swap, slide the new month in from the other side
    property int slideDir: 1
    function shiftMonth(delta) {
        if (monthSwap.running) monthSwap.complete();
        slideDir = delta > 0 ? 1 : -1;
        pendingDelta = delta;
        monthSwap.start();
    }
    function goToday() {
        const delta = (now.getFullYear() - viewYear) * 12 + (now.getMonth() - viewMonth);
        if (delta !== 0) shiftMonth(delta);
        selected = null;
    }
    property int pendingDelta: 0

    SequentialAnimation {
        id: monthSwap
        ParallelAnimation {
            NumberAnimation { target: grid; property: "x"; to: -cal.slideDir * 28; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: grid; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                const m = cal.viewYear * 12 + cal.viewMonth + cal.pendingDelta;
                cal.viewYear = Math.floor(m / 12);
                cal.viewMonth = m % 12;
                grid.x = cal.slideDir * 28;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: grid; property: "x"; to: 0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { target: grid; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }
    }

    component Caption: Text {
        color: Theme.altFg
        font.family: Theme.font
        font.pixelSize: Theme.fontCaption
    }

    // Labelled progress bar for the "how far along" module
    component Progress: ColumnLayout {
        id: prog
        property string label
        property real value      // 0..1
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Caption { text: prog.label; Layout.fillWidth: true }
            Caption { text: Math.floor(prog.value * 100) + "%"; color: Theme.panelFg }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.progressTrack

            Rectangle {
                height: parent.height
                radius: 3
                color: Theme.accent
                // Grows from zero each time the calendar opens
                width: cal.open ? Math.max(height, parent.width * prog.value) : height
                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.OutQuint } }
            }
        }
    }

    Popover {
        bar: cal.bar
        open: cal.open
        align: "center"
        panelWidth: cal.panelWidth
        panelHeight: column.implicitHeight + 2 * cal.pad
        onCloseRequested: cal.close()

        // Wide layout: clock + progress on the left, the month on the right
        RowLayout {
            id: column
            x: cal.pad
            y: cal.pad
            width: cal.panelWidth - 2 * cal.pad
            spacing: 10

            ColumnLayout {
                Layout.preferredWidth: cal.sideWidth
                Layout.maximumWidth: cal.sideWidth
                Layout.fillHeight: true
                spacing: 10

                // Clock
                CcModule {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    shown: cal.open
                    delay: 0
                    padding: 16
                    implicitHeight: clockColumn.implicitHeight + 2 * padding

                    // Centered vertically: this module stretches to the month grid's height
                    ColumnLayout {
                        id: clockColumn
                        width: parent.width
                        y: Math.round((parent.height - implicitHeight) / 2)
                        spacing: 2

                        RowLayout {
                            spacing: 4
                            Text {
                                text: Qt.formatTime(cal.now, "HH:mm")
                                color: Theme.panelFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontDisplay
                                font.weight: Font.Bold
                            }
                            Text {
                                Layout.alignment: Qt.AlignBaseline
                                text: Qt.formatTime(cal.now, "ss")
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 20
                                font.weight: Font.Medium
                            }
                        }
                        Text {
                            text: Qt.formatDate(cal.now, "dddd, MMMM d, yyyy")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Medium
                        }
                        Caption {
                            text: "Week " + cal.isoWeek(cal.now) + "  ·  Day " + cal.dayOfYear(cal.now)
                        }
                    }
                }

                // How far along
                CcModule {
                    Layout.fillWidth: true
                    shown: cal.open
                    delay: 90
                    padding: 12

                    ColumnLayout {
                        width: parent.width
                        spacing: 10

                        Progress {
                            label: "Today"
                            value: (cal.now - cal.today) / 86400000
                        }
                        Progress {
                            label: "This week"
                            value: (((cal.now.getDay() - cal.firstDayOfWeek + 7) % 7) + (cal.now - cal.today) / 86400000) / 7
                        }
                        Progress {
                            label: String(cal.now.getFullYear())
                            value: (cal.now - new Date(cal.now.getFullYear(), 0, 1))
                                 / (new Date(cal.now.getFullYear() + 1, 0, 1) - new Date(cal.now.getFullYear(), 0, 1))
                        }
                    }
                }
            }

            // Month
            CcModule {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                shown: cal.open
                delay: 50
                padding: 10

                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: Qt.locale().standaloneMonthName(cal.viewMonth) + " " + cal.viewYear
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        // "Today" chip, shown when you've wandered away
                        Rectangle {
                            implicitWidth: todayText.implicitWidth + 18
                            implicitHeight: 24
                            radius: height / 2
                            color: todayMouse.containsMouse ? Theme.controlHover : Theme.control
                            opacity: cal.showingThisMonth ? 0 : 1
                            scale: cal.showingThisMonth ? 0.6 : 1
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: todayText
                                anchors.centerIn: parent
                                text: "Today"
                                color: Theme.panelFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                id: todayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cal.goToday()
                            }
                        }

                        CcIconButton {
                            code: 0xF0141  // chevron-left
                            size: 28
                            glyphSize: 16
                            onClicked: cal.shiftMonth(-1)
                        }
                        CcIconButton {
                            code: 0xF0142  // chevron-right
                            size: 28
                            glyphSize: 16
                            onClicked: cal.shiftMonth(1)
                        }
                    }

                    // Weekday initials
                    Row {
                        Repeater {
                            model: 7
                            delegate: Text {
                                required property int index
                                width: grid.cellSize
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.locale().standaloneDayName((cal.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontCaption
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: grid.height
                        clip: true

                        WheelHandler {
                            onWheel: event => cal.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
                        }

                        Grid {
                            id: grid
                            readonly property real cellSize: parent.width / 7
                            width: parent.width
                            columns: 7

                            Repeater {
                                model: cal.cells
                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    required property int index
                                    readonly property bool inMonth: modelData.getMonth() === cal.viewMonth
                                    readonly property bool isToday: cal.sameDay(modelData, cal.now)
                                    readonly property bool isSelected: cal.sameDay(modelData, cal.selected)
                                    readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6

                                    width: grid.cellSize
                                    height: 38

                                    // Selection ring
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Theme.accent
                                        opacity: cell.isSelected && !cell.isToday ? 1 : 0
                                        scale: cell.isSelected ? 1 : 0.5
                                        Behavior on opacity { NumberAnimation { duration: 180 } }
                                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                                    }

                                    // Today / hover disc
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: cell.isToday ? Theme.accent : dayMouse.containsMouse ? Theme.sliderTrack : "transparent"
                                        scale: dayMouse.pressed ? 0.85 : 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: cell.modelData.getDate()
                                        color: cell.isToday ? Theme.accentFg : !cell.inMonth ? Theme.textFaint
                                             : cell.weekend ? Theme.altFg : Theme.panelFg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontBody
                                        font.weight: cell.isToday || cell.isSelected ? Font.Bold : Font.Normal
                                    }

                                    MouseArea {
                                        id: dayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const d = cell.modelData;
                                            if (cal.sameDay(d, cal.selected)) {
                                                cal.selected = null;
                                                return;
                                            }
                                            cal.selected = d;
                                            if (!cell.inMonth) cal.shiftMonth(d < new Date(cal.viewYear, cal.viewMonth, 1) ? -1 : 1);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Selected day: what it is and how far away
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: cal.selected ? 22 : 0
                        clip: true
                        Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                        RowLayout {
                            width: parent.width
                            height: 22
                            opacity: cal.selected ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            Text {
                                Layout.leftMargin: 6
                                Layout.fillWidth: true
                                text: cal.selected ? Qt.formatDate(cal.selected, "ddd, MMM d yyyy") : ""
                                color: Theme.panelFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                            }
                            Caption {
                                Layout.rightMargin: 6
                                text: cal.selected ? cal.relative(cal.selected) : ""
                            }
                        }
                    }
                }
            }

        }
    }
}
