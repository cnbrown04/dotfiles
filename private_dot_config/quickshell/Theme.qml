pragma Singleton
import Quickshell
import QtQuick

// Palette and metrics from the MacTahoe GTK theme (dark, transparent variant):
// https://github.com/vinceliuice/MacTahoe-gtk-theme  src/sass/{_colors,_variables}.scss + gnome-shell/
// Accents stay monochrome (white) instead of MacTahoe's blue; font is JetBrains Mono.
Singleton {
    // Text
    readonly property color fg: "#dedede"            // $fg_color
    readonly property color altFg: "#afafaf"         // $alt_fg_color
    readonly property color dim: "#7a7a7a"
    readonly property color panelFg: "#ffffff"       // $panel_fg (transparent panel)
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14               // 11pt body ($base_font_size)
    readonly property int fontSizeSmall: 12          // caption

    // Fills (white over glass/dark surfaces)
    readonly property color fill: "#0dffffff"        // $fill_color, 5%
    readonly property color divider: "#1affffff"     // $divider_color, 10%
    readonly property color track: "#29ffffff"       // $track_color, 16%

    // Top bar: transparent panel with pill buttons
    readonly property int barHeight: 44              // 32px pills + 6px margin top/bottom
    readonly property int pillHeight: 32             // $menuitem_size
    readonly property color panelHover: "#26ffffff"  // $panel_hover (= $panel_divider), 15%
    readonly property color panelActive: "#47ffffff" // $panel_active (= $panel_track), 28%
    readonly property color panelTextShadow: "#59000000"  // not in MacTahoe; keeps text readable on bright wallpapers
    readonly property color barScrimTop: "#4d000000"      // top-edge fade behind the bar (30% black -> transparent)

    // Popovers / notification banners
    // Panel background opacity (MacTahoe's $popover_opacity is 0.92; lighter here so the blur shows through)
    readonly property real panelOpacity: 0.80
    readonly property color panelBase: "#242424"      // $base_color
    readonly property color popoverBg: Qt.rgba(panelBase.r, panelBase.g, panelBase.b, panelOpacity)
    readonly property color popoverBorder: "#bf000000" // 1px black 75%
    readonly property color shadow: "#26000000"        // box-shadow 0 3px 5px black 15%
    readonly property int notificationRadius: 18       // $bt_radius + $base_padding * 2
    readonly property int buttonRadius: 6              // $bt_radius
    readonly property int buttonHeight: 36             // $medium_size

    readonly property color popoverRim: "#12ffffff"    // faint inner glass rim, white 7%
    readonly property color urgentBorder: "#80ffffff"  // critical banner rim
    readonly property int panelRadius: 26              // popovers: module radius + 12px padding (concentric)
    readonly property int moduleRadius: 14
    readonly property int rowRadius: 10                // hover rows in lists
    readonly property int cardRadius: 12               // workspace overview cards

    // Popover contents (Control Center, calendar, workspace overview). White overlays on the dark panel.
    readonly property color accent: "#ffffff"          // "on" state: toggles, today, active workspace, slider fill
    readonly property color accentFg: "#1c1c1c"        // icons/text drawn on top of accent
    readonly property color moduleBg: "#12ffffff"      // module tiles, white 7%
    readonly property color moduleBorder: "#0affffff"
    readonly property color hoverFill: "#1affffff"     // hovered tile / icon button / calendar day
    readonly property color rowHover: "#0dffffff"
    readonly property color rowPressed: "#17ffffff"
    readonly property color control: "#24ffffff"       // "off" round buttons and chips
    readonly property color controlHover: "#38ffffff"
    readonly property color controlPressed: "#33ffffff"
    readonly property color switchOff: "#33ffffff"
    readonly property color sliderTrack: "#1fffffff"
    readonly property color sliderMuted: "#80ffffff"
    readonly property color knobRing: "#26000000"
    readonly property color progressTrack: "#26ffffff"
    readonly property color inputBg: "#14ffffff"
    readonly property color focusRing: "#59ffffff"     // focused input border, text selection
    readonly property color textFaint: "#4dffffff"     // days outside the shown month
    // Workspace overview cards
    readonly property color cardBg: "#10ffffff"
    readonly property color cardHover: "#1cffffff"
    readonly property color cardDrop: "#30ffffff"      // a window is being dragged over it
    readonly property color cardDropBorder: "#99ffffff"
    readonly property color thumbBg: "#2b2b2b"         // window thumbnail before it has a frame
    readonly property color thumbOutline: "#26ffffff"
    readonly property color thumbOutlineHover: "#ccffffff"
    readonly property color chipBg: "#99000000"        // workspace number chip

    // Type scale for panels (pixels)
    readonly property int fontCaption: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 15
    readonly property int fontDisplay: 48              // calendar clock

    // Tooltip (.dash-label)
    readonly property color tooltipBg: "#bf000000"     // black 75%
    readonly property color tooltipFg: "#d9ffffff"     // $light_alt_fg_color, white 85%

    // Shared
    readonly property color urgent: "#ffffff"
    readonly property int radius: 6
    readonly property int radiusSmall: 4

    // Dock (MacTahoe GTK theme dash-to-dock values)
    readonly property int dockIconSize: 52
    readonly property bool dockAutoHide: true    // slide away; touch the bottom screen edge to reveal
    readonly property color dockBg: "#1affffff"         // white 10% ($dash_bg, transparent variant)
    readonly property color dockBorder: "#33ffffff"     // 1px inner rim, white 20%
    readonly property color dockDivider: "#1affffff"    // white 10%
    readonly property color dockDot: "#bfffffff"        // running dot, white 75%
    readonly property color dockDotFocused: "#ffffff"   // focused app (MacTahoe uses its accent here)
}
