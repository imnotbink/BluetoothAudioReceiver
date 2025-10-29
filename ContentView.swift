import SwiftUI
import IOBluetooth

struct ContentView: View {
    @ObservedObject var vm: BluetoothViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paired Bluetooth Devices")
                .font(.headline)

            List(vm.devices, id: \.addressString) { dev in
                HStack {
                    Text(dev.name ?? dev.addressString)
                    Spacer()
                    if vm.selected?.addressString == dev.addressString {
                        Text(vm.isConnected ? "Connected" : "Selected")
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.select(dev)
                }
            }

            HStack {
                Button("Refresh") { vm.refresh() }
                Spacer()
                Button(vm.isConnected ? "Close Connection" : "Open Connection") {
                    vm.isConnected ? vm.close() : vm.open()
                }
                .disabled(vm.selected == nil)
            }
        }
        .padding(16)
    }
}
