#!/usr/bin/env bash

ENVIRONMENT ?= dev
SERVICE ?= persistent-shared-cluster
AWS_REGION ?= eu-west-1
BITBUCKET_BUILD_NUMBER ?= localbuild

DB_NAME = testdb
REDIS_STACK_NAME = redis-shared-cluster
RDS_STACK_NAME = rds-shared-cluster

BUCKET_NAME = artifactory-$(ENVIRONMENT)
NOW = $(shell date)
REPOS = $(shell git config --get remote.origin.url)
REV = $(shell git rev-parse HEAD)


.PHONY: deploy_redis
deploy_redis:
	@echo "\n----- Deploying redis shared cluster START -----\n"
	aws cloudformation deploy \
	--template-file cloudformation/redis.yaml \
	--stack-name $(REDIS_STACK_NAME) \
	--capabilities CAPABILITY_NAMED_IAM \
	--region $(AWS_REGION) \
	--tags Environment=$(ENVIRONMENT) Project=$(SERVICE) \
				"UpdatedDate=$(NOW)" \
				"Repository=$(REPOS)" \
				"git-sha=$(REV)" \
				"git-branch"=$(shell git rev-parse --abbrev-ref HEAD) \
				BitbucketBuildNumber=$(BITBUCKET_BUILD_NUMBER) \
	--parameter-overrides \
	Service=$(SERVICE) \
	Environment=$(ENVIRONMENT)
	@echo "\n----- Deploying redis shared cluster DONE -----\n"

cfn-package = mkdir -p cloudformation/dist && \
	aws cloudformation package \
	--template-file cloudformation/${1}.yaml \
	--output-template-file cloudformation/dist/${1}.yaml \
	--s3-bucket $(BUCKET_NAME) \
	--s3-prefix $(RDS_STACK_NAME)

cfn-deploy = $(call cfn-package,${1}) && \
	aws cloudformation deploy \
	--tags Environment=$(ENVIRONMENT) Project=$(SERVICE) \
		"UpdatedDate=$(NOW)" \
		"git-sha=$(REV)" \
		"git-branch"=$(shell git rev-parse --abbrev-ref HEAD) \
		BitbucketBuildNumber=$(BITBUCKET_BUILD_NUMBER) \
	--template-file cloudformation/dist/${1}.yaml \
	--stack-name $(RDS_STACK_NAME)-${1} \
	--capabilities CAPABILITY_NAMED_IAM \
	--region $(AWS_REGION) \
	--no-fail-on-empty-changeset \
	--parameter-overrides \
		Service=$(RDS_STACK_NAME) \
		Environment=$(ENVIRONMENT) \
		DBName=$(DB_NAME)

deploy_db:
	@echo "----- Deploying DB Stack: START -----"
	bash ./pipeline/deploy_db.sh $(AWS_REGION) $(RDS_STACK_NAME) $(ENVIRONMENT) $(DB_NAME) $(RDS_STACK_NAME)
	@echo "----- Deploying DB Stack: DONE -----"

deploy_vpc:
	@echo "----- Deploying VPC Stack: START -----"
	bash ./pipeline/deploy_vpc.sh $(AWS_REGION) $(RDS_STACK_NAME) $(ENVIRONMENT)
	@echo "----- Deploying VPC Stack: DONE -----"

deploy_lambda:
	@echo "----- Deploying Lambda Stack: START -----"
	$(call cfn-deploy,lambda)
	@echo "----- Deploying Lambda Stack: DONE -----"

enable_data_api:
	aws rds modify-db-cluster --db-cluster-identifier $(RDS_STACK_NAME) --enable-http-endpoint --apply-immediately

install:
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm install $(args)) \
		done;

clean:
	npm cache clean --force
	rm -rf node_modules
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && rm -rf node_modules) \
    done;

test:
	@echo "No tests found"

lint:
	./node_modules/.bin/eslint '**/*.js' --ignore-path .gitignore
