# Summary

This is sample demo to show use of spark to pull data from sql server to apache ice-berg. It:
- Creates and initializes docker container for sql server database
- Setup docker containers for spark cluster in standalone mode
- Builds pyspark based docker container that executes in spark cluster to pull data from sql server and writes to iceberg tables. It:
    - Uses poetry for packaging and virtual env management
    - Uses local Spark iceberg catalog to write sql data

# Execution Steps 

Below are 2 options to run the app (with Or without docker)

## Option 1: Execute via docker build 

- Pre-requisite:
    - Docker installed & docker engine running on local machine
    - Machine with min 7 GB RAM
    - Code is checked out into your local machine
- Launch docker containers (sql server, spark-master, spark-worker & spark history server)  using commands below

```
## Start the containers
docker-compose up --force-recreate --no-deps --build

```

-- Verify if the Spark cluster is running be visiting http://localhost:8080/

- Submit Spark job to load sql data to local iceberg tables (from /opt/spark folter)
```
## Bash into spark master container
docker exec -it spark-master bash

## Run python module
./bin/spark-submit ./siceberg_spark_sqlserver/main.py
```  

## Option 2 --> Run without docker

- Pre-requisite
    - pyenv installed (>=3.1.1)
    - poetry installed (>= 2.0.1)
    - Machine with min 7 GB RAM
    - Spark is installed
    - Hadoop (winutils) for windows machine is installed
    - Ensure following env variable is set:
        - SPARK_HOME
        - HADOOP_HOME 

- VS Code Notes
    - Python Lanugage Server: Pylance
    - Pylance settings -> Type checking: basic 

- Create virtual environment using poetry install from root of project
```
poetry install
```

- Add Spark runtime and extension jars, ms sql spark connector, ms sql jdbc driver jars in %SPARK_HOME%\jars folder

```
iceberg-spark-runtime-3.4_2.12-1.4.3.jar
iceberg-spark-extensions-3.4_2.12-1.4.3.jar
spark-mssql-connector_2.12-1.4.0-BETA.jar
mssql-jdbc-12.8.1.jre11.jar
```  

- Set local ms sql server and initialize with dummy data
```
sqlcmd -S localhost -U sa -P 'StrongPwd@123' -C -d master -i iceberg_spark_sqlserver/mssql-init.sql
```

- Execute the spark job Or python script to load data from ms sql to iceberg table
```
python -m .iceberg_spark_sqlserver.main
```

