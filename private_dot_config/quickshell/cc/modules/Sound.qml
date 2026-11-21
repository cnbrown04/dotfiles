// Output volume and microphone sliders (click the icon to mute).
import QtQuick
import QtQuick.Layouts
import qs
import qs.cc

CcModule {
    id: mod

    property var cc

    shown: cc.open
    padding: 12

    ColumnLayout {
        width: parent.width
        spacing: 8

        CcText { kind: "section"; text: "Sound" }
        CcSlider {
            Layout.fillWidth: true
            readonly property var audio: CcUtil.sink?.audio ?? null
            value: audio?.volume ?? 0
            muted: audio?.muted ?? true
            code: muted || value <= 0 ? 0xF075F : value < 0.34 ? 0xF057F : value < 0.67 ? 0xF0580 : 0xF057E
            onMoved: v => { if (audio) { audio.muted = false; ShellState.setVolume(CcUtil.sink, v); } }
            onIconClicked: if (audio) audio.muted = !audio.muted
        }
        CcText { Layout.topMargin: 2; kind: "section"; text: "Microphone" }
        CcSlider {
            Layout.fillWidth: true
            readonly property var audio: CcUtil.source?.audio ?? null
            value: audio?.volume ?? 0
            muted: audio?.muted ?? true
            code: muted ? 0xF036D : 0xF036C
            onMoved: v => { if (audio) { audio.muted = false; ShellState.setVolume(CcUtil.source, v); } }
            onIconClicked: if (audio) audio.muted = !audio.muted
        }
    }
}
