include build.properties
export $(shell sed 's/=.*//' build.properties)

ifeq ($(SCAN_FOLDER),)
	SCAN_FOLDER:=.
endif

build: distribution
	
distribution:
	./build.sh

scan: # this will be executed only  on CI/CD (Bamboo) where there is a whitesource agent installed
	bash /home/bamboo/bamboo-agent-config/scripts/agent/whitesource-agent.sh -d ${SCAN_FOLDER} -product "Alfresco Identity Service" -project "Identity Service" -projectVersion "${IDENTITY_VERSION}"