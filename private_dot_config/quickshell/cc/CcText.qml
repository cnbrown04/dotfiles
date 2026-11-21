// Text in the Control Center's type styles, one line (titles never wrap; set wrapMode for body paragraphs).
//   kind: "title" (page headers) | "heading" (row titles, bold) | "body" | "section" (small bold labels)
//         | "caption" (state under a title) | "hint" (dim notes)
import QtQuick
import qs

Text {
    property string kind: "body"

    color: kind === "caption" ? Theme.altFg : kind === "hint" ? Theme.dim : Theme.panelFg
    font.family: Theme.font
    font.pixelSize: kind === "title" ? Theme.fontTitle
                  : kind === "section" ? Theme.fontSizeSmall
                  : kind === "caption" || kind === "hint" ? Theme.fontCaption
                  : Theme.fontBody
    font.weight: kind === "title" || kind === "heading" || kind === "section" ? Font.Bold : Font.Normal
    elide: Text.ElideRight
}
