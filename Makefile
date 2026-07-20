.PHONY: install update format lint test

install:
	shards install

update:
	shards update

format:
	crystal tool format --check

lint:
	ameba --fix
	ameba

test:
	crystal spec

clean:
	rm -rf ./temp/*
