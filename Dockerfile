#################################
## 1st stage 
## -- Create Poetry base stage that installs project (non root) dependencies in .venv
#################################
FROM python:3.10-bookworm AS poetry-base

## Pin specific poetry version to avoid any breaking changes in any other version
RUN pip install poetry==2.0.1

## Set Poetry env variables
## https://python-poetry.org/docs/configuration/#using-environment-variables
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Working dir
WORKDIR /app

# Not copying README.md in container to prevent docker layer caching whenever its modified
COPY pyproject.toml poetry.lock ./
RUN touch README.md

## RUN poetry install --without dev && rm -rf $POETRY_CACHE_DIR
## We dont need cache as part of final image
## We install only dependency fitst and not project (no root). This is to avoid rebuiding this layer on code change
RUN poetry install --no-root && rm -rf $POETRY_CACHE_DIR

#################################
## 2nd stage
# Add Spark runtime and iceberg related jars
#################################
FROM python:3.10-slim-bookworm AS spark-base

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=poetry-base ${VIRTUAL_ENV} ${VIRTUAL_ENV}

## Install Spark and Hadoop
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      vim \
      unzip \
      rsync \
      openjdk-17-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Download spark and hadoop dependencies and install

# ENV variables
ENV SPARK_HOME="/opt/spark"
ENV HADOOP_HOME="/opt/hadoop"
ENV SPARK_VERSION=3.5.4
ENV PYTHONPATH=$SPARK_HOME/python

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST=spark-master
ENV SPARK_MASTER_PORT=7077
ENV PYSPARK_PYTHON=python3

# Add iceberg spark runtime jar to IJava classpath
ENV IJAVA_CLASSPATH=/opt/spark/jars/*

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}
WORKDIR ${SPARK_HOME}

# Download spark
RUN mkdir -p ${SPARK_HOME} \
    && curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
    && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

COPY conf/spark-defaults.conf "$SPARK_HOME/conf"

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

#################################
## 3rd stage
# -- Copy venv from poetry-base into spark base
# -- Download spark run time jars
#################################
# The runtime image, used to just run the code provided its virtual environment
# poetry is not needed (to ensure our image size is less)
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=poetry-base ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY iceberg_spark_sqlserver ./iceberg_spark_sqlserver

## Poetry install (with project copiedl)
## Dependency is already copied in virtual env
# RUN poetry install is not needed as project is copied

# Download iceberg spark runtime
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.4_2.12/1.4.3/iceberg-spark-runtime-3.4_2.12-1.4.3.jar -Lo /opt/spark/jars/iceberg-spark-runtime-3.4_2.12-1.4.3.jar

# Download sql connector & jdbc drivers
RUN curl https://github.com/microsoft/sql-spark-connector/releases/download/v1.4.0/spark-mssql-connector_2.12-1.4.0-BETA.jar -Lo /opt/spark/jars/spark-mssql-connector_2.12-1.4.0-BETA.jar
RUN curl https://github.com/microsoft/mssql-jdbc/releases/download/v12.8.1/mssql-jdbc-12.8.1.jre11.jar -Lo /opt/spark/jars/mssql-jdbc-12.8.1.jre11.jar

COPY entrypoint.sh .
RUN chmod u+x /opt/spark/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD [ "bash" ]
