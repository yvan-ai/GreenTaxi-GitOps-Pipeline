.DEFAULT_GOAL := help
.PHONY: help setup lint format test run build ingest infra-up infra-down clean

DBT_DIR := GreenTaxi
IMAGE   := ghcr.io/yvan-ai/greentaxi-dbt:local
MONTHS  ?= 2021-01

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}'

setup: ## Install Python & dbt dependencies and pre-commit hooks
	pip install dbt-core dbt-postgres pre-commit sqlfluff pandas pyarrow sqlalchemy
	pre-commit install

ingest: ## Load NYC TLC green taxi data into Postgres (MONTHS="2021-01 2021-02")
	python ingestion/load_green_tripdata.py $(MONTHS)

lint: ## Lint SQL (SQLFluff) and Terraform
	sqlfluff lint $(DBT_DIR)/models --dialect postgres
	terraform -chdir=terraform fmt -check

format: ## Auto-format SQL and Terraform
	sqlfluff fix $(DBT_DIR)/models --dialect postgres
	terraform -chdir=terraform fmt

test: ## Parse and test dbt models
	cd $(DBT_DIR) && dbt deps && dbt parse --profiles-dir . && dbt build --profiles-dir .

run: ## Run dbt models against the configured Postgres target
	cd $(DBT_DIR) && dbt run --profiles-dir .

build: ## Build the dbt Docker image locally
	docker build -f $(DBT_DIR)/Dockerfile -t $(IMAGE) .

infra-up: ## Provision ArgoCD on the cluster via Terraform
	terraform -chdir=terraform init
	terraform -chdir=terraform apply -auto-approve

infra-down: ## Tear down the Terraform-managed infrastructure
	terraform -chdir=terraform destroy -auto-approve

clean: ## Remove dbt artifacts and Python caches
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/dbt_packages $(DBT_DIR)/logs
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
