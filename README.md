<p align="center">
  <img src=".github/assets/app-icon.png" width="128" height="128" alt="Browser Clutch ®">
</p>

<h1 align="center">Browser Clutch ®</h1>

<p align="center">
  <strong>A browser picker for macOS that routes URLs to different browsers based on rules.</strong><br><br>
  Tired of all links opening in the wrong browser? Browser Clutch sits in your menu bar<br>
  and intercepts every URL click. Set rules by source app or domain pattern —<br>
  Slack links open in Chrome, GitHub in Firefox, everything else in your default browser.
</p>

<p align="center">
  <a href="https://browserclutch.com">browserclutch.com</a>
</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/nikuscs/browser-clutch?style=flat-square" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5-orange?style=flat-square" alt="Swift 5">
</p>

---

## Features

- **Source-based routing** — Route URLs based on which app opened them
- **Domain-based routing** — Match exact domains, wildcards, or patterns
- **Priority rules** — Control which rule wins when multiple match
- **Private/Incognito mode** — Open URLs in private browsing mode
- **New window option** — Force URLs to open in a new browser window
- **Menu bar app** — Lives quietly in your menu bar
- **Settings panel** — Configure rules, default browser, and preferences
- **About panel** — View app version and info
- **XDG config** — Uses `~/.config/browserclutch/`
- **Zero config start** — Works out of the box with sensible defaults

---

## Screenshot

<!-- TODO: Add screenshot here -->
<p align="center">
  <em>Screenshot coming soon</em>
</p>

---

## Installation

1. Download the latest DMG from [**Releases**](../../releases/latest)
2. Open the DMG and drag **Browser Clutch ®** to Applications
3. Launch Browser Clutch ®
4. Right-click → Open (first time only, to bypass Gatekeeper)
5. Set as default browser: **System Settings → Desktop & Dock → Default web browser**

---

## FAQ

<details>
<summary><strong>How do I set Browser Clutch ® as my default browser?</strong></summary>
<br>
System Settings → Desktop & Dock → Default web browser → Browser Clutch ®
</details>

<details>
<summary><strong>Why does macOS say the app is damaged or unverified?</strong></summary>
<br>
The app isn't notarized yet. Right-click the app → Open, then click Open in the dialog.
</details>

<details>
<summary><strong>Where is the config?</strong></summary>
<br>
<code>~/.config/browserclutch/config.json</code>
</details>

<details>
<summary><strong>Where are the logs?</strong></summary>
<br>
<code>~/.config/browserclutch/debug.log</code>
</details>

<details>
<summary><strong>How do I configure rules?</strong></summary>
<br>
Open Browser Clutch ® from the menu bar and use the Settings to add rules.
</details>

---

## Roadmap

- [x] Private/Incognito mode support
- [x] Open in new window option
- [x] About panel
- [x] App menu with Settings shortcut
- [x] Use standard config directory (`~/.config/browserclutch/`)
- [ ] Chrome profile selection
- [ ] Cleanup leftover files on uninstall
- [ ] CLI support

---

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/thing`)
3. Commit your changes
4. Push and open a PR

### Development

```bash
make build    # Build
make install  # Build + install to /Applications
make run      # Launch app
make logs     # View debug logs
```

---

## License

[Non-Commercial](LICENSE.md) — Free for personal use, no commercial use without permission.

---

<p align="center">
  <sub>🐉 Here be dragons — this app was vibe coded. Use at your own risk.</sub>
</p>
