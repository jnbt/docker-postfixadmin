NAME=postfixadmin
VERSION=3.0

build:
	docker build -t ${NAME} .

shell: build
	docker run --rm -it ${NAME} bash

test: build
	docker run --rm -it --net backend -P ${NAME}

init: build
	docker run --rm -it --net backend -e ADMIN_USERNAME=root@example.org -e ADMIN_PASSWORD=s3cr3t -e SETUP_PASSWORD=0th3rs3cr3t -P ${NAME} app:init

release:
	git commit -av -e -m "Upgrade to postfixadmin ${VERSION}" && \
	git tag -f ${VERSION} && \
	git push && \
	git push --tags -f
