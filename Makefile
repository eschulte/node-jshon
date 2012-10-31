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
	sed -i 's/VERSION/$(VERSION)/' $@; \
	chmod +x $@;

package.json: package_template.json
	cp $< $@; sed -i 's/VERSION/$(VERSION)/' $@;

README.md: preamble jshon.1
	rm -f $@; \
	cat preamble >> $@; \
	groff -man -Tascii -P-cbu jshon.1|sed 's/^/    /' >> $@

dist: jshon README.md package.json
	npm pack

clean:
	rm -f jshon jshon.js jshon-*.tgz package.json

.PHONY: all clean dist
