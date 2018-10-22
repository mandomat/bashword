.PHONY: help
help: ## this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help

instance: ## builds a new container image with a new database. launch with `NEW_INSTANCE_NAME=mysecrets make instance`.
	@export RANDOM_PASS="$$(cat /dev/urandom | head -1 | base64 | tr -d '\n' | cut -c1-32)" && \
	./.docker/bin/dbuild \
		--squash --no-cache \
		--build-arg BASHWORD_DB_KEY="$${RANDOM_PASS}" \
		.

list: ## list the existing db images and instances.
	@echo  "\n\nAVAILABLE:\n" && docker images | egrep 'IMAGE|bashword' 2>/dev/null && \
	echo  "\n\nRUNNING:\n" && docker ps -a | egrep 'IMAGE|bashword' 2>/dev/null && echo

start: ## starts an instance of latest build of a db.
	@export REGISTRY='localhost' && \
	read -p "Enter instance name: " INSTANCE && \
	set +x && docker run \
		-d --restart=unless-stopped \
		--name bashword-$$INSTANCE \
		--entrypoint /bin/bash \
		$$REGISTRY/bashword:$$INSTANCE \
		/usr/local/bin/entrypoint.sh

dev: ## stops the existing testdb instance (if any) and recreates it mounting bashword.sh + db from test/ on the container
	@export RANDOM_PASS="$$(cat /dev/urandom | head -1 | base64 | tr -d '\n' | cut -c1-32)" && \
	export REGISTRY='localhost' && \
	export INSTANCE='testdb' && \
	if [ ! -z "$$(docker ps -a | grep bashword-$$INSTANCE)" ]; then \
		echo -n "\nFound old instance, removing: " && \
		docker stop bashword-$$INSTANCE && \
		docker rm bashword-$$INSTANCE; \
	fi && \
	echo -n "\nBuilding new testdb instance.. " && \
	echo 'n' | ./.docker/bin/dbuild \
	        --build-arg BASHWORD_DB_KEY="$${RANDOM_PASS}" \
		. && \
	echo -n "\nLaunching new testdb instance.. " && \
	docker run \
		-d --restart=unless-stopped \
		--name bashword-$$INSTANCE \
		--entrypoint /bin/bash \
		-v $$(pwd)/bashword.sh:/usr/local/bin/bashword.sh \
		$$REGISTRY/bashword:$$INSTANCE \
		/usr/local/bin/entrypoint.sh

dev-db: ## creates a new db for development purposes
	@if [ ! -e ./test/ ]; then mkdir ./test/; fi && \
	export RANDOM_PASS="$$(cat /dev/urandom | head -1 | base64 | tr -d '\n' | cut -c1-32)" && \
	echo "\nRecreating testdb in $$(pwd)/test/.." && rm -fr test/* && \
	touch test/bashword.db && \
	openssl enc -aes-256-cbc -in "test/bashword.db" -out "test/bashword.db.enc" -pass pass:"$$RANDOM_PASS" && \
	echo "New db testdb created in $$(pwd)/test/ with password $$RANDOM_PASS"

install: ## copies bw to /usr/local/bin/ (requires sudo).
	sudo cp bw /usr/local/bin/

clean: ## destroys all instances ¯\_(ツ)_/¯
	INSTANCES="$$(docker ps -a |grep bashword| awk '{print $$1}')" && \
	if [ ! -z "$$INSTANCES" ]; then \
		for i in $$INSTANCES; do \
			docker stop $$i; \
			docker rm $$i; \
		done; \
	fi
