APP_NAME = Amphetamine
SCHEME = Amphetamine
BUILD_DIR = build
RELEASE_DIR = $(BUILD_DIR)/release
DMG_NAME = $(APP_NAME).dmg

.PHONY: all build clean dmg install run

all: dmg

build:
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(RELEASE_DIR)
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/derived \
		CONFIGURATION_BUILD_DIR=$(CURDIR)/$(RELEASE_DIR) \
		CODE_SIGN_IDENTITY="-" \
		build
	@echo "Build complete: $(RELEASE_DIR)/$(APP_NAME).app"

dmg: build
	@echo "Creating DMG..."
	@rm -f $(BUILD_DIR)/$(DMG_NAME)
	@mkdir -p $(BUILD_DIR)/dmg-staging
	@cp -R $(RELEASE_DIR)/$(APP_NAME).app $(BUILD_DIR)/dmg-staging/
	@ln -sf /Applications $(BUILD_DIR)/dmg-staging/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder $(BUILD_DIR)/dmg-staging \
		-ov -format UDZO \
		$(BUILD_DIR)/$(DMG_NAME)
	@rm -rf $(BUILD_DIR)/dmg-staging
	@echo "DMG created: $(BUILD_DIR)/$(DMG_NAME)"

install: build
	@echo "Installing to /Applications..."
	@rm -rf /Applications/$(APP_NAME).app
	@cp -R $(RELEASE_DIR)/$(APP_NAME).app /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

run: build
	@open $(RELEASE_DIR)/$(APP_NAME).app

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@echo "Done."

generate:
	xcodegen generate
