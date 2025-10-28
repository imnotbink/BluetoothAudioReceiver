#!/usr/bin/env swift

/*
 This script implements a very simple macOS application that mimics the
 behaviour of the “Bluetooth Audio Receiver” utility found on Windows.

 The program relies on macOSʼs `IOBluetooth` framework to list devices that
 have been paired with your Mac.  When you run the script it opens a small
 window listing every paired device.  Selecting a device stores its
 Bluetooth address in `UserDefaults` so the choice will persist across
 launches.  Beneath the list youʼll see the currently selected device name
 together with a button for opening or closing a base‑band connection to
 that device.  When a device is connected the label is tinted blue to
 reflect its active state.  You can click the button again to tear down
 the connection.  The view refreshes itself every few seconds to update
 connection state.

 ❖ Requirements

 • macOS 10.15 or later with Bluetooth hardware.
 • The `IOBluetooth` framework must be available at run time.  If you
   intend to distribute this as a signed, sandboxed application you will
   need to add the Bluetooth entitlement (`com.apple.security.device.bluetooth`)
   to your entitlements file.  Without the entitlement, calls such as
   `IOBluetoothDevice.pairedDevices()` will return an empty array on
   modern versions of macOS【966307550843165†L253-L259】.

 • Your `Info.plist` should include a `NSBluetoothAlwaysUsageDescription`
   entry explaining to the user why you need access to Bluetooth.  This
   description will be presented in the permission prompt.

 Because this script uses SwiftUI and AppKit directly from a Swift shebang
 script, you can compile it into an executable using `swiftc` or simply
 execute it with `./BluetoothAudioReceiver.swift`.  To build an app bundle
 using Xcode, copy the classes and views into a new SwiftUI macOS target
 and include the required entitlements and Info.plist entries.
*/

import AppKit
import SwiftUI
import IOBluetooth

@available(macOS 10.15, *)
final class BluetoothViewModel: ObservableObject {
    /// A list of all devices that are paired with the host Mac.  These are
    /// populated at initialization and sorted alphabetically by name or address.
    @Published var pairedDevices: [IOBluetoothDevice] = []

    /// The currently selected device.  When set, its address is stored in
    /// `UserDefaults` so that it will be recalled on the next launch.
    @Published var selectedDevice: IOBluetoothDevice?

    /// A flag that indicates whether a connection attempt is in progress.  The
    /// UI can use this to disable buttons or show a spinner while waiting for
    /// `openConnection()` to return.
    @Published var isConnecting: Bool = false

    init() {
        loadPairedDevices()
        loadSavedSelection()
    }

    /// Refreshes the list of paired devices using the IOBluetooth API.  On
    /// Ventura and later the Bluetooth entitlement must be present; otherwise
    /// this function will return an empty array【966307550843165†L253-L259】.
    func loadPairedDevices() {
        if let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            self.pairedDevices = devices.sorted {
                let lhsName = $0.name ?? $0.addressString ?? ""
                let rhsName = $1.name ?? $1.addressString ?? ""
                return lhsName.localizedCompare(rhsName) == .orderedAscending
            }
        }
    }

    /// Loads the previously selected device from user defaults (if any) and
    /// updates the `selectedDevice` property.  This uses the deviceʼs
    /// Bluetooth address as the key.
    func loadSavedSelection() {
        guard let savedAddress = UserDefaults.standard.string(forKey: "SelectedDeviceAddress"),
              let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }
        if let matched = devices.first(where: { $0.addressString == savedAddress }) {
            self.selectedDevice = matched
        }
    }

    /// Updates the selection when the user clicks on a device in the list.  The
    /// deviceʼs address is stored in user defaults for persistence.
    func selectDevice(_ device: IOBluetoothDevice) {
        selectedDevice = device
        UserDefaults.standard.set(device.addressString, forKey: "SelectedDeviceAddress")
        // notify observers explicitly because UserDefaults changes donʼt
        // automatically trigger @Published updates.
        objectWillChange.send()
    }

    /// Forces a refresh of any views bound to connection state.  This method
    /// does nothing beyond sending a change notification; however, the UI
    /// reads properties such as `isConnected()` on the selected device which
    /// may have changed since the last render.
    func refreshConnectionState() {
        objectWillChange.send()
    }

    /// Attempts to open or close the connection to the selected device.  If the
    /// device is already connected, it will call `closeConnection()`; otherwise
    /// it will start a connection attempt on a background queue.  Once the
    /// attempt finishes, the UI will be refreshed.  Note that `openConnection()`
    /// returns an `IOReturn` code which is ignored here; error handling could
    /// be added if desired.
    func connectOrDisconnect() {
        guard let device = selectedDevice else { return }
        if device.isConnected() {
            device.closeConnection()
            // Immediately refresh the UI so the button updates without waiting
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

@available(macOS 10.15, *)
struct DeviceRow: View {
    let device: IOBluetoothDevice
    let isSelected: Bool
    var body: some View {
        HStack {
            Text(device.name ?? device.addressString ?? "Unknown")
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(4)
    }
}

@available(macOS 10.15, *)
struct ContentView: View {
    @ObservedObject var viewModel: BluetoothViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paired Bluetooth Devices")
                .font(.headline)

            // Use the deviceʼs Bluetooth address as the list identifier.  The
            // `addressString` property returns a unique string for each
            // paired device.
            List(viewModel.pairedDevices, id: \.addressString) { device in
                DeviceRow(device: device, isSelected: viewModel.selectedDevice?.addressString == device.addressString)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectDevice(device)
                    }
            }
            .frame(minHeight: 200, maxHeight: 300)

            if let selected = viewModel.selectedDevice {
                HStack {
                    Text("Selected: \(selected.name ?? selected.addressString ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(selected.isConnected() ? .blue : .primary)
                    Spacer()
                    Button(action: {
                        viewModel.connectOrDisconnect()
                    }) {
                        HStack {
                            if viewModel.isConnecting {
                                ProgressView().scaleEffect(0.7, anchor: .center)
                            }
                            Text(selected.isConnected() ? "Close Connection" : "Open Connection")
                        }
                    }
                    .disabled(viewModel.isConnecting)
                }
            } else {
                Text("Select a device to connect.")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Use a timer to periodically refresh the connection status.  This
            // helps keep the UI in sync if the device disconnects externally.
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                viewModel.refreshConnectionState()
            }
        }
    }
}

@available(macOS 10.15, *)
final class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}

@available(macOS 10.15, *)
final class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let windowDelegate = WindowDelegate()
    let viewModel = BluetoothViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let size = CGSize(width: 400, height: 450)
        window.setContentSize(size)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.delegate = windowDelegate
        window.title = "Bluetooth Audio Receiver"
        let rootView = ContentView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(hostingView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@available(macOS 10.15, *)
let app = NSApplication.shared
@available(macOS 10.15, *)
let delegate = AppDelegate()
@available(macOS 10.15, *)
app.delegate = delegate
@available(macOS 10.15, *)
app.run()