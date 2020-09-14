HOST_IP := $(shell sh -c "ifconfig | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v 127.0.0.1" | awk '{ print $$2 }' | cut -f2 -d: | head -n1)

export HOST_IP

build: show-ip up

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

show-logs: ## show logs
	docker-compose logs