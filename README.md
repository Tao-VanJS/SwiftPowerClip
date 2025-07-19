# SwiftPowerClip

SwiftPowerClip is a lightweight macOS clipboard history tool inspired by the Hammerspoon PowerClip webview. It stores recent clipboard items and lets you search and paste them using a small translucent window.

## Features

- Ctrl+V global shortcut opens the window, or pastes the selected item if the window is already visible
- Up/Down arrows to navigate items
- Type to filter clipboard history
- Enter to paste the selected item back into the previous application
- Appearance matches the Hammerspoon version (background `rgba(0,0,0,0.7)` and white text)
- Clipboard history persists across launches

## Building

```bash
cd SwiftPowerClip
make build
```
This creates `build/SwiftPowerClip.app`.

## Running

```bash
make run
```
Grant the app Accessibility permission the first time so it can observe key presses and send the paste keystroke.

To install system wide:

```bash
make install
```

After launching, press **Ctrl+V** in any app to bring up the clipboard selector. If the selector is visible, pressing **Ctrl+V** pastes the highlighted item immediately.

## Skipping the App Switcher

To keep SwiftPowerClip out of the Command&#x2011;Tab app switcher, set the `LSUIElement` key in `Info.plist` to `true` (already configured) or call `NSApp.setActivationPolicy(.accessory)` during startup. This allows the app to show windows without appearing in the app switcher.

## Launch at Login

To start SwiftPowerClip automatically when you log in:

1. Build and install the app with `make install` so it resides in `/Applications`.
2. Open **System Settings** → **General** → **Login Items**.
3. Click the **+** button and choose `SwiftPowerClip.app` from the Applications folder.
4. The app will now launch on every login and your clipboard history will be available via **Ctrl+V**.

