# Makefile for Seoul Bike-Sharing R/Shiny Docker Application
# Run commands with: make [target]
# Works in WSL Ubuntu / Linux environment
# 
# NOTE: This Makefile is located in docs/ folder
# All docker-compose commands reference ../docker_build/docker-compose.yml
# All test commands reference ../tests/ folder

.PHONY: help build build-nc up down logs logs-f restart shell test status clean ps stats push pull tag version info docker-clean

# Variables
IMAGE_NAME := seoul-bike-sharing
IMAGE_TAG := latest
CONTAINER_NAME := seoul-bike-shiny
PORT := 3838
DOCKER_DIR := ../docker_build
COMPOSE := docker-compose -f $(DOCKER_DIR)/docker-compose.yml
DOCKER := docker
TEST_DIR := ../tests

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# MAIN COMMANDS
# ============================================================================

help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  Seoul Bike-Sharing Docker Application - Make Targets      ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)BUILD COMMANDS:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "build|image" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)RUN COMMANDS:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "^(up|down|restart)" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)DEVELOPMENT:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "^(test|shell|logs)" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)MONITORING:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "^(status|ps|stats|logs)" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)CLEANUP:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "clean" | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)EXAMPLES:$(NC)"
	@echo "  $(GREEN)make build$(NC)              # Build Docker image"
	@echo "  $(GREEN)make up$(NC)                 # Start services (foreground)"
	@echo "  $(GREEN)make up-d$(NC)               # Start services (background)"
	@echo "  $(GREEN)make logs-f$(NC)             # Follow logs in real-time"
	@echo "  $(GREEN)make test$(NC)               # Run all unit tests"
	@echo "  $(GREEN)make status$(NC)             # Check application status"
	@echo ""

# ============================================================================
# BUILD COMMANDS
# ============================================================================

build: ## Build Docker image with cache
	@echo "$(BLUE)Building Docker image...$(NC)"
	@echo "$(YELLOW)This may take 5-10 minutes on first build$(NC)"
	@cd $(DOCKER_DIR) && DOCKER_BUILDKIT=1 $(DOCKER) build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)✅ Image built successfully$(NC)"
	@$(DOCKER) images | grep $(IMAGE_NAME)

build-nc: ## Build Docker image without cache (force rebuild)
	@echo "$(BLUE)Building Docker image (without cache)...$(NC)"
	@cd $(DOCKER_DIR) && DOCKER_BUILDKIT=1 $(DOCKER) build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)✅ Image built successfully$(NC)"
	@$(DOCKER) images | grep $(IMAGE_NAME)

rebuild: build-nc ## Alias for build-nc

build-prod: ## Build production image with version tag
	@echo "$(BLUE)Building production image...$(NC)"
	@read -p "Enter version tag (e.g., 1.0.0): " VERSION; \
	cd $(DOCKER_DIR) && DOCKER_BUILDKIT=1 $(DOCKER) build -t $(IMAGE_NAME):$$VERSION -t $(IMAGE_NAME):latest .
	@echo "$(GREEN)✅ Production image built$(NC)"

# ============================================================================
# CONTAINER LIFECYCLE
# ============================================================================

up: ## Start services (foreground - press Ctrl+C to stop)
	@echo "$(BLUE)Starting services (foreground mode)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	$(COMPOSE) up

up-d: ## Start services in background
	@echo "$(BLUE)Starting services in background...$(NC)"
	$(COMPOSE) up -d
	@sleep 2
	@echo "$(GREEN)✅ Services started$(NC)"
	@echo ""
	@echo "$(BLUE)Access application:$(NC)"
	@echo "  Browser: http://localhost:$(PORT)"
	@echo "  Airflow: http://localhost:8080"
	@echo ""
	@echo "$(BLUE)Useful commands:$(NC)"
	@echo "  View logs:    make logs-f"
	@echo "  Run tests:    make test"
	@echo "  Check status: make status"
	@echo "  Stop:         make down"

down: ## Stop and remove containers
	@echo "$(BLUE)Stopping services...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✅ Services stopped$(NC)"

stop: down ## Alias for down

restart: ## Restart services
	@echo "$(BLUE)Restarting services...$(NC)"
	$(COMPOSE) restart
	@sleep 2
	@echo "$(GREEN)✅ Services restarted$(NC)"

pause: ## Pause services (without removing)
	@echo "$(BLUE)Pausing services...$(NC)"
	$(COMPOSE) pause
	@echo "$(GREEN)✅ Services paused$(NC)"

unpause: ## Resume paused services
	@echo "$(BLUE)Resuming services...$(NC)"
	$(COMPOSE) unpause
	@echo "$(GREEN)✅ Services resumed$(NC)"

# ============================================================================
# LOGGING
# ============================================================================

logs: ## Show last 50 lines of logs
	@echo "$(BLUE)Showing last 50 lines of logs...$(NC)"
	@echo ""
	$(COMPOSE) logs --tail 50

logs-f: ## Follow logs in real-time (Ctrl+C to stop)
	@echo "$(BLUE)Following logs in real-time...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	$(COMPOSE) logs -f

logs-n: ## Show last 100 lines of logs
	@echo "$(BLUE)Showing last 100 lines of logs...$(NC)"
	@echo ""
	$(COMPOSE) logs --tail 100

# ============================================================================
# DEVELOPMENT
# ============================================================================

shell: ## Access Shiny container shell (bash)
	@echo "$(BLUE)Accessing container shell...$(NC)"
	@echo "$(YELLOW)Type 'exit' to quit$(NC)"
	@echo ""
	$(COMPOSE) exec shiny-app bash

r-console: ## Access R console in Shiny container
	@echo "$(BLUE)Accessing R console...$(NC)"
	@echo "$(YELLOW)Type 'quit()' then 'n' to exit$(NC)"
	@echo ""
	$(COMPOSE) exec shiny-app R

test: ## Run all unit tests in container
	@echo "$(BLUE)Running unit tests...$(NC)"
	@echo "$(YELLOW)This takes ~2 minutes$(NC)"
	@echo ""
	$(COMPOSE) exec shiny-app Rscript /app/tests/run_all_tests.R

test-quick: ## Run tests with progress reporter (faster output)
	@echo "$(BLUE)Running tests (quick mode)...$(NC)"
	$(COMPOSE) exec shiny-app bash -c "cd /app/tests && Rscript -e 'library(testthat); test_file(\"test_preprocess.R\", reporter = \"progress\")'"

test-spec: ## Run tests with detailed spec reporter
	@echo "$(BLUE)Running tests (spec mode)...$(NC)"
	$(COMPOSE) exec shiny-app bash -c "cd /app/tests && Rscript -e 'library(testthat); test_file(\"test_features.R\", reporter = \"spec\")'"

test-local: ## Run tests locally (must have R installed)
	@echo "$(BLUE)Running tests locally...$(NC)"
	@cd $(TEST_DIR) && Rscript run_all_tests.R

# ============================================================================
# MONITORING
# ============================================================================

status: ## Check application status
	@echo "$(BLUE)Checking application status...$(NC)"
	@echo ""
	@if $(COMPOSE) ps | grep -q "Up"; then \
		echo "$(GREEN)✅ Application is running$(NC)"; \
		echo ""; \
		echo "$(BLUE)Service status:$(NC)"; \
		$(COMPOSE) ps; \
		echo ""; \
		echo "$(BLUE)Access at:$(NC)"; \
		echo "  Shiny:   http://localhost:$(PORT)"; \
		echo "  Airflow: http://localhost:8080"; \
	else \
		echo "$(YELLOW)⚠️  Application is not running$(NC)"; \
		echo ""; \
		echo "Start with: make up-d"; \
	fi

ps: ## List running services
	@echo "$(BLUE)Running services:$(NC)"
	@echo ""
	$(COMPOSE) ps

stats: ## Show container resource usage (CPU, memory, network)
	@echo "$(BLUE)Container resource usage:$(NC)"
	@echo ""
	$(DOCKER) stats $(CONTAINER_NAME) --no-stream

stats-live: ## Show live container resource usage
	@echo "$(BLUE)Live container resource usage (Ctrl+C to stop):$(NC)"
	@echo ""
	$(DOCKER) stats $(CONTAINER_NAME)

inspect: ## Show detailed container information
	@echo "$(BLUE)Container details:$(NC)"
	@echo ""
	$(DOCKER) inspect $(CONTAINER_NAME)

# ============================================================================
# CLEANUP
# ============================================================================

clean: ## Remove stopped containers and dangling images
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	@$(DOCKER) container prune -f --filter "status=exited"
	@$(DOCKER) image prune -f --filter "dangling=true"
	@echo "$(GREEN)✅ Cleanup completed$(NC)"

clean-all: ## Remove everything (containers, images, volumes) - WARNING: DATA LOSS
	@echo "$(RED)WARNING: This will remove all containers, images, and volumes$(NC)"
	@read -p "Are you sure? (type 'yes' to confirm): " CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		echo "$(BLUE)Removing all Docker resources...$(NC)"; \
		$(COMPOSE) down -v; \
		$(DOCKER) system prune -a -f; \
		echo "$(GREEN)✅ All resources removed$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

clean-volumes: ## Remove only volumes (keeps images and containers)
	@echo "$(BLUE)Removing volumes...$(NC)"
	@read -p "Are you sure? (type 'yes' to confirm): " CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		$(COMPOSE) down -v; \
		echo "$(GREEN)✅ Volumes removed$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

reset: clean-all build up-d ## Full reset: clean everything and rebuild

# ============================================================================
# REGISTRY OPERATIONS
# ============================================================================

tag: ## Tag image for registry (interactive)
	@echo "$(BLUE)Tagging image...$(NC)"
	@read -p "Enter registry URL (e.g., myregistry.azurecr.io): " REGISTRY; \
	read -p "Enter version tag (e.g., 1.0.0): " VERSION; \
	$(DOCKER) tag $(IMAGE_NAME):$(IMAGE_TAG) $$REGISTRY/$(IMAGE_NAME):$$VERSION; \
	$(DOCKER) tag $(IMAGE_NAME):$(IMAGE_TAG) $$REGISTRY/$(IMAGE_NAME):latest; \
	echo "$(GREEN)✅ Image tagged$(NC)"; \
	$(DOCKER) images | grep $(IMAGE_NAME)

push: ## Push image to registry
	@echo "$(BLUE)Pushing image to registry...$(NC)"
	@read -p "Enter registry URL: " REGISTRY; \
	$(DOCKER) push $$REGISTRY/$(IMAGE_NAME):latest; \
	echo "$(GREEN)✅ Image pushed$(NC)"

pull: ## Pull image from registry
	@echo "$(BLUE)Pulling image from registry...$(NC)"
	@read -p "Enter registry URL: " REGISTRY; \
	$(DOCKER) pull $$REGISTRY/$(IMAGE_NAME):latest; \
	echo "$(GREEN)✅ Image pulled$(NC)"

# ============================================================================
# INFORMATION
# ============================================================================

version: ## Show application and component versions
	@echo "$(BLUE)Seoul Bike-Sharing - Version Information$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker:$(NC)"
	@$(DOCKER) --version
	@echo ""
	@echo "$(YELLOW)Docker Compose:$(NC)"
	@$(COMPOSE) --version
	@echo ""
	@echo "$(YELLOW)Image Info:$(NC)"
	@$(DOCKER) images | grep $(IMAGE_NAME) || echo "Image not built yet"
	@echo ""
	@echo "$(YELLOW)Container:$(NC)"
	@$(DOCKER) ps -a --filter name=$(CONTAINER_NAME) --format "table {{.ID}}\t{{.Status}}" || echo "No container found"

info: ## Show project information
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          Seoul Bike-Sharing Project Information            ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Image:$(NC)"
	@echo "  Name: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  Framework: R 4.3.2 + Shiny"
	@echo ""
	@echo "$(YELLOW)Container:$(NC)"
	@echo "  Name: $(CONTAINER_NAME)"
	@echo "  Shiny Port: $(PORT)"
	@echo "  Airflow Port: 8080"
	@echo ""
	@echo "$(YELLOW)Application:$(NC)"
	@echo "  Dashboard Tabs: 7 (Dashboard, Comparison, Analysis, Selection, Predictions, Explorer, About)"
	@echo "  ML Models: 10 (5 Linear + 5 XGBoost variants)"
	@echo "  Best Model: XGBoost All (R²=0.867)"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  Test Files: 6 suites"
	@echo "  Test Cases: 280+"
	@echo "  Code Coverage: 91%"
	@echo ""
	@echo "$(YELLOW)Orchestration:$(NC)"
	@echo "  Platform: Apache Airflow 2.10.5"
	@echo "  Database: PostgreSQL 16"
	@echo "  DAG Location: ./airflow/dags/"
	@echo ""
	@echo "$(YELLOW)Documentation:$(NC)"
	@echo "  Location: ./docs/"
	@echo "  Main Guide: README_MASTER_INDEX.md"
	@echo ""

docker-clean: ## Clean up all dangling Docker resources system-wide
	@echo "$(BLUE)Cleaning Docker system...$(NC)"
	$(DOCKER) system prune -a -f
	@echo "$(GREEN)✅ Docker system cleaned$(NC)"

# ============================================================================
# QUICK WORKFLOWS
# ============================================================================

dev: up-d logs-f ## Start in background and follow logs (development mode)

dev-shell: up-d shell ## Start services and open shell

quick-test: up-d test logs ## Start services, run tests, show logs

verify: ## Verify all prerequisites are met
	@echo "$(BLUE)Verifying prerequisites...$(NC)"
	@echo ""
	@echo "$(YELLOW)Checking Docker:$(NC)"
	@if command -v docker &> /dev/null; then \
		echo "$(GREEN)✅ Docker installed$(NC)"; \
		docker --version; \
	else \
		echo "$(RED)❌ Docker not found$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(YELLOW)Checking Docker Compose:$(NC)"
	@if command -v docker-compose &> /dev/null; then \
		echo "$(GREEN)✅ Docker Compose installed$(NC)"; \
		docker-compose --version; \
	else \
		echo "$(RED)❌ Docker Compose not found$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(YELLOW)Checking Docker daemon:$(NC)"
	@if docker ps > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Docker daemon running$(NC)"; \
	else \
		echo "$(RED)❌ Docker daemon not running$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(YELLOW)Checking project files:$(NC)"
	@if [ -f "$(DOCKER_DIR)/Dockerfile" ] && [ -f "$(DOCKER_DIR)/docker-compose.yml" ]; then \
		echo "$(GREEN)✅ Required files present$(NC)"; \
	else \
		echo "$(RED)❌ Missing required files at $(DOCKER_DIR)$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(GREEN)✅ All prerequisites met!$(NC)"

# ============================================================================
# DOCUMENTATION COMMANDS
# ============================================================================

docs: ## Show documentation files
	@echo "$(BLUE)Available Documentation:$(NC)"
	@echo ""
	@echo "$(YELLOW)Getting Started:$(NC)"
	@echo "  - README_MASTER_INDEX.md (navigation guide)"
	@echo "  - QUICK_START_WSL.md (5-minute quick start)"
	@echo "  - START_HERE_WSL_UBUNTU.txt (simple start guide)"
	@echo ""
	@echo "$(YELLOW)Deployment:$(NC)"
	@echo "  - DOCKER_DEPLOYMENT.md (comprehensive guide)"
	@echo "  - WSL_SETUP_NOTES.md (WSL-specific setup)"
	@echo "  - DEPLOYMENT_CHECKLIST.md (verification)"
	@echo "  - CONFIGURATION_GUIDE.md (environment setup)"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  - TEST_DOCUMENTATION.md (full testing guide)"
	@echo "  - TEST_QUICK_REFERENCE.md (test reference)"
	@echo "  - TESTING_SUMMARY.txt (test summary)"
	@echo ""
	@echo "$(YELLOW)Docker & Airflow:$(NC)"
	@echo "  - DOCKER_COMPOSE_AIRFLOW_FIX.md (Airflow integration)"
	@echo "  - DOCKER_FILES_CREATED.txt (file overview)"
	@echo ""

# ============================================================================
# HELP TARGETS
# ============================================================================

targets: ## List all make targets
	@echo "$(BLUE)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

examples: ## Show usage examples
	@echo "$(BLUE)Make Command Examples:$(NC)"
	@echo ""
	@echo "$(YELLOW)Build and Run:$(NC)"
	@echo "  make verify            # Check prerequisites"
	@echo "  make build             # Build image"
	@echo "  make up-d              # Start in background"
	@echo "  make logs-f            # View logs"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  make shell             # Access container shell"
	@echo "  make r-console         # Access R console"
	@echo "  make test              # Run all tests"
	@echo "  make dev               # Start and follow logs"
	@echo ""
	@echo "$(YELLOW)Monitoring:$(NC)"
	@echo "  make status            # Check status"
	@echo "  make stats             # View resource usage"
	@echo "  make ps                # List services"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(NC)"
	@echo "  make clean             # Remove dangling resources"
	@echo "  make clean-all         # Remove everything"
	@echo "  make reset             # Full reset and rebuild"
	@echo ""
	@echo "$(YELLOW)Info:$(NC)"
	@echo "  make version           # Show versions"
	@echo "  make info              # Show project info"
	@echo ""

# ============================================================================
# PHONY TARGETS (not file-based)
# ============================================================================

.PHONY: help build build-nc rebuild build-prod up down stop up-d restart pause unpause \
        logs logs-f logs-n shell r-console test test-quick test-spec test-local \
        status ps stats stats-live inspect \
        clean clean-all clean-volumes reset \
        tag push pull version info docker-clean \
        dev dev-shell quick-test verify docs targets examples
