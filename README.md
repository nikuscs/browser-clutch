<p align="center">
  <img src="BrowserClutch/icon.icon/Assets/icon.png" width="128" height="128" alt="BrowserClutch">
</p>

<h1 align="center">BrowserClutch</h1>

<p align="center">
  <strong>Route URLs to different browsers based on rules</strong><br>
  Open links from Slack in Chrome, GitHub in Firefox, everything else in Safari.
</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/user/browser-clutch?style=flat-square" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5-orange?style=flat-square" alt="Swift 5">
</p>

---

## Features

- **Source-based routing** — Route URLs based on which app opened them
- **Domain-based routing** — Match exact domains, wildcards, or patterns
- **Priority rules** — Control which rule wins when multiple match
- **Menu bar app** — Lives quietly in your menu bar
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
2. Open the DMG and drag **BrowserClutch** to Applications
3. Launch BrowserClutch
4. Right-click → Open (first time only, to bypass Gatekeeper)
5. Set as default browser: **System Settings → Desktop & Dock → Default web browser**

---

## Configuration

Config file: `~/Library/Application Support/BrowserClutch/config.json`

```json
{
  "defaultBrowser": "com.apple.Safari",
  "rules": [
    { "source": { "name": "Slack" }, "browser": "com.google.Chrome" },
    { "domain": { "pattern": "*.github.com" }, "browser": "org.mozilla.firefox" }
  ]
}
```

### Browser IDs

| Browser | Bundle ID |
|---------|-----------|
| Safari | `com.apple.Safari` |
| Chrome | `com.google.Chrome` |
| Firefox | `org.mozilla.firefox` |
| Brave | `com.brave.Browser` |
| Edge | `com.microsoft.edgemac` |
| Arc | `company.thebrowser.Browser` |

---

## FAQ

<details>
<summary><strong>How do I set BrowserClutch as my default browser?</strong></summary>
<br>
System Settings → Desktop & Dock → Default web browser → BrowserClutch
</details>

<details>
<summary><strong>Why does macOS say the app is damaged or unverified?</strong></summary>
<br>
The app isn't notarized yet. Right-click the app → Open, then click Open in the dialog.
</details>

<details>
<summary><strong>Where are the logs?</strong></summary>
<br>
<code>~/Library/Application Support/BrowserClutch/debug.log</code>
</details>

<details>
<summary><strong>Can I match URLs by regex?</strong></summary>
<br>
Yes. Use <code>"source": { "pattern": "regex" }</code> for apps or <code>"domain": { "pattern": "*.example.com" }</code> for domains.
</details>

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

MIT
