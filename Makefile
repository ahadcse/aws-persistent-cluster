#!/usr/bin/env bash

ENVIRONMENT ?= dev
SERVICE ?= persistent-shared-cluster
AWS_REGION ?= eu-west-1
BITBUCKET_BUILD_NUMBER ?= localbuild

REDIS_STACK_NAME = redis-shared-cluster

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
