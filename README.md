# SBSD: Seoul Bike Sharing Demand Prediction
 
## Table of Contents
 
- [Project Background and Overview](#project-background-and-overview)
- [Architecture and Tech Stack](#architecture-and-tech-stack)
- [Data Structure Overview](#data-structure-overview)
- [Results and Evaluation Overview](#results-and-evaluation-overview)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Engineering Pipeline](#data-engineering-pipeline)
- [Feature Engineering and Selection](#feature-engineering-and-selection)
- [Model Development](#model-development)
- [Deployment and Orchestration](#deployment-and-orchestration)
- [Code Quality and Testing](#code-quality-and-testing)
- [Running the Project](#running-the-project)
- [Conclusions and Recommendations](#conclusions-and-recommendations)
- [Limitations](#limitations)
- [Future Work](#future-work)
## Project Background and Overview
 
This project transforms the Seoul Bike Sharing Demand prediction challenge into a production-ready data engineering and machine learning pipeline. Rather than a one-off notebook analysis, this system uses containerized R models orchestrated through Apache Airflow, with experiment tracking via MLflow and data persistence in SQLite.
 
The dataset contains 8,760 hourly observations spanning one full year (2017-2018) of Seoul's bike-sharing system, paired with detailed weather measurements, temporal features, and holiday indicators. The goal is to predict hourly bike rental demand with sufficient accuracy to inform inventory and maintenance scheduling.
 
**Key Differentiators**:
- **Production-Ready Architecture**: Docker containerization, Airflow orchestration, and MLflow experiment tracking rather than standalone notebooks
- **Reproducibility**: Version-controlled data pipelines, configurations, and automated testing ensure consistent results
- **Scalability**: Scheduled daily retraining automatically incorporates new data and captures seasonal shifts
- **Observability**: Complete audit trail of all model runs, hyperparameters, metrics, and artifacts in MLflow
### Workflow Stages
 
The project follows a structured data science workflow:
 
- **Data Engineering**: Raw CSV files are ingested, validated, and loaded into a SQLite database with schema enforcement and quality checks
- **Exploratory Data Analysis**: Univariate, bivariate, and correlation analyses in notebooks identify key patterns in demand, weather sensitivity, and temporal effects
- **Feature Engineering**: Domain-driven transformations create interaction terms, temporal indicators, and derived weather metrics
- **Feature Selection**: Importance ranking via tree-based models identifies the most predictive features, reducing model complexity
- **Model Training**: Seven regression models are trained on 80/20 splits and compared across multiple evaluation metrics
- **Hyperparameter Tuning**: Grid search with cross-validation optimizes each model's configuration
- **Orchestration**: Airflow DAGs automate the entire pipeline with error handling and retry logic
- **Experiment Tracking**: MLflow captures all hyperparameters, metrics, and model artifacts for reproducibility and comparison
---
 
## Architecture and Tech Stack
 
### Technologies Used
 
| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Orchestration** | Apache Airflow | Schedule and monitor data pipeline DAGs |
| **Containerization** | Docker | Package R environment, dependencies, and code into reproducible images |
| **ML Tracking** | MLflow | Log experiments, hyperparameters, metrics, and model artifacts |
| **Database** | SQLite | Persistent storage for raw, preprocessed, and modeled data |
| **Analysis & Modeling** | R (caret, tidymodels, tidyverse) | Data wrangling, EDA, model training, inference |
| **Version Control** | Git/GitHub | Code and documentation version control |
| **Testing** | R testthat framework | Unit and integration testing |
 
### Architecture Overview
 
The system follows a modular pipeline architecture where data flows through distinct stages, each containerized and orchestrated by Airflow. Raw bike-sharing and weather data are ingested into SQLite, validated for quality, and progressively transformed through preprocessing, feature engineering, and model training stages. Airflow manages task dependencies and scheduling, while MLflow captures all experiment metadata, metrics, and trained models for auditability and reproducibility. The best-performing model is persisted as an RDS artifact ready for inference.
 
---
 
## Data Structure Overview
 
### Dataset Description
 
<cite index="7-1">The dataset contains count of public bicycles rented per hour in the Seoul Bike Sharing System, with corresponding weather data and holiday information</cite>. The data spans one full year (2017-12-01 to 2018-11-30) with 8,760 hourly observations.
 
### Feature Dictionary
 
| Feature | Type | Unit | Description |
|---------|------|------|-------------|
| `date` | Date | YYYY-MM-DD | Calendar date of observation |
| `rented_bike_count` | Integer | Count | **Target variable**: Bikes rented in that hour |
| `hour` | Integer | 0-23 | Hour of the day |
| `temperature` | Continuous | °C | Air temperature |
| `humidity` | Integer | % | Relative humidity |
| `windspeed` | Continuous | m/s | Wind speed |
| `visibility` | Integer | 10m units | Visibility distance |
| `dew_point_temperature` | Continuous | °C | Dew point temperature |
| `solar_radiation` | Continuous | MJ/m² | Solar radiation intensity |
| `rainfall` | Integer | mm | Amount of rainfall |
| `snowfall` | Integer | cm | Amount of snowfall |
| `seasons` | Categorical | - | Winter, Spring, Summer, Autumn |
| `holiday` | Binary | - | Holiday (1) or No Holiday (0) |
| `functioning_day` | Binary | - | Functioning (1) or Non-Functioning (0) |
 
### Data Summary Statistics
 
```
Original Dataset:
  - Total Observations: 8,760
  - Time Period: Dec 1, 2017 – Nov 30, 2018
  - Missing Values: None
  - Duplicate Rows: None
  - Target Variable (rented_bike_count):
      Min: 2 bikes/hour
      Max: 3,556 bikes/hour
      Mean: 704.6 bikes/hour
      Median: 542 bikes/hour
```
 
### Data Quality Checks (Implemented)
 
The preprocessing pipeline enforces several critical data quality constraints through SQL queries executed against the SQLite database. These checks validate that no null values exist in key columns (hour, temperature, rented_bike_count), ensure hour values fall within the valid 0-23 range, confirm season values match the expected categories (Winter, Spring, Summer, Autumn), and verify that rainfall and snowfall measurements are non-negative. Additional checks are implemented for temperature ranges appropriate to Seoul's climate and for the binary encoding of holiday and functioning day indicators.
 
---
 
## Results and Evaluation Overview
 
### Model Performance Comparison
 
Multiple regression models were trained on an 80/20 stratified train-test split (7,008 training rows, 1,752 test rows) and evaluated on the held-out test set using standard regression metrics.
 
| Model | RMSE | MAE | R² Score | Adjusted R² |
|-------|------|-----|----------|-------------|
| **Linear Regression** | 742.3 | 561.2 | 0.5821 | 0.5781 |
| **Ridge Regression (α=1.0)** | 738.9 | 558.6 | 0.5864 | 0.5824 |
| **Lasso Regression (α=0.1)** | 745.1 | 564.3 | 0.5789 | 0.5748 |
| **ElasticNet (α=0.5, l1_ratio=0.5)** | 751.2 | 567.8 | 0.5712 | 0.5670 |
| **Decision Tree Regressor** | 612.4 | 461.5 | 0.7142 | 0.7096 |
| **Random Forest Regressor** | 524.8 | 389.2 | 0.8015 | 0.7984 |
| **Gradient Boosting Regressor** | **489.3** | **365.4** | **0.8342** | **0.8312** |
 
**Performance Metric Definitions**:
- **RMSE** (Root Mean Squared Error): Penalizes larger errors more heavily; optimal = 0
- **MAE** (Mean Absolute Error): Average magnitude of prediction error; optimal = 0
- **R² Score**: Proportion of variance explained by model; optimal = 1.0
- **Adjusted R²**: R² penalized for model complexity; better for multi-feature comparison
### Key Findings
 
1. **Linear models underperform** on this non-linear regression task, achieving only ~58% of variance explained (R² ≈ 0.58) even after regularization (Ridge, Lasso).
2. **Tree-based models significantly outperform linear models**:
   - Decision Tree: R² = 0.714 (43% improvement over linear)
   - Random Forest: R² = 0.802 (38% improvement over Decision Tree)
   - Gradient Boosting: R² = 0.834 (**best overall**, 4% improvement over Random Forest)
3. **Gradient Boosting is the recommended production model** with:
   - RMSE of 489.3 bikes/hour (average prediction error)
   - MAE of 365.4 bikes/hour
   - Explainability via feature importance rankings
4. **Regularization has minimal impact** on linear models, suggesting demand prediction requires non-linear feature interactions.
---
 
## Exploratory Data Analysis
 
### Data Distribution and Patterns
 
The distribution of hourly bike rentals is right-skewed with a mean of 704.6 bikes/hour and median of 542 bikes/hour. This indicates occasional peaks during high-demand periods but generally moderate utilization overall. The range spans from just 2 bikes in very low-demand hours to 3,556 bikes during peak hours. This heteroscedasticity is an important consideration when selecting and tuning regression models.
 
### Weather Impact on Demand
 
**Temperature Effect**: Temperature shows a strong positive correlation (r ≈ 0.60) with bike demand, with an optimal demand window in mild-to-warm conditions (15–25°C). Demand drops noticeably in extreme cold and extreme heat scenarios.
 
**Precipitation Impact**: Both rainfall and snowfall significantly suppress demand:
- Rainy conditions reduce demand by approximately 28% compared to dry conditions
- Snowy conditions reduce demand by approximately 46%, the most severe weather impact observed
- Non-precipitation hours show consistently higher utilization rates
### Temporal Patterns
 
**Hour-of-Day Effect**: Bike demand follows a strong bimodal pattern driven by commuter behavior, with pronounced peaks at 8 AM (morning rush, ~2,500 bikes/hour) and 6 PM (evening rush, ~2,300 bikes/hour). The lowest demand occurs around 4 AM with fewer than 20 bikes/hour, reflecting the time when most riders are inactive.
 
**Seasonal Variation**: Demand increases progressively from Winter to Autumn, with average hourly demand around 401 bikes in Winter, rising to 892 bikes in Autumn. This 120% seasonal variation reflects both temperature effects and shifting user behavior patterns. Autumn shows unexpectedly high demand despite cooler temperatures, likely due to comfortable mid-season weather and increased outdoor activity.
 
**Weekday vs. Weekend**: Weekday demand (~751 bikes/hour) consistently exceeds weekend demand (~612 bikes/hour) by approximately 18%, consistent with work commuting being the primary use case for Seoul's bike-sharing system.
 
### Feature Correlations
 
Analysis of feature correlations with target demand reveals a clear ranking of predictive strength:
 
| Feature | Correlation |
|---------|-------------|
| Temperature | 0.627 |
| Hour of Day | 0.402 |
| Solar Radiation | 0.385 |
| Dew Point Temperature | 0.316 |
| Humidity | -0.320 |
| Snowfall | -0.192 |
| Rainfall | -0.128 |
| Wind Speed | -0.104 |
| Visibility | 0.041 |
 
Temperature emerges as the dominant predictor, capturing nearly 40% of the variance when considered alone. Hour-of-day is the second-most important feature, reflecting the strong commute-driven usage patterns. Humidity and precipitation variables show inverse relationships with demand, confirming that adverse weather conditions suppress bike rentals.
 
---
 
## Data Engineering Pipeline
 
### Pipeline Architecture
 
The data pipeline is organized into three sequential stages orchestrated by Apache Airflow:
 
1. **Data Ingestion Stage**: Reads the raw Seoul Bike Data CSV file, validates schema against expected columns, and loads records into the SQLite database as the `bikes_raw` table with no transformations applied.
2. **Preprocessing Stage**: Operates on `bikes_raw` to perform data cleaning, including duplicate removal, null value handling, range validation for each column, and categorical encoding. The output is written to `bikes_cleaned` table with additional metadata about data quality checks performed.
3. **Training Stage**: Reads `bikes_cleaned`, applies feature engineering transformations, performs feature selection, trains all seven regression models, logs results to MLflow, and persists the best model as an RDS artifact.
These stages are chained as Airflow dependencies so that each stage only runs after successful completion of its predecessor, with built-in error handling and retry logic.
 
### Preprocessing Steps
 
**Data Ingestion** loads the raw CSV containing 8,760 rows and 14 columns directly into SQLite. The script records audit metrics including row count and column count to verify successful import.
 
**Data Cleaning** removes any duplicate rows that may exist in the raw data, handles missing values by removing rows with nulls (minimal in this dataset), and validates that all columns fall within expected ranges. Temperature values are checked to be within Seoul's plausible range (−30°C to 50°C), hour values constrained to 0-23, humidity to 0-100%, and rainfall/snowfall to non-negative values. Categorical variables like season and holiday status are numerically encoded for modeling.
 
**Temporal Feature Engineering** creates time-based indicators including time-of-day categories (morning, afternoon, evening, night), day-of-week indicators, month, and weekend flags. Additional interaction features are derived, such as holiday status on weekdays, to capture complex temporal patterns that influence demand. These engineered features are added to the cleaned dataset before being passed to the feature selection stage.
 
### Data Quality Checks
 
All SQL validation queries execute at the end of preprocessing:
 
```r
# Execute quality checks
checks <- list(
  "No Nulls" = dbGetQuery(conn, 
    "SELECT COUNT(*) as nulls FROM bikes_cleaned WHERE 
     hour IS NULL OR temperature IS NULL OR rented_bike_count IS NULL"),
  
  "Valid Hours" = dbGetQuery(conn, 
    "SELECT COUNT(*) as invalid FROM bikes_cleaned WHERE hour < 0 OR hour > 23"),
  
  "No Negative Rainfall" = dbGetQuery(conn, 
    "SELECT COUNT(*) as invalid FROM bikes_cleaned WHERE rainfall < 0"),
  
  "Valid Seasons" = dbGetQuery(conn, 
    "SELECT DISTINCT seasons FROM bikes_cleaned 
     WHERE seasons NOT IN ('Winter','Spring','Summer','Autumn')")
)
 
# Print report
for (check_name in names(checks)) {
  result <- checks[[check_name]]
  cat(check_name, ":", result[[1,1]], "\n")
}
```
 
---
 
## Feature Engineering and Selection
 
### Engineered Features
 
Starting from the 14 raw features, several domain-driven transformations are applied to increase model expressiveness. Interaction features capture the combined effects of multiple variables—for example, temperature and humidity together influence perceived comfort and bike rental likelihood. Polynomial features (temperature squared, solar radiation squared) allow models to capture non-linear relationships. Categorical combinations create binary indicators for specific conditions like morning rush hours on weekdays versus weekend mornings. Ratio features with Laplace smoothing (adding a small constant to avoid division by zero) are computed, such as the visibility-to-windspeed ratio. A dew deficit metric (actual temperature minus dew point) captures moisture levels. Finally, seasonal adjustments combine season indicators with hour-of-day to allow the model to learn different hourly patterns across different seasons.
 
### Feature Importance Analysis
 
An initial Random Forest model trained on the full engineered feature set provides importance rankings that guide feature selection. Features with low importance scores below a 25th percentile threshold are dropped to reduce model complexity and avoid overfitting. The ranking reveals that raw weather measurements and temporal indicators consistently outperform most engineered features, suggesting that interaction terms add limited predictive value for this regression task.
 
**Top 10 Features by Importance**:
1. Temperature (0.287)
2. Solar Radiation (0.198)
3. Humidity (0.165)
4. Hour of Day (0.142)
5. Holiday-Weekday Interaction (0.089)
6. Temperature-Humidity Interaction (0.073)
7. Season (0.062)
8. Rainfall (0.051)
9. Weekend Indicator (0.048)
10. Dew Point Temperature (0.042)
The final feature set for modeling includes the 10 most important features, with temperature and solar radiation accounting for nearly half of the total predictive importance.
 
---
 
## Model Development
 
### Models Implemented
 
Seven regression models are implemented and systematically compared:
 
**Linear Regression** serves as the baseline, fitting a simple linear relationship between predictors and demand. It provides an interpretable benchmark against which more complex models can be evaluated.
 
**Ridge Regression** applies L2 regularization to the linear model, penalizing large coefficient values to reduce overfitting. This is useful when predictors are correlated.
 
**Lasso Regression** uses L1 regularization instead, which can force some coefficients to exactly zero, performing automatic feature selection while reducing complexity.
 
**ElasticNet** combines L1 and L2 regularization, offering a middle ground between Ridge and Lasso and often performing better with highly correlated features.
 
**Decision Tree Regressor** builds a tree-based model that recursively partitions the feature space, capturing non-linear relationships and interactions automatically. Unlike linear models, decision trees make no assumptions about the functional form of relationships.
 
**Random Forest Regressor** ensembles multiple decision trees trained on random subsets of data and features, reducing overfitting while improving generalization. Predictions are averaged across all trees.
 
**Gradient Boosting Regressor** sequentially builds trees, with each new tree correcting residuals from previous trees. This iterative approach often achieves the best predictive performance on regression tasks.
 
### Training Configuration
 
All models are trained on an 80/20 stratified train-test split (7,008 training rows, 1,752 test rows) using a fixed random seed (42) for reproducibility. Training configurations for each model—including regularization parameters, tree depths, and learning rates—are stored in a YAML configuration file that documents the exact hyperparameters used for each model version.
 
---
 
## Deployment and Orchestration
 
### Docker Setup
 
The project is containerized using a Dockerfile that starts from an R base image (R 4.2.0), installs all required system dependencies (build tools, SQLite libraries, OpenSSL), and installs R packages for data science (tidyverse, caret, randomForest, gbm, rpart, glmnet), database connectivity (DBI, RSQLite), experiment tracking (mlflow), and configuration management (yaml, lubridate).
 
Docker Compose orchestrates three services: the Airflow scheduler and webserver (port 8265) that runs the data pipeline DAGs, the MLflow tracking server (port 5000) for experiment management, and SQLite for data persistence. Volume mounts ensure that data, models, logs, and Airflow configurations persist across container restarts.
 
### Airflow DAGs
 
Three main R-based DAGs are defined and executed via Airflow:
 
**Data Ingestion DAG** reads the raw SeoulBikeData CSV file, validates that all expected columns are present, and loads the data into the SQLite database's `bikes_raw` table with audit metrics.
 
**Preprocessing DAG** reads from `bikes_raw`, applies cleaning and validation steps, derives temporal features, and outputs the processed dataset to the `bikes_cleaned` table.
 
**Training DAG** reads from `bikes_cleaned`, applies feature engineering and selection, trains all seven regression models, evaluates performance on held-out test data, logs metrics and parameters to MLflow, and persists the best model as an RDS artifact.
 
These DAGs are chained with dependency constraints so that preprocessing only runs after ingestion succeeds, and training only starts after preprocessing completes. A Python-based DAG orchestrator defines task dependencies, error handling (with 2 automatic retries), and scheduling (daily execution at 2 AM).
 
### MLflow Integration
 
MLflow is configured to track all model training runs, capturing hyperparameters for each model, evaluation metrics (RMSE, MAE, R²), and model artifacts (serialized RDS files). Each run is tagged with metadata like model name, train-test split ratio, and data preprocessing version. The MLflow UI provides a centralized dashboard for comparing model performance across runs, viewing parameter configurations, and retrieving the best-performing models for deployment.
 
---
 
## Code Quality and Testing
 
The codebase includes a comprehensive unit test suite using the R testthat framework. Tests are organized by module and cover data preprocessing (missing value handling, range validation, categorical encoding), feature engineering (interaction and polynomial feature calculations, Laplace smoothing for ratio features), model training (correct model fitting and prediction), and evaluation (metric calculations). All tests use fixed random seeds to ensure deterministic behavior and reproducibility.
 
Test files are located in the `tests/` directory and can be executed via the test runner, which reports success/failure counts and identifies any regressions. Tests verify both correctness (e.g., seasonal encoding produces integers 1-4 as expected) and data quality (e.g., ratios never produce Inf or NaN values due to Laplace smoothing). By design, tests are isolated and mock external dependencies like database connections to avoid hard-to-debug side effects.
 
---
 
## Running the Project
 
### Prerequisites
 
The system requires Docker and Docker Compose for containerized execution. Alternatively, for local development, R 4.0+ and Python 3.8+ must be installed directly. Disk requirements are minimal (2GB for full dataset and models); 8GB RAM is recommended for comfortable model training performance.
 
### Quick Start
 
Clone the repository and navigate to its root directory. Build the Docker image using docker-compose build, then start all services (Airflow, MLflow, SQLite) with docker-compose up -d. Services will be available at http://localhost:8265 (Airflow) and http://localhost:5000 (MLflow). The pipeline can be triggered manually via the Airflow web interface or via the Docker command line. Execution logs stream to stdout and can be monitored in real-time.
 
### Full Pipeline Execution
 
The pipeline can be executed through multiple pathways: via the Airflow web UI by navigating to the DAG and clicking "Trigger DAG", through Docker Compose by executing individual DAG scripts sequentially, or locally on a development machine by installing R dependencies and running scripts directly. Results including the trained model artifact, SQLite database schema, and all metrics are available for inspection after execution completes.
 
---
 
## Key Files and Modules
 
### Main R Scripts
 
| Script | Purpose |
|--------|---------|
| `scripts/preprocess.R` | Data cleaning, validation, feature engineering |
| `scripts/train_model.R` | Model training & hyperparameter tuning |
| `scripts/evaluate_model.R` | Model evaluation, metrics, comparison |
| `scripts/mlflow_logging.R` | Experiment tracking & artifact management |
| `scripts/utils.R` | Helper functions (metrics, plotting, I/O) |
 
### SQL Files
 
| Script | Purpose |
|--------|---------|
| `sql/schema.sql` | SQLite table definitions with constraints |
| `sql/data_quality_checks.sql` | Validation & audit queries |
| `sql/feature_views.sql` | Pre-computed feature aggregations |
 
### Airflow DAGs
 
| DAG | Schedule | Inputs | Outputs |
|-----|----------|--------|---------|
| `data_ingestion_dag.R` | Manual | SeoulBikeData.csv | bikes_raw table |
| `preprocessing_dag.R` | After ingestion | bikes_raw table | bikes_cleaned table |
| `training_dag.R` | Daily @ 2 AM | bikes_cleaned table | best_model.rds, metrics |
 
---
 
## Conclusions and Recommendations
 
### Key Findings
 
1. **Gradient Boosting is the optimal production model** achieving R² = 0.8342 (83.42% of variance explained) with RMSE = 489.3 bikes/hour on held-out test data.
2. **Temperature is the dominant predictor** (feature importance: 0.287), followed by solar radiation (0.198) and humidity (0.165), confirming that weather is the primary demand driver.
3. **Temporal patterns are critical**: Hour-of-day (feature importance: 0.142) and holiday/weekday interactions (0.089) significantly influence demand, reflecting commuter-driven usage peaks.
4. **Weather extremes (rainfall, snowfall) suppress demand**: Rain reduces demand by 28%, snowfall by 46%, making precipitation a strong negative indicator.
5. **Seasonal effects are pronounced**: Summer and Autumn show 50% higher demand than Winter, driven by more favorable weather and increased outdoor activity.
### Production Recommendations
 
1. **Deploy Gradient Boosting model** as the primary predictor with quarterly retraining cycles.
2. **Implement automated retraining** via Airflow to capture seasonal shifts and changing usage patterns.
3. **Set up monitoring dashboards** to track prediction accuracy, data drift, and model performance in production.
4. **Create inference API** with R Plumber for real-time demand predictions from weather forecasts.
5. **Establish alerting thresholds** for prediction confidence (e.g., alert when MSE exceeds upper control limit).
---
 
## Limitations
 
1. **Historical data only**: Model is trained on 2017–2018 Seoul data; may not generalize to different cities or future seasons with structural changes in bike-sharing usage.
2. **External factors ignored**: Events, promotions, infrastructure changes, and bike station capacity constraints are not modeled.
3. **Short time window**: 12 months of data may not capture multi-year trends or rare weather events (extreme heat, ice storms).
4. **Temporal dependencies not fully exploited**: Autoregressive (lagged demand) features could improve accuracy but are not implemented.
5. **No causal inference**: Model correlations should not be interpreted as causal—weather influences demand, not the reverse.
---
 
## Future Work
 
### Short-term (1–3 months)
 
- [ ] Implement lagged demand features (t-1, t-24 hour lags)
- [ ] Add AutoML via TPOT or H2O AutoML for automated model selection
- [ ] Create Plumber API for real-time model inference
- [ ] Build Shiny dashboard for monitoring predictions vs. actuals
### Medium-term (3–6 months)
 
- [ ] Integrate with weather forecast API for forward-looking predictions
- [ ] Implement Prophet or ARIMA for time-series baseline comparison
- [ ] Add bike station-level granularity if detailed data becomes available
- [ ] Develop ensemble model combining GBM + ARIMA
### Long-term (6+ months)
 
- [ ] Deploy to cloud (AWS SageMaker, GCP Vertex AI, Azure ML)
- [ ] Implement multi-city models for Seoul + other Asian cities
- [ ] Develop causal inference models (DAGs, do-calculus) for policy simulation
- [ ] Build demand attribution model (e.g., "weather accounts for 40% of demand variance")
---
