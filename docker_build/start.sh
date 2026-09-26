#!/bin/bash

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

IMAGE_NAME="seoul-bike-sharing"
IMAGE_TAG="latest"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Service definitions with their health check endpoints
declare -A SERVICES=(
    [shiny-app]="3838:Shiny Dashboard"
    [airflow-webserver]="8080:Airflow Web UI"
    [seoul-bike-mlflow]="5000:MLflow Tracking Server"
)

declare -A HEALTH_CHECKS=(
    [3838]="curl -fsS http://localhost:3838/ >/dev/null 2>&1"
    [8080]="curl -fsS http://localhost:8080/health >/dev/null 2>&1"
    [5000]="curl -fsS http://localhost:5000/ >/dev/null 2>&1"
)

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
else
    echo "ERROR: Docker Compose is not installed."
    exit 1
fi

compose() {
    "${COMPOSE_CMD[@]}" -f "${COMPOSE_FILE}" "$@"
}

check_docker() {
    docker info >/dev/null 2>&1 || {
        echo "ERROR: Docker is not running."
        exit 1
    }
}

# Parse docker-compose.yml to extract services and their ports
get_services_from_compose() {
    # Extract service names and their exposed ports from docker-compose.yml
    python3 -c "
import yaml
import sys

try:
    with open('${COMPOSE_FILE}', 'r') as f:
        compose = yaml.safe_load(f)
    
    for service_name, service_config in compose.get('services', {}).items():
        if 'ports' in service_config:
            ports = service_config['ports']
            for port_mapping in ports:
                # Port mapping format: 'HOST:CONTAINER' or just 'PORT'
                if isinstance(port_mapping, str):
                    parts = port_mapping.split(':')
                    host_port = parts[0].strip('\"')
                    print(f'{service_name}:{host_port}')
except Exception as e:
    # Fallback to grep if yaml parsing fails
    pass
" 2>/dev/null || fallback_parse_ports
}

# Fallback port parsing using grep
fallback_parse_ports() {
    grep -A 2 'container_name:' "${COMPOSE_FILE}" | grep -B 1 'ports:' | grep 'container_name:' | sed 's/.*container_name: //' | while read container; do
        grep -A 50 "container_name: ${container}" "${COMPOSE_FILE}" | grep -A 2 'ports:' | grep -oP '(?<=")\d+(?=:)' | head -1 | xargs -I {} echo "${container}:{}"
    done
}

# Get port for a specific service
get_port() {
    local service=$1
    grep -A 50 "container_name: ${service}" "${COMPOSE_FILE}" 2>/dev/null | grep -A 1 'ports:' | grep -oP '"\d+:\d+' | head -1 | cut -d':' -f2 | tr -d '"' || echo ""
}

# Get human-readable service name
get_service_name() {
    local port=$1
    case $port in
        3838) echo "Shiny Dashboard" ;;
        8080) echo "Airflow Web UI" ;;
        5000) echo "MLflow Tracking Server" ;;
        5432) echo "PostgreSQL Database" ;;
        *)    echo "Service on port $port" ;;
    esac
}

# Check if service is responding
check_service_health() {
    local port=$1
    case $port in
        3838)
            curl -fsS http://localhost:${port}/ >/dev/null 2>&1
            ;;
        8080)
            curl -fsS http://localhost:${port}/health >/dev/null 2>&1
            ;;
        5000)
            curl -fsS http://localhost:${port}/ >/dev/null 2>&1
            ;;
        *)
            # Generic check
            timeout 2 bash -c "echo >/dev/tcp/localhost/${port}" >/dev/null 2>&1
            ;;
    esac
}

# Display service status
display_service_status() {
    local port=$1
    local service_name=$(get_service_name $port)
    
    if check_service_health $port; then
        echo -e "  ${GREEN}✔${NC} ${service_name:20}  ${GREEN}http://localhost:${port}${NC}"
        return 0
    else
        echo -e "  ${RED}✗${NC} ${service_name:20}  ${RED}NOT RESPONDING${NC}"
        return 1
    fi
}

# Enhanced status function
detailed_status() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Seoul Bike-Sharing Service Status                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
    
    # Show container status
    echo -e "${YELLOW}Container Status:${NC}"
    compose ps
    
    echo -e "\n${YELLOW}Service Access Points:${NC}\n"
    
    # Check all services
    local all_healthy=true
    
    # Shiny
    if display_service_status 3838; then
        :
    else
        all_healthy=false
    fi
    
    # Airflow
    if display_service_status 8080; then
        :
    else
        all_healthy=false
    fi
    
    # MLflow
    if display_service_status 5000; then
        :
    else
        all_healthy=false
    fi
    
    echo
    
    # Database status (no health check, just running)
    if compose ps postgres | grep -q "Up"; then
        echo -e "  ${GREEN}✔${NC} PostgreSQL Database     ${CYAN}localhost:5432${NC} (internal)"
    else
        echo -e "  ${RED}✗${NC} PostgreSQL Database     ${RED}NOT RUNNING${NC}"
        all_healthy=false
    fi
    
    # MLflow PostgreSQL (if exists)
    if compose ps mlflow-postgres 2>/dev/null | grep -q "Up" || docker ps 2>/dev/null | grep -q "seoul-bike-mlflow-postgres"; then
        echo -e "  ${GREEN}✔${NC} MLflow PostgreSQL       ${CYAN}localhost:5433${NC} (internal)"
    fi
    
    echo
    echo -e "${YELLOW}Quick Links:${NC}"
    echo -e "  ${BLUE}Shiny Dashboard:${NC}    http://localhost:3838"
    echo -e "  ${BLUE}Airflow WebUI:${NC}      http://localhost:8080"
    echo -e "  ${BLUE}MLflow Tracking:${NC}    http://localhost:5000"
    echo
    
    # Summary
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}✔ All services operational!${NC}\n"
        return 0
    else
        echo -e "${YELLOW}⚠ Some services not responding yet. Wait a moment and retry.${NC}\n"
        return 1
    fi
}

# Start all services with port information
start_all() {
    echo -e "${BLUE}Starting Seoul Bike + Airflow + MLflow...${NC}\n"
    
    compose up -d --remove-orphans
    
    echo -e "\n${GREEN}Services starting...${NC}"
    echo -e "${YELLOW}Waiting for services to be ready (this may take 30-60 seconds)${NC}\n"
    
    # Wait a moment for services to initialize
    sleep 3
    
    # Show detailed status
    detailed_status
}

# Stop all services
stop_all() {
    echo -e "${BLUE}Stopping Seoul Bike + Airflow + MLflow...${NC}\n"

    compose down

    echo -e "${GREEN}All services stopped.${NC}\n"
}

# Restart services
restart_all() {
    stop_all
    sleep 2
    start_all
}

# Enhanced status with port discovery
status() {
    detailed_status
}

# Build images
build_shiny() {
    echo -e "${BLUE}Building Seoul Bike R/Shiny image${NC}\n"

    DOCKER_BUILDKIT=1 docker build \
        -f "${SCRIPT_DIR}/Dockerfile" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${PROJECT_ROOT}"

    echo -e "\n${GREEN}Shiny image built successfully.${NC}\n"
}

build_all() {
    echo -e "${BLUE}Building Seoul Bike + Airflow + MLflow stack${NC}\n"

    build_shiny

    echo -e "\n${YELLOW}Pulling Airflow, MLflow and PostgreSQL images...${NC}\n"
    compose pull postgres airflow-init airflow-webserver airflow-scheduler mlflow mlflow-postgres 2>/dev/null || true

    echo -e "\n${GREEN}Build complete.${NC}\n"
}

build_nc() {
    echo -e "${BLUE}Building Seoul Bike image WITHOUT cache${NC}\n"

    DOCKER_BUILDKIT=1 docker build \
        --no-cache \
        -f "${SCRIPT_DIR}/Dockerfile" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${PROJECT_ROOT}"

    echo -e "\n${YELLOW}Pulling Airflow, MLflow and PostgreSQL images...${NC}\n"
    compose pull postgres airflow-init airflow-webserver airflow-scheduler mlflow mlflow-postgres 2>/dev/null || true

    echo -e "\n${GREEN}Build complete.${NC}\n"
}

# Logging functions
logs() {
    compose logs --tail="${1:-100}"
}

logs_shiny() {
    compose logs --tail="${1:-100}" shiny-app
}

logs_airflow() {
    compose logs --tail="${1:-100}" airflow-webserver airflow-scheduler
}

logs_mlflow() {
    compose logs --tail="${1:-100}" seoul-bike-mlflow
}

logs_follow() {
    compose logs -f
}

# Shell access functions
shell_shiny() {
    compose exec shiny-app bash
}

shell_airflow() {
    compose exec airflow-webserver bash
}

shell_mlflow() {
    compose exec seoul-bike-mlflow bash
}

# Testing
test_r() {
    compose exec shiny-app \
        Rscript /app/R_and_IBM_Cloud/tests/run_all_tests.R
}

# Airflow management
airflow_dags() {
    compose exec airflow-webserver airflow dags list
}

airflow_test() {
    compose exec airflow-webserver \
        airflow dags test seoul_bike_pipeline 2026-09-24
}

airflow_trigger() {
    compose exec airflow-webserver \
        airflow dags trigger seoul_bike_pipeline
}

# Cleanup
clean() {
    echo -e "${BLUE}Removing stopped containers...${NC}"
    docker container prune -f

    echo -e "${BLUE}Removing dangling images...${NC}"
    docker image prune -f

    echo -e "${GREEN}Cleanup complete.${NC}\n"
}

# Display all services and ports
show_services() {
    echo -e "\n${BLUE}Available Services & Ports:${NC}\n"
    
    echo -e "  ${CYAN}Service${NC}                    ${CYAN}Port${NC}    ${CYAN}URL${NC}"
    echo -e "  ${CYAN}─────────────────────────────────────────────────────${NC}"
    echo -e "  Shiny Dashboard              3838    http://localhost:3838"
    echo -e "  Airflow Web UI               8080    http://localhost:8080"
    echo -e "  MLflow Tracking Server       5000    http://localhost:5000"
    echo -e "  PostgreSQL (Airflow)         5432    localhost:5432 (internal)"
    echo -e "  PostgreSQL (MLflow)          5433    localhost:5433 (internal)"
    echo
}

# Help text
show_help() {
    cat <<EOF

${BLUE}Seoul Bike Sharing - Docker Management${NC}
Enhanced with dynamic port discovery and comprehensive service status

${YELLOW}Usage:${NC}
  ./start.sh COMMAND

${YELLOW}BUILD COMMANDS${NC}
  build              Build the R/Shiny image and Airflow services
  build-nc           Build everything without Docker cache

${YELLOW}APPLICATION LIFECYCLE${NC}
  up                 Start all services (Shiny + Airflow + MLflow)
  down               Stop all services
  restart            Restart all services
  status             Show comprehensive service status and health

${YELLOW}LOGGING${NC}
  logs               Show last 100 lines of all logs
  logs-shiny         Show Shiny logs
  logs-airflow       Show Airflow logs
  logs-mlflow        Show MLflow logs
  logs-f             Follow all logs in real-time

${YELLOW}SHELL ACCESS${NC}
  shell              Open bash shell in Shiny container
  shell-airflow      Open bash shell in Airflow container
  shell-mlflow       Open bash shell in MLflow container

${YELLOW}TESTING${NC}
  test               Run R unit tests (280+ test cases)

${YELLOW}AIRFLOW MANAGEMENT${NC}
  dags               List Airflow DAGs
  airflow-test       Test the Seoul Bike Pipeline DAG
  airflow-trigger    Trigger the Seoul Bike Pipeline manually

${YELLOW}MAINTENANCE${NC}
  clean              Remove stopped containers and dangling images
  services           Show all available services and ports

${YELLOW}HELP${NC}
  help               Show this help message

${YELLOW}QUICK START${NC}
  1. Check prerequisites:
     ./start.sh status

  2. Build (first time only):
     ./start.sh build

  3. Start services:
     ./start.sh up

  4. View all access points:
     ./start.sh services

  5. Check service health:
     ./start.sh status

  6. View logs:
     ./start.sh logs-f

${YELLOW}SERVICE ACCESS POINTS${NC}
  Shiny Dashboard:      http://localhost:3838
  Airflow Web UI:       http://localhost:8080 (admin/admin)
  MLflow Tracking:      http://localhost:5000

${YELLOW}ENVIRONMENT${NC}
  Docker File:         ${COMPOSE_FILE}
  Project Root:        ${PROJECT_ROOT}

${YELLOW}TIPS${NC}
  - Use 'status' command frequently to monitor service health
  - Use 'logs-f' to follow logs in real-time
  - Use 'services' to see all available ports
  - MLflow is now available on port 5000 for ML experiment tracking

EOF
}

# Main entry point
main() {
    check_docker

    case "${1:-help}" in
        build)
            build_all
            ;;

        build-nc)
            build_nc
            ;;

        up|up-d)
            start_all
            ;;

        down)
            stop_all
            ;;

        restart)
            restart_all
            ;;

        status)
            status
            ;;

        logs)
            logs "${2:-100}"
            ;;

        logs-shiny)
            logs_shiny "${2:-100}"
            ;;

        logs-airflow)
            logs_airflow "${2:-100}"
            ;;

        logs-mlflow)
            logs_mlflow "${2:-100}"
            ;;

        logs-f)
            logs_follow
            ;;

        shell)
            shell_shiny
            ;;

        shell-airflow)
            shell_airflow
            ;;

        shell-mlflow)
            shell_mlflow
            ;;

        dags)
            airflow_dags
            ;;

        airflow-test)
            airflow_test
            ;;

        airflow-trigger)
            airflow_trigger
            ;;

        test)
            test_r
            ;;

        clean)
            clean
            ;;

        services)
            show_services
            ;;

        help|-h|--help)
            show_help
            ;;

        *)
            echo -e "${RED}Unknown command: ${1}${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"

# set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# IMAGE_NAME="seoul-bike-sharing"
# IMAGE_TAG="latest"
# SHINY_CONTAINER="seoul-bike-shiny"
# AIRFLOW_WEB="seoul-bike-airflow-webserver"
# AIRFLOW_SCHEDULER="seoul-bike-airflow-scheduler"
# PORT="3838"
# AIRFLOW_PORT="8080"

# if docker compose version >/dev/null 2>&1; then
#     COMPOSE_CMD=(docker compose)
# elif command -v docker-compose >/dev/null 2>&1; then
#     COMPOSE_CMD=(docker-compose)
# else
#     echo "ERROR: Docker Compose is not installed."
#     exit 1
# fi

# compose() {
#     "${COMPOSE_CMD[@]}" -f "${COMPOSE_FILE}" "$@"
# }

# check_docker() {
#     docker info >/dev/null 2>&1 || {
#         echo "ERROR: Docker is not running."
#         exit 1
#     }
# }

# build_shiny() {
#     echo "=========================================="
#     echo "Building Seoul Bike R/Shiny image"
#     echo "=========================================="

#     DOCKER_BUILDKIT=1 docker build \
#         -f "${SCRIPT_DIR}/Dockerfile" \
#         -t "${IMAGE_NAME}:${IMAGE_TAG}" \
#         "${PROJECT_ROOT}"

#     echo
#     echo "Shiny image built successfully."
# }

# build_all() {
#     echo "=========================================="
#     echo "Building Seoul Bike + Airflow stack"
#     echo "=========================================="

#     build_shiny

#     echo
#     echo "Pulling Airflow and PostgreSQL images..."
#     compose pull postgres airflow-init airflow-webserver airflow-scheduler

#     echo
#     echo "Build complete."
# }

# build_nc() {
#     echo "=========================================="
#     echo "Building Seoul Bike image WITHOUT cache"
#     echo "=========================================="

#     DOCKER_BUILDKIT=1 docker build \
#         --no-cache \
#         -f "${SCRIPT_DIR}/Dockerfile" \
#         -t "${IMAGE_NAME}:${IMAGE_TAG}" \
#         "${PROJECT_ROOT}"

#     echo
#     echo "Airflow uses the official Apache Airflow image."
#     echo "No separate Airflow Dockerfile is required."

#     echo
#     echo "Pulling Airflow and PostgreSQL images..."
#     compose pull postgres airflow-init airflow-webserver airflow-scheduler

#     echo
#     echo "Build complete."
# }

# start_all() {
#     echo "Starting Seoul Bike + Airflow..."

#     compose up -d --remove-orphans

#     echo
#     echo "Services started."
#     echo
#     echo "Shiny:   http://localhost:${PORT}"
#     echo "Airflow: http://localhost:${AIRFLOW_PORT}"
# }

# stop_all() {
#     echo "Stopping Seoul Bike + Airflow..."

#     compose down

#     echo "All services stopped."
# }

# restart_all() {
#     stop_all
#     start_all
# }

# status() {
#     compose ps

#     echo
#     echo "Shiny:"
#     if curl -fsS "http://localhost:${PORT}/" >/dev/null 2>&1; then
#         echo "  OK - http://localhost:${PORT}"
#     else
#         echo "  NOT RESPONDING"
#     fi

#     echo
#     echo "Airflow:"
#     if curl -fsS "http://localhost:${AIRFLOW_PORT}/health" >/dev/null 2>&1; then
#         echo "  OK - http://localhost:${AIRFLOW_PORT}"
#     else
#         echo "  NOT RESPONDING YET"
#     fi
# }

# logs() {
#     compose logs --tail="${1:-100}"
# }

# logs_shiny() {
#     compose logs --tail="${1:-100}" shiny-app
# }

# logs_airflow() {
#     compose logs --tail="${1:-100}" airflow-webserver airflow-scheduler
# }

# logs_airflow_follow() {
#     compose logs -f airflow-webserver airflow-scheduler
# }

# shell_shiny() {
#     compose exec shiny-app bash
# }

# shell_airflow() {
#     compose exec airflow-webserver bash
# }

# airflow_dags() {
#     compose exec airflow-webserver airflow dags list
# }

# airflow_test() {
#     compose exec airflow-webserver \
#         airflow dags test seoul_bike_pipeline 2026-09-24
# }

# airflow_trigger() {
#     compose exec airflow-webserver \
#         airflow dags trigger seoul_bike_pipeline
# }

# test_r() {
#     compose exec shiny-app \
#         Rscript /app/R_and_IBM_Cloud/tests/run_all_tests.R
# }

# clean() {
#     echo "Removing stopped containers..."
#     docker container prune -f

#     echo "Removing dangling images..."
#     docker image prune -f

#     echo "Cleanup complete."
# }

# show_help() {
#     cat <<EOF

# Seoul Bike Sharing - Docker Management

# Usage:
#   ./start.sh COMMAND

# BUILD
#   build          Build the R/Shiny image and Airflow services
#   build-nc       Build everything without Docker cache

# APPLICATION
#   up             Start Shiny + Airflow
#   down           Stop Shiny + Airflow
#   restart        Restart everything
#   status         Show service status

# LOGS
#   logs            Show all logs
#   logs-shiny      Show Shiny logs
#   logs-airflow    Show Airflow logs
#   logs-airflow-f  Follow Airflow logs

# SHELL
#   shell            Open shell in Shiny container
#   shell-airflow    Open shell in Airflow container

# AIRFLOW
#   dags             List Airflow DAGs
#   airflow-test     Test the Seoul Bike DAG
#   airflow-trigger  Trigger the Seoul Bike DAG manually

# TESTING
#   test             Run R tests

# MAINTENANCE
#   clean            Remove stopped containers and dangling images

# URLS
#   Shiny:    http://localhost:3838
#   Airflow:  http://localhost:8080

# EOF
# }

# main() {
#     check_docker

#     case "${1:-help}" in
#         build)
#             build_all
#             ;;

#         build-nc)
#             build_nc
#             ;;

#         up|up-d)
#             start_all
#             ;;

#         down)
#             stop_all
#             ;;

#         restart)
#             restart_all
#             ;;

#         status)
#             status
#             ;;

#         logs)
#             logs "${2:-100}"
#             ;;

#         logs-shiny)
#             logs_shiny "${2:-100}"
#             ;;

#         logs-airflow)
#             logs_airflow "${2:-100}"
#             ;;

#         logs-airflow-f)
#             logs_airflow_follow
#             ;;

#         shell)
#             shell_shiny
#             ;;

#         shell-airflow)
#             shell_airflow
#             ;;

#         dags)
#             airflow_dags
#             ;;

#         airflow-test)
#             airflow_test
#             ;;

#         airflow-trigger)
#             airflow_trigger
#             ;;

#         test)
#             test_r
#             ;;

#         clean)
#             clean
#             ;;

#         help|-h|--help)
#             show_help
#             ;;

#         *)
#             echo "Unknown command: $1"
#             show_help
#             exit 1
#             ;;
#     esac
# }

# main "$@"