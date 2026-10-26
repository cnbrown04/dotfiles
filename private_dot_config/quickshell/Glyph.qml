// A JetBrainsMono Nerd Font icon by codepoint (https://www.nerdfonts.com/cheat-sheet), in a size x size box.
// Nerd Font glyphs sit off-center in their advance width (and vary per glyph), so the text is positioned by its
// measured ink box: the visible icon is centered exactly, and scale/rotation pivot on its middle.
import QtQuick

Item {
    id: glyph

    property int code
    property int size: 16
    property color color: Theme.fg

    implicitWidth: size
    implicitHeight: size

    TextMetrics {
        id: metrics
        font: label.font
        text: label.text
    }

    Text {
        id: label
        readonly property rect ink: metrics.tightBoundingRect   // relative to the baseline origin
        x: Math.round((glyph.width - ink.width) / 2 - ink.x)
        y: Math.round((glyph.height - ink.height) / 2 - ink.y - baselineOffset)
        text: String.fromCodePoint(glyph.code)
        color: glyph.color
        font.family: Theme.font
        font.pixelSize: glyph.size
    }
}
