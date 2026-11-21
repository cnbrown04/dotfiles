import qs.cc

CcRow {
    available: CcUtil.wiredDevice !== null
    code: 0xF0200  // ethernet
    title: "Ethernet"
    subtitle: CcUtil.wiredDevice?.hasLink ? "Connected" : "Unplugged"
    checked: CcUtil.wiredDevice?.hasLink ?? false
    toggleable: false
}
