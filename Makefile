.DEFAULT_GOAL := default

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# ----------------------------------------------------------------------------------------------------------------------
.PHONY: help start stop restart ps prune


default: rebootd

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: ## Start all or c=<name> containers
	docker compose -f docker-compose.yml up ${c}

startd: ## Srart all or c=<name> containers (detached)
	docker compose -f docker-compose.yml up -d ${c}
	docker compose logs -f --tail=100

stop: ## Stop all or c=<name> containers
	docker compose -f docker-compose.yml down -t 1 ${c}

top: ## Show top
	docker compose -f docker-compose.yml top

ps: ## Show all containers
	docker compose -f docker-compose.yml ps

restart: ## Restart all containers
	docker compose restart

build: ## Build all or c=<name> images
	docker compose build --build-arg DEV_MODE=${DEV_MODE} ${c}
	#docker compose build --build-arg ENV_MODE=${ENV_MODE} ${c}
#	docker compose build ${c}

buildh: ## Build odoo image with local network (hack way)
	docker build --network host --build-arg DEV_MODE=${DEV_MODE} -t odoo_test_odoo .

buildf: ## Build all or c=<name> images (force)
	docker compose build --build-arg ENV_MODE=${ENV_MODE} --no-cache ${c}

reboot: stop start ## Reboot all containers

rebootd: stop startd logs ## Reboot all containers (detached+log)

prune: ## Prune all dangling containers, images and volumes
	docker system prune

prunef: ## Prune all dangling containers, images and volumes (force)
	docker system prune --all --volumes --force

logs: ## Show all or c=<name> containers logs
	docker compose logs -f --tail=$(or $(t), 100) ${c}

bash: ## Run bash in c=<name> service container
	docker compose exec -it $(c) bash

exec: ## Run cmd=<command> in c=<name> service container
	#docker compose exec -it $(c) $(cmd)
	docker compose exec $(c) $(cmd)

restart-svc: ## Restart c=<name> service container
	docker compose -f docker-compose.yml up -d --force-recreate --no-deps ${c}

gen: ## Generate odoo modules and views
	cd ./addons/netsuite_integration && \
	pipenv run python tools/codegen.py && \
	cd ../..

restore_db: ## Restore database from dump.sql (internal)
	docker compose -f docker-compose.yml up -d postgresql
	sleep 5
	docker compose exec -it postgresql su - postgres -c "dropdb ${d} -U odoo"
	docker compose cp dump.sql postgresql:/tmp/
	docker compose exec -it postgresql su - postgres -c "createdb -U odoo ${d}"
	docker compose exec -it postgresql su - postgres -c "psql -U odoo -f /tmp/dump.sql ${d}"


restore: stop restore_db startd ## Restore database from dump.sql


#-- Tests --------------------------------------------------------------------------------------------------------------
all-tests: ## Run all tests
	docker compose exec odoo pytest -s -v /mnt/extra-addons/netsuite_integration/tests/ --setup-show

test: ## Run test under development
#	docker compose exec odoo pytest -s -v /mnt/extra-addons/netsuite_integration/tests/test_api.py --setup-show
	docker compose exec odoo pytest -s -v /mnt/extra-addons/netsuite_integration/tests/test_model_factory.py --setup-show
	#docker compose exec odoo pytest -s -v /mnt/extra-addons/netsuite_integration/tests/test_fetcher.py::test_fetch_records --setup-show
