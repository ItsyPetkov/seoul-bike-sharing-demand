from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount


IMAGE = "seoul-bike-sharing:latest"
NETWORK = "seoul-bike-network"
PROJECT_ROOT = "/app/R_and_IBM_Cloud"


COMMON_MOUNTS = [
    Mount(
        source="seoul-bike-data-raw",
        target=f"{PROJECT_ROOT}/data_raw",
        type="volume",
    ),
    Mount(
        source="seoul-bike-data-preprocessed",
        target=f"{PROJECT_ROOT}/data_preprocessed",
        type="volume",
    ),
    Mount(
        source="seoul-bike-features",
        target=f"{PROJECT_ROOT}/features",
        type="volume",
    ),
    Mount(
        source="seoul-bike-models",
        target=f"{PROJECT_ROOT}/models",
        type="volume",
    ),
    Mount(
        source="seoul-bike-checkpoints",
        target=f"{PROJECT_ROOT}/checkpoints",
        type="volume",
    ),
    Mount(
        source="seoul-bike-logs",
        target=f"{PROJECT_ROOT}/logs",
        type="volume",
    ),
]


default_args = {
    "owner": "seoul-bike",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


with DAG(
    dag_id="seoul_bike_pipeline",
    default_args=default_args,
    description="Seoul Bike Sharing R data and machine-learning pipeline",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["seoul-bike", "r", "machine-learning"],
) as dag:

    preprocess = DockerOperator(
        task_id="preprocess_data",
        image=IMAGE,
        command=[
            "Rscript",
            "preprocess.R",
        ],
        working_dir=PROJECT_ROOT,
        docker_url="unix://var/run/docker.sock",
        network_mode=NETWORK,
        mounts=COMMON_MOUNTS,
        auto_remove="success",
        mount_tmp_dir=False,
    )

    train = DockerOperator(
        task_id="train_models",
        image=IMAGE,
        command=[
            "Rscript",
            "main.R",
        ],
        working_dir=PROJECT_ROOT,
        docker_url="unix://var/run/docker.sock",
        network_mode=NETWORK,
        mounts=COMMON_MOUNTS,
        auto_remove="success",
        mount_tmp_dir=False,
    )

    tests = DockerOperator(
        task_id="run_tests",
        image=IMAGE,
        command=[
            "Rscript",
            "tests/run_all_tests.R",
        ],
        working_dir=PROJECT_ROOT,
        docker_url="unix://var/run/docker.sock",
        network_mode=NETWORK,
        mounts=COMMON_MOUNTS,
        auto_remove="success",
        mount_tmp_dir=False,
    )

    preprocess >> train >> tests