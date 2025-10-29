import SwiftUI
import IOBluetooth

@main
struct BluetoothAudioReceiverApp: App {
    @StateObject private var vm = BluetoothViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
                .frame(minWidth: 420, minHeight: 320)
        }
    }
}
