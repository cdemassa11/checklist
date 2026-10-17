# Moment prototype for iPhone

A small iOS app that runs the two HTML prototypes in `../prototype/` full-screen on a real iPhone:

- **Onboarding** (`moment-onboarding.html`) opens first: sign-up, then making a group by holding phones together.
- **Shuffle** (`moment-shuffle.html`) opens when you tap the "Time to capture a moment" notification at the end of onboarding.

Shake the phone at any point to switch between the two.

## Run it

You need a Mac with Xcode 15 or later, and an iPhone on iOS 16 or later (or the iOS Simulator).

1. Open `ios/MomentPrototype.xcodeproj` in Xcode.
2. Select the **MomentPrototype** target, open **Signing & Capabilities**, and choose your **Team**. A free personal Apple ID works. If Xcode says the bundle ID is taken, change `com.example.MomentPrototype` to something unique, like `com.yourname.moment`.
3. Plug in your iPhone, pick it as the run destination at the top of the window, and press **Run** (⌘R).
4. The first time, the iPhone may block the app. Go to **Settings > General > VPN & Device Management**, trust your developer profile, then open the app again. Newer iOS versions also ask you to turn on **Developer Mode** in **Settings > Privacy & Security**.

## Good to know

- The app shows the same HTML files as the web prototypes, so any edit to `prototype/*.html` shows up the next time you run from Xcode.
- The control panel and the drawn phone frame are hidden on device. Use the real screen instead.
- On the group screen, the friends' phones sit in a row at the bottom. Drag one up onto the screen to "bump" it.
- Haptics come through as real taps from the iPhone's vibration motor. Sounds play even with the silent switch on.
- The fonts load from Google Fonts. Without internet the text falls back to system fonts.
