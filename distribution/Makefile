include build.properties
export $(shell sed 's/=.*//' build.properties)

PRIVATE_IMAGE	:=quay.io/alfresco/alfresco-identity-service:$(IDENTITY_VERSION)
PUBLIC_IMAGE	:=alfresco/alfresco-identity-service:$(IDENTITY_VERSION)

ifeq ($(SCAN_FOLDER),)
	SCAN_FOLDER:=.
endif

build: distribution image
	
distribution:
	./build.sh

image:
	docker build --force-rm=true --no-cache=true --build-arg IDENTITY_VERSION=$(IDENTITY_VERSION) -t $(PRIVATE_IMAGE) -f Dockerfile .
	docker tag $(PRIVATE_IMAGE) $(PUBLIC_IMAGE)

push_private:
	@docker push $(PRIVATE_IMAGE)

push_public:
	@docker push $(PUBLIC_IMAGE)

push: push_private push_public
	
# this will be executed only  on CI/CD (Bamboo) where there is a whitesource agent installed
scan:
	bash /home/bamboo/bamboo-agent-config/scripts/agent/whitesource-agent.sh -d ${SCAN_FOLDER} -product "Alfresco Identity Service" -project "Identity Service" -projectVersion "${IDENTITY_VERSION}"

run:
	@docker run -p 8080:8080 -p 9990:9990 --name alfresco-ids --rm $(PRIVATE_IMAGE)

stop:
	docker kill alfresco-ids

sh:
	docker exec -it $$(docker ps -aq --filter name=alfresco-ids) sh
	