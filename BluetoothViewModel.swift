import Foundation
import IOBluetooth

final class BluetoothViewModel: ObservableObject {
    @Published var devices: [IOBluetoothDevice] = []
    @Published var selected: IOBluetoothDevice?
    private let selKey = "selected_bt_addr"

    init() {
        refresh()
    }

    func refresh() {
        let list = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        devices = list.sorted { ($0.name ?? "") < ($1.name ?? "") }
        if let saved = UserDefaults.standard.string(forKey: selKey),
           let found = devices.first(where: { $0.addressString == saved }) {
            selected = found
        }
    }

    func select(_ d: IOBluetoothDevice) {
        selected = d
        UserDefaults.standard.set(d.addressString, forKey: selKey)
    }

    var isConnected: Bool {
        return selected?.isConnected() ?? false
    }

    func open() {
        guard let d = selected, !d.isConnected() else { return }
        d.openConnection()
    }

    func close() {
        guard let d = selected, d.isConnected() else { return }
        d.closeConnection()
    }
}
