import SwiftUI
import IOBluetooth

/// A simple row for displaying a Bluetooth device name in a list.  When
/// selected it shows a checkmark to the right of the name.
struct DeviceRow: View {
    /// The device represented by this row.
    let device: IOBluetoothDevice

    /// Indicates whether this device is currently selected.  When `true` the
    /// row displays a blue checkmark.
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(device.name ?? device.addressString ?? "Unknown")
                .lineLimit(1)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(4)
    }
}