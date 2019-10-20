include build.properties
export $(shell sed 's/=.*//' build.properties)

IMAGE_NAME							:=alfresco/alfresco-identity-service:$(IDENTITY_VERSION)
IMAGE_NAME_WITH_BASE_OS				:=$(IMAGE_NAME)-java8-oracle-centos7
IMAGE_NAME_WITH_BASE_OS_AND_SHA		:=$(IMAGE_NAME_WITH_BASE_OS)-$(shell git rev-parse HEAD | cut -c1-12)
export IMAGE_NAME_WITH_BASE_OS_AND_SHA


ifeq ($(SCAN_FOLDER),)
	SCAN_FOLDER:=.
endif

build: distribution tag_image push_private
	
distribution:
	./build.sh

tag_image:
	@echo "Tag docker image..."
	docker tag quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA) quay.io/$(IMAGE_NAME)
	docker tag quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA) quay.io/$(IMAGE_NAME_WITH_BASE_OS)
	
push_private:
	@echo "Push private image..."
	@docker push quay.io/$(IMAGE_NAME)
	@docker push quay.io/$(IMAGE_NAME_WITH_BASE_OS)
	@docker push quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA)

push_public:
	@echo "Tag and push public image..."
	@docker tag quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA) $(IMAGE_NAME) && docker push $(IMAGE_NAME)
	@docker tag quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA) $(IMAGE_NAME_WITH_BASE_OS) && docker push $(IMAGE_NAME_WITH_BASE_OS)
	@docker tag quay.io/$(IMAGE_NAME_WITH_BASE_OS_AND_SHA) $(IMAGE_NAME_WITH_BASE_OS_AND_SHA) && docker push $(IMAGE_NAME_WITH_BASE_OS_AND_SHA)
	
scan: # this will be executed only  on CI/CD (Bamboo) where there is a whitesource agent installed
	bash /home/bamboo/bamboo-agent-config/scripts/agent/whitesource-agent.sh -d ${SCAN_FOLDER} -product "Alfresco Identity Service" -project "Identity Service" -projectVersion "${IDENTITY_VERSION}"

run:
	@docker run -p 8080:8080 -p 9990:9990 --name alfresco-ids --rm $(PRIVATE_IMAGE)

stop:
	docker kill alfresco-ids

sh:
	docker exec -it $$(docker ps -aq --filter name=alfresco-ids) sh