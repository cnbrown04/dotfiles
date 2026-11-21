import qs
import qs.cc

CcRow {
    code: 0xF0565  // shield-check
    title: "Proton VPN"
    subtitle: ProtonVpn.summary
    checked: ProtonVpn.connected
    busy: ProtonVpn.busy
    page: "ProtonVpn"
    onToggled: ProtonVpn.toggle()
}
