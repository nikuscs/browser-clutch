.PHONY: build install run clean lint check logs

APP_NAME = BrowserClutch
BUILD_DIR = $(HOME)/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*/Build/Products/Debug
INSTALL_DIR = /Applications
APP_SUPPORT = $(HOME)/Library/Application Support/$(APP_NAME)

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

# Lint with SwiftLint (if installed)
lint:
	@which swiftlint > /dev/null && swiftlint $(APP_NAME) || echo "SwiftLint not installed (brew install swiftlint)"

# Show logs
logs:
	@cat "$(APP_SUPPORT)/debug.log" 2>/dev/null || echo "No logs yet"

# Tail logs
logs-follow:
	@tail -f "$(APP_SUPPORT)/debug.log"

# Clear logs
logs-clear:
	@rm -f "$(APP_SUPPORT)/debug.log"
	@echo "Logs cleared"

# Open config
config:
	@open "$(APP_SUPPORT)/config.json" 2>/dev/null || echo "No config yet"

# Clean build
clean:
	@xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) clean 2>&1 | tail -3
	@echo "Cleaned"

# Help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build the app"
	@echo "  install  - Build and install to /Applications"
	@echo "  run      - Run the installed app"
	@echo "  all      - Build, install, and run"
	@echo "  check    - Type check Swift files"
	@echo "  lint     - Run SwiftLint"
	@echo "  logs     - Show debug logs"
	@echo "  logs-follow - Tail debug logs"
	@echo "  logs-clear  - Clear debug logs"
	@echo "  config   - Open config file"
	@echo "  clean    - Clean build"
