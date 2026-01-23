# BrowserClutch

Route URLs to different browsers based on source app or domain rules.

## Build & Deploy

```bash
make all          # Build, install, run
# or
make build        # Just build
make install      # Build + copy to /Applications
make run          # Launch app
```

**Other commands:**
```bash
make check        # Type check Swift
make logs         # Show debug logs
make logs-follow  # Tail logs
make config       # Open config file
make clean        # Clean build
```

> Note: `make build` requires Xcode (not just Command Line Tools). Use `sudo xcode-select -s /Applications/Xcode.app` if needed.

## Setup

System Settings → Desktop & Dock → Default web browser → **BrowserClutch**

## Config

`~/Library/Application Support/BrowserClutch/config.json`

```json
{
  "defaultBrowser": "com.apple.Safari",
  "rules": [
    { "id": "slack-chrome", "priority": 100, "source": { "name": "Slack" }, "browser": "com.google.Chrome" },
    { "id": "github-firefox", "priority": 90, "domain": { "pattern": "*.github.com" }, "browser": "org.mozilla.firefox" }
  ]
}
```

**Source match:** `name`, `bundle_id`, `pattern` (regex)
**Domain match:** `exact`, `pattern` (wildcard), `contains`

## Browser IDs

Safari `com.apple.Safari` · Chrome `com.google.Chrome` · Firefox `org.mozilla.firefox` · Brave `com.brave.Browser` · Edge `com.microsoft.edgemac` · Arc `company.thebrowser.Browser`

## Logs

`~/Library/Application Support/BrowserClutch/debug.log`
