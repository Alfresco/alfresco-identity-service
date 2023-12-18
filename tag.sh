#!/bin/bash -e

source distribution/build.properties

if [[ -z "$KEYCLOAK_VERSION" || -z "$THEME_VERSION" ]]; then
    echo "KEYCLOAK_VERSION and/or THEME_VERSION are missing."
    echo "Please check the contents of distribution/build.properties".
    exit 1
fi

TAG="keycloak-${KEYCLOAK_VERSION}_theme-${THEME_VERSION}"

CURRENT_BRANCH=$(git branch | grep '*' | cut -d' ' -f 2)

echo "Do you wish to tag and push the current branch '$CURRENT_BRANCH' as '$TAG' ?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        git tag "$TAG" -m ""
        git push origin "$TAG"
        break
        ;;
    No)
        exit
        ;;
    esac
done
