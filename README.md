# Ballast

> Keep your audio balance from drifting!

There is, *still*, a long standing MacOS bug where your balance may drift when volume buttons are pressed while CPU is under heavy load 🤷‍♀️.

Ever noticed your audio not quite right? Only to discover your audio balance slightly off 😔

This free app keeps your balance stable and center. Lives in your Menu Bar.

<img width="292" alt="Ballast App Closed" src="https://github.com/jamsinclair/ballast/raw/master/screenshots/ballast-closed.png">
<img width="292" alt="Ballast App Open" src="https://github.com/jamsinclair/ballast/raw/master/screenshots/ballast-open.png">

## Installation
👉 Download Zip from the [latest release page](https://github.com/jamsinclair/ballast/releases/latest) (macOS 10.12 or later required)

📝 Copy `ballast.app` to your Applications folder.

⚠️ You will likely need to give permission to open app from unidentified developer. See: https://support.apple.com/kb/ph25088

## Features
- 😴 Idles in the background, only activated on system audio changes
- 📝 Keep track of how many times your balance drifts
- 🚀 Option to launch at login
- 🙅‍♀️ Option to disable functionality

## FAQ

- **Why can I not open the app after installing?**<br>
  As a security measure MacOS won't open apps from unidentified developers.
  This is because I do not have an Apple Developers subscription, so cannot sign the app.
  To open see https://support.apple.com/kb/ph25088?locale=en_US

- **How do I stop the app from centering balance?**<br>
  Two options:
  1. Quit the app from the menu bar option<br>
  OR
  1. Disable the app from the menu bar option

- **I found a bug or problem?**<br>
  Great work Sherlock! 🕵️‍♂️ It’s elementary. Please [open an issue](https://github.com/jamsinclair/ballast/issues/new) on this GitHub repo. Or submit a Pull Request 🙇‍♀️

- **I have an idea for improvement**<br>
  Let me know by [opening an issue](https://github.com/jamsinclair/ballast/issues/new). All welcome!

## Building for Development
**Prerequisites:**
- Xcode (Install via Appstore)
- [Carthage](https://github.com/Carthage/Carthage#installing-carthage) - Dependency Manager

**Steps**
1. Clone this repository locally
1. Run `carthage bootstrap` in your terminal, from project root, to install dependencies
1. Open project with Xcode, make changes and build!

**Optional**

To build from command line run:
```shell
xcodebuild -configuration Release build
```

The built app can then be found in the project folder at `/build/release`
