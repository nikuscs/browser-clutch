.PHONY: build install run clean lint format check test logs setup release patch minor major

APP_NAME = BrowserClutch
PROJECT = $(APP_NAME).xcodeproj/project.pbxproj
BUILD_DIR = $(HOME)/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*/Build/Products/Debug
INSTALL_DIR = /Applications
CONFIG_DIR = $(HOME)/.config/browserclutch

# Setup development environment
setup:
	@echo "Installing dependencies..."
	@which brew > /dev/null || (echo "Homebrew required: https://brew.sh" && exit 1)
	@brew bundle
	@echo "Done! Run 'make build' to build the app."

# Build the app
build:
	@echo "Building..."
	@xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -configuration Debug build 2>&1 | tail -5

# Install to /Applications
install: build
	@echo "Installing..."
	@pkill $(APP_NAME) 2>/dev/null || true
	@sleep 0.5
	@cp -R $(BUILD_DIR)/$(APP_NAME).app $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

# Run the app
run:
	@open $(INSTALL_DIR)/$(APP_NAME).app

# Build, install, and run
all: install run

# Type check Swift files
check:
	@swiftc -typecheck -sdk $$(xcrun --show-sdk-path --sdk macosx) $(APP_NAME)/*.swift

# Lint with SwiftLint (auto-installs if missing)
lint:
	@which swiftlint > /dev/null || (echo "Installing SwiftLint..." && brew install swiftlint)
	@swiftlint lint --strict

# Format with SwiftFormat
format:
	@which swiftformat > /dev/null || (echo "Installing SwiftFormat..." && brew install swiftformat)
	@swiftformat $(APP_NAME)

# Run tests
test:
	@echo "Running tests..."
	@xcodebuild test -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -destination 'platform=macOS' 2>&1 | grep -E '(Test Case|passed|failed|error:)' || true

# Show logs
logs:
	@cat "$(CONFIG_DIR)/debug.log" 2>/dev/null || echo "No logs yet"

# Tail logs
logs-follow:
	@tail -f "$(CONFIG_DIR)/debug.log"

# Clear logs
logs-clear:
	@rm -f "$(CONFIG_DIR)/debug.log"
	@echo "Logs cleared"

# Open config
config:
	@open "$(CONFIG_DIR)/config.json" 2>/dev/null || echo "No config yet"

# Clean build
clean:
	@xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) clean 2>&1 | tail -3
	@echo "Cleaned"

# Get current version
version:
	@grep 'MARKETING_VERSION' $(PROJECT) | head -1 | sed 's/.*= //' | tr -d ';'

# Release helpers
patch: _bump_patch _release
minor: _bump_minor _release
major: _bump_major _release

_get_version = $(shell grep 'MARKETING_VERSION' $(PROJECT) | head -1 | sed 's/.*= //' | tr -d ';')

_bump_patch:
	$(eval V := $(shell echo $(_get_version) | awk -F. '{print $$1"."$$2"."$$3+1}'))
	@sed -i '' 's/MARKETING_VERSION = .*/MARKETING_VERSION = $(V);/' $(PROJECT)
	@echo "Bumped to $(V)"

_bump_minor:
	$(eval V := $(shell echo $(_get_version) | awk -F. '{print $$1"."$$2+1".0"}'))
	@sed -i '' 's/MARKETING_VERSION = .*/MARKETING_VERSION = $(V);/' $(PROJECT)
	@echo "Bumped to $(V)"

_bump_major:
	$(eval V := $(shell echo $(_get_version) | awk -F. '{print $$1+1".0.0"}'))
	@sed -i '' 's/MARKETING_VERSION = .*/MARKETING_VERSION = $(V);/' $(PROJECT)
	@echo "Bumped to $(V)"

_release:
	$(eval V := $(_get_version))
	@git add $(PROJECT)
	@git commit -m "Release v$(V)"
	@git tag v$(V)
	@git push && git push origin v$(V)
	@echo "Released v$(V)"

# Help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Development:"
	@echo "  setup       - Install dev dependencies"
	@echo "  build       - Build the app"
	@echo "  install     - Build and install to /Applications"
	@echo "  run         - Run the installed app"
	@echo "  all         - Build, install, and run"
	@echo "  test        - Run unit tests"
	@echo "  lint        - Run SwiftLint"
	@echo "  format      - Format code with SwiftFormat"
	@echo "  check       - Type check Swift files"
	@echo "  clean       - Clean build"
	@echo ""
	@echo "Config & Logs:"
	@echo "  config      - Open config file"
	@echo "  logs        - Show debug logs"
	@echo "  logs-follow - Tail debug logs"
	@echo "  logs-clear  - Clear debug logs"
	@echo ""
	@echo "Release:"
	@echo "  version     - Show current version"
	@echo "  patch       - Release patch (1.0.0 -> 1.0.1)"
	@echo "  minor       - Release minor (1.0.0 -> 1.1.0)"
	@echo "  major       - Release major (1.0.0 -> 2.0.0)"
