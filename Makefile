APP_NAME    := Airdrop
BUILD_DIR   := build
APP_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS    := $(APP_BUNDLE)/Contents
MACOS_DIR   := $(CONTENTS)/MacOS
BINARY      := $(MACOS_DIR)/airdrop
INSTALL_DIR := $(HOME)/Applications

.PHONY: all build clean install uninstall

all: build

build: $(BINARY)
	@cp Info.plist $(CONTENTS)/Info.plist
	@codesign --force --sign - $(APP_BUNDLE)
	@echo "built $(APP_BUNDLE)"

$(BINARY): Sources/main.swift Info.plist
	@mkdir -p $(MACOS_DIR)
	@cp Info.plist $(CONTENTS)/Info.plist
	swiftc -O -framework AppKit -o $(BINARY) Sources/main.swift

LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister

install: build
	@mkdir -p $(INSTALL_DIR)
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	@$(LSREGISTER) -f $(INSTALL_DIR)/$(APP_NAME).app
	@echo "installed: $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "removed $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	@rm -rf $(BUILD_DIR)
