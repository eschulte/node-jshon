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
	chmod +x $@;

dist: jshon.js
	npm pack

clean:
	rm jshon

.PHONY: all clean dist
