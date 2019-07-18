include build.properties
export $(shell sed 's/=.*//' build.properties)

IMAGE:=quay.io/alfresco/alfresco-identity-service:$(IDENTITY_VERSION)

build:
	./build.sh && \
	docker build --force-rm=true --no-cache=true --build-arg IDENTITY_VERSION=$(IDENTITY_VERSION) -t $(IMAGE) -f Dockerfile .
	
push:
	@docker push $(IMAGE)

run:
	@docker run -p 8080:8080 -p 9990:9990 --name alfresco-ids --rm $(IMAGE)

stop:
	docker kill alfresco-ids

sh:
	docker exec -it $$(docker ps -aq --filter name=alfresco-ids) sh
