define MAKEHELP
Useful targets:
	test
endef
export MAKEHELP

NODE_BIN = ./node_modules/.bin
MOCHA = $(NODE_BIN)/mocha
MOCHA_OPTS = --compilers coffee:coffee-script/register \
	--reporter spec \
	--recursive \
	--colors \
	--require should

.PHONY: help
help:
	@echo "$$MAKEHELP"


.PHONY: test
test:
	NODE_PATH=".:$$NODE_PATH" $(MOCHA) $(MOCHA_OPTS) `find plugins -name 'test'`
