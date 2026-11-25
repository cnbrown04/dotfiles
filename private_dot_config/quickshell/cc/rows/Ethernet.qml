import qs.cc

CcRow {
    // While AirDrop has NetworkManager stopped, show the last state it reported (the link itself stays up)
    available: CcUtil.wiredDevice !== null || (CcUtil.netPaused && CcUtil.hadWired)
    code: 0xF0200  // ethernet
    title: "Ethernet"
    subtitle: CcUtil.wiredLink ? "Connected" : "Unplugged"
    checked: CcUtil.wiredLink
    toggleable: false
}
