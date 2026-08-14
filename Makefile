.PHONY: build test app dmg clean

build:
	swift build --product GestureDeck

test:
	swift run GestureDeckLogicTests

app:
	./scripts/build-app.sh

dmg:
	./scripts/build-dmg.sh

clean:
	swift package clean
	rm -rf .build-arm64 .build-x86_64 dist
