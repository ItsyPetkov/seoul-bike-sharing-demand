# Seoul Bike-Sharing Prediction System
# R/Shiny application

FROM rocker/shiny:latest AS base

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    python3 \
    python3-venv \
    pkg-config \
    libuv1-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libz-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    libcairo2-dev \
    libxt-dev \
    libicu-dev \
    libgit2-dev \
    curl \
    wget \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/mlflow-venv \
    && /opt/mlflow-venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/mlflow-venv/bin/pip install --no-cache-dir mlflow

FROM base AS dependencies

RUN R --quiet --slave -e "install.packages(c( \
    'tidyverse', \
    'tidymodels', \
    'xgboost', \
    'shiny', \
    'shinydashboard', \
    'shinyWidgets', \
    'plotly', \
    'ggplot2', \
    'dplyr', \
    'tibble', \
    'caret', \
    'recipes', \
    'yardstick', \
    'rsample', \
    'parsnip', \
    'workflows', \
    'tune', \
    'tidyselect', \
    'stringr', \
    'lubridate', \
    'scales', \
    'forcats', \
    'purrr', \
    'readr', \
    'testthat', \
    'knitr', \
    'rmarkdown', \
    'DT', \
    'fastDummies', \
    'RSQLite', \
    'rvest', \
    'httr', \
    'mlflow' \
    ), repos='https://cloud.r-project.org')"

FROM dependencies AS application

# The build context is the project root.
# Copy the complete project into the image.
COPY . /app/R_and_IBM_Cloud

RUN mkdir -p \
    /app/logs \
    /app/checkpoints \
    /app/data \
    /app/outputs \
    /app/R_and_IBM_Cloud/tests/test_results

RUN chmod -R 755 /app

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -fsS http://localhost:3838/ || exit 1

EXPOSE 3838

ENV R_HOME=/usr/local/lib/R
ENV MLFLOW_PYTHON_BIN=/opt/mlflow-venv/bin/python
ENV MLFLOW_BIN=/opt/mlflow-venv/bin/mlflow

CMD ["R", "--quiet", "--slave", "-e", "shiny::runApp('/app/R_and_IBM_Cloud', host='0.0.0.0', port=3838)"]
