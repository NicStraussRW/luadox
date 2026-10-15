VER := $(shell grep __ver luadox/version.py  | cut -d\" -f2)
# Recorded in the bundle so a built artifact says which commit it came from.
COMMIT := $(shell git rev-parse HEAD 2>/dev/null || echo unknown)
BUILT := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
# Name of the release archive without extension
ARCHIVE := luadox-$(VER)

build/luadox: build/pkg.zip
	echo '#!/usr/bin/env python3' > build/luadox
	cat build/pkg.zip >> build/luadox
	chmod 755 build/luadox

build/pkg: luadox/*
	mkdir -p build/pkg/luadox
	cp -a luadox/* build/pkg/luadox
	echo "from luadox.main import main; main()" > build/pkg/__main__.py
	touch build/pkg

build/pkg/ext: requirements.txt
	@echo "*** installing dependencies into $@/"
	pip3 install -t ./build/pkg/ext -r requirements.txt
	@# Record the bundled versions before the dist-info directories go, otherwise
	@# nothing in the artifact says which dependencies are inside it.
	@ls -d build/pkg/ext/*.dist-info | sed 's|.*/||; s|\.dist-info$$||' | sort > build/deps.txt
	@# These aren't needed
	rm -rf build/pkg/ext/bin build/pkg/ext/*.dist-info build/pkg/ext/*/*.so

build/pkg.zip: build/pkg build/pkg/ext
	@echo "*** creating bundle at build/luadox"
	@printf 'luadox %s\ncommit %s\nbuilt %s\n\nbundled dependencies:\n' \
		"$(VER)" "$(COMMIT)" "$(BUILT)" > build/pkg/BUILD-INFO
	@cat build/deps.txt >> build/pkg/BUILD-INFO
	find build -type d -name __pycache__ -prune -exec rm -rf "{}" \;
	cd build/pkg && zip -q -r ../pkg.zip .

.PHONY: docker
docker:
	docker build --pull -t luadox:latest .

.PHONY: release
release: build/luadox
	cd build && tar zcf $(ARCHIVE).tar.gz luadox
	cd build && zip $(ARCHIVE).zip luadox

.PHONY: clean
clean:
	rm -rf build
