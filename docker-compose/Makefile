include default.properties
export $(shell sed 's/=.*//' default.properties)

HOST_IP := $(shell sh -c "ifconfig | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v 127.0.0.1" | awk '{ print $$2 }' | cut -f2 -d: | head -n1)
# Empty default value!
AUTH0_CLIENT_ID ?= not-set
IDS_IMAGE_TAG ?= 1.8.0

export HOST_IP
export AUTH0_CLIENT_ID
export IDS_IMAGE_TAG

build: show-ip up configure-ids configure-acs

show-ip:
	@echo "HOST_IP environment variable has been set as: $(HOST_IP)"

stop: ## stop running containers without removing them
	@docker-compose stop -t 120

start: ## start containers
	@docker-compose start

clean: ## stop & remove containers and volumes
	@docker-compose down -v
	
wait: ## wait for stack to start
	@sh helpers/wait-for-container-log.sh "alfresco" "Starting ProtocolHandler"
	@sh helpers/wait-for-container-log.sh "share" "Starting ProtocolHandler"

up: ## start acs
	@docker-compose up -d && make wait

ids: ## start ids
	@docker-compose up -d postgres_IDS alfresco-identity-service

configure-acs:
	@sh helpers/configure_acs.sh

configure-ids:
	@sh helpers/configure_ids.sh

show-logs: ## show logs
	docker-compose logs