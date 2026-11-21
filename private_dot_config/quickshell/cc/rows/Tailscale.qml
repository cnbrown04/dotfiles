import qs
import qs.cc

CcRow {
    available: Tailscale.installed
    code: 0xF0582  // vpn
    title: "Tailscale"
    subtitle: Tailscale.summary
    checked: Tailscale.up
    busy: Tailscale.busy
    page: "Tailscale"
    onToggled: Tailscale.toggle()
}
