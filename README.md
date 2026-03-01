# Amphetamine

A lightweight macOS menu bar app that keeps your Mac awake. No Dock icon, no clutter — just a small icon in your menu bar.

## Features

- **Timed sessions** — Keep your Mac awake for 15 min, 30 min, 1h, 2h, 4h, 8h, or indefinitely
- **Menu bar icon** — Lives entirely in the menu bar with no Dock presence
- **Customizable icon** — Choose from 6 different menu bar icons (pill, bolt, coffee cup, flame, eye, rabbit)
- **Countdown display** — Optionally show remaining time next to the icon in the menu bar
- **Mouse jiggler** — Moves the cursor imperceptibly every 4 minutes to keep Slack and other apps showing you as "active"
- **Launch at login** — Start automatically when you log in
- **Tiny footprint** — ~60KB DMG, ~190KB binary. No Electron, no web views, pure native Swift

## Requirements

- macOS 13.0 (Ventura) or later

## Installation

### Download

1. Download the latest `Amphetamine.dmg` from the [Releases](../../releases) page
2. Open the DMG and drag **Amphetamine** to your Applications folder
3. Launch Amphetamine from Applications
4. Since the app is not notarized, macOS will block it the first time. Right-click the app → **Open** → **Open** to allow it

### Build from source

Prerequisites: [Xcode](https://developer.apple.com/xcode/) and [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
# Install XcodeGen (if you don't have it)
brew install xcodegen

# Clone and build
git clone https://github.com/YOUR_USERNAME/amphetamine.git
cd amphetamine
xcodegen generate
make dmg
```

The DMG will be at `build/Amphetamine.dmg`. Or use `make install` to copy directly to `/Applications`.

#### Other make targets

| Command | Description |
|---------|-------------|
| `make build` | Compile the release .app |
| `make dmg` | Build and package as DMG |
| `make install` | Build and copy to /Applications |
| `make run` | Build and launch |
| `make clean` | Remove build artifacts |
| `make generate` | Regenerate the Xcode project |

## Usage

Click the icon in your menu bar to open the dropdown:

1. **Pick a duration** — Select how long to keep your Mac awake
2. **End session** — Click "End Session" to stop early
3. **Mouse jiggler** — Toggle "Keep Slack Active" to prevent going idle in chat apps
4. **Change icon** — Open the "Menu Bar Icon" submenu to pick a different icon
5. **Show countdown** — Toggle "Show Time in Menu Bar" to display remaining time next to the icon

The icon switches from outline to filled when a session is active.

## How it works

Amphetamine uses the macOS [`IOPMAssertionCreateWithName`](https://developer.apple.com/documentation/iokit/1557134-iopmassertioncreatewithname) API to create a power assertion that prevents the system from idle-sleeping. This is the same mechanism used by the built-in `caffeinate` command. The assertion is released when the session ends or the app quits.

The mouse jiggler uses `CGWarpMouseCursorPosition` to move the cursor 1 pixel and back every 4 minutes — invisible to the user but enough to register as activity.

## Project structure

```
Amphetamine/
├── AmphetamineApp.swift    # App entry point, MenuBarExtra with dynamic icon
├── MenuBarView.swift       # Dropdown menu UI
├── PowerManager.swift      # IOKit power assertion wrapper
├── SessionTimer.swift      # Countdown timer and session management
├── MouseJiggler.swift      # Periodic mouse movement
├── MenuBarIcon.swift       # Available menu bar icon options
├── Info.plist              # LSUIElement=true (menu bar only)
└── Assets.xcassets/        # Asset catalog
```

## Author

[Thanos Samarinas](https://github.com/YOUR_USERNAME)

## License

MIT © [Thanos Samarinas](LICENSE)
