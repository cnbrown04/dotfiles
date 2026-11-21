import qs
import qs.cc

CcRow {
    code: 0xF0003  // access-point
    title: "AirDrop"
    subtitle: AirDrop.status === "off" ? "Off" : AirDrop.status === "idle" || AirDrop.status === "armed" ? "Receiving" : AirDrop.summary
    checked: AirDrop.on
    busy: AirDrop.busy
    page: "AirDrop"
    onToggled: AirDrop.toggle()
}
