import SwiftUI
import IOBluetooth

/// Entry point for the conventional macOS application.
///
/// This struct conforms to the `App` protocol introduced in macOS 11 and
/// provides a familiar application life‑cycle. It creates a single window
/// containing a `ContentView` bound to a `BluetoothViewModel`. The window
/// is given a default size that matches the stand‑alone script. If you
/// prefer an AppKit life cycle with a custom `AppDelegate`, you can adapt
/// this file accordingly.
@main
struct BluetoothAudioReceiverApp: App {
    /// A single view model shared by the entire application.  Storing it as
    /// a `StateObject` ensures SwiftUI instantiates it once and keeps it
    /// alive for the lifetime of the app.
    @StateObject private var viewModel = BluetoothViewModel()

    var body: some Scene {
        WindowGroup("Bluetooth Audio Receiver") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 400, idealWidth: 400, maxWidth: 600,
                       minHeight: 450, idealHeight: 450, maxHeight: 600)
        }
    }
}