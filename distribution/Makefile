include build.properties
export $(shell sed 's/=.*//' build.properties)

ifeq ($(SCAN_FOLDER),)
	SCAN_FOLDER:=.
endif

DEV_BUILD			?=false
# Dev properties
KEYCLOAK_GIT_REPO	:=Alfresco/keycloak
# 'master' will be used if not set
KEYCLOAK_GIT_BRANCH	:=
THEME_VERSION		?=0.3.1


build: distribution
	
distribution:
ifeq (false, $(DEV_BUILD))
	./build.sh
else
	@./build.sh keycloak_git_repo=$(KEYCLOAK_GIT_REPO) keycloak_git_branch=$(KEYCLOAK_GIT_BRANCH) theme_version=$(THEME_VERSION) || (echo "Couldn't build keycloak. Make sure you are building with the correct Java version."; rm -rf temp; exit 1)
endif

scan: # this will be executed only  on CI/CD (Bamboo) where there is a whitesource agent installed
	bash /home/bamboo/bamboo-agent-config/scripts/agent/whitesource-agent.sh -d ${SCAN_FOLDER} -product "Alfresco Identity Service" -project "Identity Service" -projectVersion "${IDENTITY_VERSION}"
