# SwiftFileClip

SwiftFileClip is a lightweight macOS utility that displays a list of recent file paths from `~/.personal_repo_file_history`. It lets you search and paste a path using a small translucent window.

## Features

- Ctrl+Option+P global shortcut opens the window, or pastes the selected item if the window is already visible
- Up/Down arrows to navigate items
- Type to filter the file list
- Enter to paste the selected path back into the previous application
- Appearance matches the Hammerspoon version (background `rgba(0,0,0,0.7)` and white text)

## Building

```bash
cd SwiftFileClip
make build
```
This creates `build/SwiftFileClip.app`.

## Running

```bash
make run
```
Grant the app Accessibility permission the first time so it can observe key presses and send the paste keystroke.

To install system wide:

```bash
make install
```

After launching, press **Ctrl+Option+P** in any app to bring up the file selector. If the selector is visible, pressing **Ctrl+Option+P** pastes the highlighted path immediately.

## Skipping the App Switcher

To keep SwiftFileClip out of the Command&#x2011;Tab app switcher, set the `LSUIElement` key in `Info.plist` to `true` (already configured) or call `NSApp.setActivationPolicy(.accessory)` during startup. This allows the app to show windows without appearing in the app switcher.

## Launch at Login

To start SwiftFileClip automatically when you log in:

1. Build and install the app with `make install` so it resides in `/Applications`.
2. Open **System Settings** → **General** → **Login Items**.
3. Click the **+** button and choose `SwiftFileClip.app` from the Applications folder.
4. The app will now launch on every login and your file list will be available via **Ctrl+Option+P**.

