import SwiftUI
import IOBluetooth

/// The main view presented by the application.  It lists all paired
/// Bluetooth devices and allows the user to select a device and open or
/// close a base‑band connection to it.
struct ContentView: View {
    /// A view model that holds device state and connection information.  The
    /// model is injected from the parent so that the same instance can be
    /// shared across different parts of the UI.
    @ObservedObject var viewModel: BluetoothViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paired Bluetooth Devices")
                .font(.headline)

            // Display the list of paired devices.  The device address is used
            // as a stable identifier because it uniquely identifies each
            // device on the system.
            List(viewModel.pairedDevices, id: \.addressString) { device in
                DeviceRow(device: device,
                          isSelected: viewModel.selectedDevice?.addressString == device.addressString)
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
                                ProgressView()
                                    .scaleEffect(0.7, anchor: .center)
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
            // Refresh the connection status periodically to keep the UI
            // responsive when the connection state changes externally.
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                viewModel.refreshConnectionState()
            }
        }
    }
}