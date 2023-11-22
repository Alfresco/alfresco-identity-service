include build.properties
export $(shell sed 's/=.*//' build.properties)

DEV_BUILD			?=false
# Dev properties
THEME_GIT_REPO :=Alfresco/alfresco-keycloak-theme
# 'master' will be used if not set
THEME_GIT_BRANCH :=

build: distribution
	
distribution:
ifeq (false, $(DEV_BUILD))
	./build.sh
else
	@./build.sh theme_git_repo=$(THEME_GIT_REPO) theme_git_branch=$(THEME_GIT_BRANCH) || (echo "Couldn't build keycloak. Make sure you are building with the correct Java version."; rm -rf temp; exit 1)
endif