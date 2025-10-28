import Foundation
import IOBluetooth
import SwiftUI

/// A view model responsible for maintaining the list of paired devices,
/// tracking the currently selected device and managing connection state.  It
/// exposes `@Published` properties so that SwiftUI views update whenever
/// underlying values change.
final class BluetoothViewModel: ObservableObject {
    /// All devices that have been paired with the host Mac.  On macOS 13
    /// and later you must add the `com.apple.security.device.bluetooth`
    /// entitlement to your app for this property to be populated【966307550843165†L253-L259】.
    @Published var pairedDevices: [IOBluetoothDevice] = []

    /// The currently selected device.  When set, its Bluetooth address is
    /// stored in user defaults so that the selection persists across
    /// launches.
    @Published var selectedDevice: IOBluetoothDevice?

    /// Indicates whether a connection attempt is in progress.  When `true`,
    /// the UI can disable buttons or show an activity indicator.
    @Published var isConnecting: Bool = false

    init() {
        loadPairedDevices()
        loadSavedSelection()
    }

    /// Populates the `pairedDevices` array by querying `IOBluetoothDevice`.
    /// Devices are sorted alphabetically by name or address to make them
    /// easier to scan.  If the Bluetooth entitlement is missing this
    /// method will return an empty array on modern versions of macOS【966307550843165†L253-L259】.
    func loadPairedDevices() {
        if let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            pairedDevices = devices.sorted {
                let lhsName = $0.name ?? $0.addressString ?? ""
                let rhsName = $1.name ?? $1.addressString ?? ""
                return lhsName.localizedCompare(rhsName) == .orderedAscending
            }
        }
    }

    /// Loads the saved Bluetooth address from `UserDefaults` and updates
    /// `selectedDevice` accordingly.  If the saved address is not found
    /// among the currently paired devices nothing happens.
    func loadSavedSelection() {
        guard let savedAddress = UserDefaults.standard.string(forKey: "SelectedDeviceAddress"),
              let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }
        if let matched = devices.first(where: { $0.addressString == savedAddress }) {
            selectedDevice = matched
        }
    }

    /// Handles selection when the user taps on a device in the list.  The
    /// deviceʼs Bluetooth address is stored persistently so that it can be
    /// restored on the next launch.
    func selectDevice(_ device: IOBluetoothDevice) {
        selectedDevice = device
        UserDefaults.standard.set(device.addressString, forKey: "SelectedDeviceAddress")
        // Manually send a change notification because storing the address
        // doesnʼt automatically trigger `@Published` updates.
        objectWillChange.send()
    }

    /// Forces a refresh of any views bound to connection state.  This is
    /// useful when an external event changes the deviceʼs connection status.
    func refreshConnectionState() {
        objectWillChange.send()
    }

    /// Opens or closes the connection to the selected device.  If the device
    /// is currently connected it will call `closeConnection()`; otherwise it
    /// launches a background task to open the connection.  Once the attempt
    /// finishes, the UI is refreshed.  The return value from
    /// `openConnection()` is ignored but you can add error handling if
    /// desired.
    func connectOrDisconnect() {
        guard let device = selectedDevice else { return }
        if device.isConnected() {
            device.closeConnection()
            objectWillChange.send()
        } else {
            isConnecting = true
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                _ = device.openConnection()
                DispatchQueue.main.async {
                    self?.isConnecting = false
                    self?.objectWillChange.send()
                }
            }
        }
    }
}