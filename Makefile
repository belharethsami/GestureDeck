.PHONY: build test app dmg login-item-integration-test clean

build:
	swift build --product GestureDeck

test:
	swift run GestureDeckLogicTests

app:
	./scripts/build-app.sh

dmg:
	./scripts/build-dmg.sh

login-item-integration-test:
	./scripts/run-login-item-integration-test.sh

clean:
	swift package clean
	rm -rf .build-arm64 .build-x86_64 dist
