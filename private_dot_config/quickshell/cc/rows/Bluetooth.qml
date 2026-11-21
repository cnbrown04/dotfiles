import qs.cc

CcRow {
    readonly property var connected: CcUtil.btConnected

    code: !CcUtil.btOn ? 0xF00B2 : connected.length > 0 ? 0xF00B1 : 0xF00AF
    title: "Bluetooth"
    subtitle: !CcUtil.adapter ? "Unavailable"
            : !CcUtil.btOn ? "Off"
            : connected.length === 1 ? connected[0].name
            : connected.length > 1 ? connected.length + " Devices"
            : "On"
    checked: CcUtil.btOn
    toggleable: CcUtil.adapter !== null
    page: CcUtil.adapter !== null ? "Bluetooth" : ""
    onToggled: CcUtil.adapter.enabled = !CcUtil.adapter.enabled
}
