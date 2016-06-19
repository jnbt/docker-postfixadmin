NAME=postfixadmin
VERSION=2.93

build:
	docker build -t ${NAME} .

shell: build
	docker run --rm -it ${NAME} bash

test: build
	docker run --rm -it --net backend -P ${NAME}

release:
	git commit -av -e -m "Upgrade to postfixadmin ${VERSION}" && \
	git tag -f ${VERSION} && \
	git push && \
	git push --tags -f
