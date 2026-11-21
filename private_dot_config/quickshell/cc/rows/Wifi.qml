import Quickshell.Networking
import qs.cc

CcRow {
    available: CcUtil.wifiDevice !== null
    code: Networking.wifiEnabled ? (CcUtil.wifiNetwork ? CcUtil.wifiGlyph(CcUtil.wifiNetwork.signalStrength) : 0xF05A9) : 0xF05AA
    title: "Wi-Fi"
    subtitle: !Networking.wifiEnabled ? "Off" : CcUtil.wifiNetwork?.name ?? "Not Connected"
    checked: Networking.wifiEnabled
    page: "Wifi"
    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
}
