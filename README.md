# BluetoothAudioReceiver for macOS

This repository contains a very small macOS application written entirely in Swift. It aims to mimic the user interface of the Windows **Bluetooth Audio Receiver** utility: when launched it shows a list of devices that have been paired with your Mac, remembers your last selection, and lets you quickly open or close a Bluetooth connection to that device.

## Features

* **Displays paired devices:** The app reads the list of paired devices from the `IOBluetoothDevice` API and displays them in a list. It sorts devices alphabetically by name or address for easy browsing.
* **Remembers your selection:** When you select a device the app records its Bluetooth address in `UserDefaults`. On subsequent launches your previously selected device is highlighted automatically.
* **Connect / disconnect:** If the selected device is currently disconnected the button reads **Open Connection**; pressing it calls `openConnection()` on the underlying `IOBluetoothDevice`. If the device is connected the button changes to **Close Connection**, invoking `closeConnection()` to tear down the connection.
* **Status feedback:** The selected device name is tinted blue when it is connected. A small activity indicator appears next to the button while a connection attempt is in progress. The view refreshes periodically so that external disconnects are reflected in the UI.

## Caveats

* **Bluetooth entitlement:** On modern versions of macOS the `IOBluetoothDevice.pairedDevices()` method returns an empty array unless your app has the `com.apple.security.device.bluetooth` entitlement. If you plan to distribute the app as a sandboxed binary you should add this entitlement to your appʼs `.entitlements` file. See the [gist discussion]【966307550843165†L253-L259】 for more details.
* **Info.plist keys:** The system will prompt for Bluetooth permission the first time you access Bluetooth APIs. Ensure that your `Info.plist` contains a `NSBluetoothAlwaysUsageDescription` (and, if supporting older OS versions, `NSBluetoothPeripheralUsageDescription`) explaining to the user why the app needs Bluetooth access. These strings are user‑facing.
* **No audio streaming:** macOS does not provide a public API to act as an A2DP sink (receive high‑quality stereo audio from another device). This sample only manages connections using the baseband layer; it does not implement an audio sink. If you are looking for full audio‑receiver functionality you may need to explore third‑party or private APIs.

## Running the app

The simplest way to experiment with the app is to run the Swift script directly. On macOS 10.15 or later you can execute the script without Xcode:

```bash
chmod +x BluetoothAudioReceiver.swift
./BluetoothAudioReceiver.swift
```

When the window appears it will show any devices you have already paired with your Mac. Click on a device name to select it, then use the **Open Connection** button to connect. If the device supports a baseband connection you should see its status change and the label turn blue. Press **Close Connection** to disconnect.

### Compiling a binary

If you prefer to compile a standalone binary you can invoke the Swift compiler directly:
To build a conventional macOS app you have two options:

### Use the included sample project


## Building with Xcode


To build a conventional macOS app you have two options:

repository now contains a `mac_app` directory with a minimal SwiftUI application. It defines `BluetoothViewModel`, `ContentView` and `DeviceRow` as separate files and an `@main` entry point in `BluetoothAudioReceiverApp.swift`. It also includes a sample `Info.plist` with an `NSBluetoothAlwaysUsageDescription` key.

To use this approach:

1. Open Xcode and select **File → Open…**, then choose the `mac_app` folder. Xcode will recognise it as a Swift package and display the files.
2. Create a new **macOS App** target if one isn't created automatically. Add the files from `mac_app` to your target.
3. Under **Frameworks, Libraries, and Embedded Content** add **IOBluetooth.framework** so the Bluetooth APIs link correctly.
4. Create an `.entitlements` file and enable `com.apple.security.device.bluetooth` so that `IOBluetoothDevice.pairedDevices()` returns your paired devices【966307550843165†L253-L259】.
5. Edit the bundle identifier in `Info.plist` as appropriate for your team; keep the `NSBluetoothAlwaysUsageDescription` key and customise the message shown to users.
6. Build and run the app. It will behave the same as the script but appears as a fully fledged macOS application.

### Create a project manually

Alternatively you can start from scratch. Create a new **macOS App** project using Swift and SwiftUI and then copy the code from this repository into your new target:

1.11. Add the `IOBluetooth.framework` under **Frameworks, Libraries, and Embedded Content**.
2. Replace the content of your automatically generated `ContentView` with the implementation found in this repository.
3. Add a new Swift file (`BluetoothViewModel.swift`) and copy the `BluetoothViewModel` class.
4. Include the `DeviceRow` struct in its own Swift file or copy the `DeviceRow` implementation.
5. Create an `.entitlements` file enabling `com.apple.security.device.bluetooth` and attach it to the target.
6. Add the `NSBluetoothAlwaysUsageDescription` key to your `Info.plist` with a message explaining why the app uses Bluetooth.Include the `DeviceRow` struct in its own Swift file or copy the `DeviceRow` implementation.
5. Create an `.entitlements` file enabling `com.apple.security.device.bluetooth` and attach it to the target.
6. Add the `NSBluetoothAlwaysUsageDescription` key to your `Info.plist` with a message explaining why the app uses Bluetooth.scription` key to your `Info.plist` with a message explaining why the app uses Bluetooth.its own Swift file or alongside `ContentView`.
6. Create an `.entitlements` file enabling `com.apple.security.device.bluetooth` and attach it to the target.
7. Add a `NSBluetoothAlwaysUsageDescription` key to your `Info.plist` explaining why you need Bluetooth.

After these steps you can build and run the app from Xcode. The interface will be identical to the script version but signed and sandboxed according to your team configuration.

```bash
swiftc -o BluetoothAudioReceiver BluetoothAudioReceiver.swift -framework IOBluetooth -framework AppKit -framework SwiftUI
```

This will produce an executable named `BluetoothAudioReceiver` in the current directory. When you run it the window will behave the same as the script. You may need to codesign the binary with the Bluetooth entitlement if you want to distribute it outside of your local machine.

## Building with Xcode
uration.

## Credits

The Bluetooth device enumeration uses the `IOBluetoothDevice.pairedDevices()` API, which requires a Bluetooth entitlement on modern macOS versions【966307550843165†L253-L259】. The concept of listing paired devices was inspired by an [example gist] that iterates over known devices and prints their properties【966307550843165†L100-L121】.
