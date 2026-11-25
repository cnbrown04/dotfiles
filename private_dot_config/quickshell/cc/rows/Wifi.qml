import Quickshell.Networking
import qs.cc

CcRow {
    readonly property bool paused: CcUtil.netPaused   // AirDrop has the card (NetworkManager is stopped)

    available: CcUtil.wifiDevice !== null || paused
    code: paused || !Networking.wifiEnabled ? 0xF05AA : CcUtil.wifiNetwork ? CcUtil.wifiGlyph(CcUtil.wifiNetwork.signalStrength) : 0xF05A9
    title: "Wi-Fi"
    subtitle: paused ? "Used by AirDrop" : !Networking.wifiEnabled ? "Off" : CcUtil.wifiNetwork?.name ?? "Not Connected"
    checked: !paused && Networking.wifiEnabled
    toggleable: !paused
    page: paused ? "" : "Wifi"
    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
}
