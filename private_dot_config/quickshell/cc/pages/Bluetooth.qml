// Paired Bluetooth devices: click to connect or disconnect.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.cc

CcPage {
    title: "Bluetooth"
    checked: CcUtil.btOn
    onToggled: if (CcUtil.adapter) CcUtil.adapter.enabled = !CcUtil.adapter.enabled

    CcPlaceholder {
        visible: btList.count === 0
        text: !CcUtil.btOn ? "Bluetooth is off" : "No paired devices"
    }

    CcList {
        id: btList
        model: ScriptModel {
            values: !CcUtil.btOn ? []
                : CcUtil.adapter.devices.values
                    .filter(d => d.paired || d.connected)
                    .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
        }

        delegate: CcListRow {
            required property var modelData
            readonly property var dev: modelData

            width: ListView.view.width
            code: CcUtil.btGlyph(dev.icon)
            title: dev.name
            current: dev.connected
            busy: dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting
                  || dev.pairing
            subtitle: dev.state === BluetoothDeviceState.Connecting ? "Connecting…"
                    : dev.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                    : dev.connected ? "Connected" + (dev.batteryAvailable ? " · " + CcUtil.percent(dev.battery) : "")
                    : "Not Connected"
            onClicked: dev.connected ? dev.disconnect() : dev.connect()
        }
    }
}
