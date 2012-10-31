# jshon - command line JSON parsing

#VERSION=$(shell date +%Y%m%d)
VERSION=$(shell git show -s --format="%ci" HEAD | cut -d ' ' -f 1 | tr -d '-')
#VERSION=$(grep "^#define JSHONVER" | cut -d ' ' -f 3)

all: dist

%.js: %.coffee
	coffee -c $<

jshon: jshon.js
	echo "#!/usr/bin/env node" > $@; \
	cat $< >> $@; \
	sed -i 's/^  version = .*;$$/  version = $(VERSION);/' $@; \
	chmod +x $@;

README.md: jshon.1
	echo "node.js clone of https://github.com/keenerd/jshon" > $@; \
	echo "" >> $@; echo "" >> $@; \
	groff -man -Tascii -P-cbu $<|sed 's/^/    /' >> $@

dist: jshon README.md
	npm pack

clean:
	rm -f jshon jshon.js jshon-*.tgz

.PHONY: all clean dist
