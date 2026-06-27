.PHONY: get analyze test coverage build-debug build-aab build-release clean run codegen

get:
	fvm flutter pub get

analyze:
	fvm flutter analyze

test:
	fvm flutter test

coverage:
	fvm flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

build-debug:
	fvm flutter build apk --debug

build-aab:
	fvm flutter build appbundle --release

build-release:
	fvm flutter build apk --release --split-per-abi

clean:
	fvm flutter clean

run:
	fvm flutter run

codegen:
	fvm flutter pub run build_runner build --delete-conflicting-outputs
