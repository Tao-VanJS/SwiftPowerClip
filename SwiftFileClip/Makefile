APP_NAME = SwiftFileClip
BUNDLE = build/$(APP_NAME).app
EXECUTABLE = $(BUNDLE)/Contents/MacOS/$(APP_NAME)
PLIST = $(BUNDLE)/Contents/Info.plist

all: build

build: clean
	@mkdir -p $(BUNDLE)/Contents/MacOS
	@mkdir -p $(BUNDLE)/Contents/Resources
	@swiftc -o $(EXECUTABLE) main.swift -framework Cocoa -framework Carbon
	@cp Info.plist $(PLIST)
	@echo "Built $(BUNDLE)"

run: build
	@open $(BUNDLE)

clean:
	@rm -rf build

install: build
	@sudo cp -R $(BUNDLE) /Applications/

uninstall:
	@sudo rm -rf /Applications/$(APP_NAME).app

