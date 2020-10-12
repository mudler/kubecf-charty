CHARTY_VERSION?=0.1.3
RELEASE_CHARTY = external-db upgrades

all: deps build

.bin:
	mkdir -p .bin

.bin/charty: .bin
	@wget https://github.com/mudler/charty/releases/download/v$(CHARTY_VERSION)/charty-$(CHARTY_VERSION)-linux-amd64 -O .bin/charty
	chmod +x .bin/charty

deps: .bin/charty

clean:
	rm -rf .bin release

build:
	mkdir release || true
	for d in $(RELEASE_CHARTY); do .bin/charty package testcharts/$$d  release/ ; done
	