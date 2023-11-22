include build.properties
export $(shell sed 's/=.*//' build.properties)

THEME_VERSION		?=0.3.5

build: distribution
	
distribution:
	./build.sh
