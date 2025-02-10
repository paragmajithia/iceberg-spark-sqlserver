print("""===========================
      Importing Spark sql
===========================
      """)
from pyspark.sql import SparkSession
from pyspark import SparkConf
from dotenv import load_dotenv, find_dotenv
import os

# Find the correct .env file based on the current environment
env_file = find_dotenv(f'.env.{os.getenv("APP_ENV", "local")}')

# Load the environment variables from the .env file
load_dotenv(env_file)

## Constants
warehouse_path = "./warehouse"
iceberg_spark_jar = 'org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.4.3'
iceberg_spark_ext = 'org.apache.iceberg:iceberg-spark-extensions-3.4_2.12:1.4.3'
spark_mssql_connector = 'com.microsoft.azure:spark-mssql-connector_2.12:1.4.0-BETA'
mssql_jdbc_driver = 'com.microsoft.sqlserver:mssql-jdbc:12.8.1.jre11'
catalog_name = "product"

# Setup iceberg config
conf = SparkConf().setAppName("iceberg-sqlserver") \
    .set("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .set(f"spark.sql.catalog.{catalog_name}", "org.apache.iceberg.spark.SparkCatalog") \
    .set('spark.jars.packages', iceberg_spark_jar) \
    .set('spark.jars.packages', iceberg_spark_ext) \
    .set('spark.jars.packages', spark_mssql_connector) \
    .set('spark.jars.packages', mssql_jdbc_driver) \
    .set(f"spark.sql.catalog.{catalog_name}.warehouse", warehouse_path) \
    .set(f"spark.sql.catalog.{catalog_name}.type", "hadoop")\
    .set("spark.sql.defaultCatalog", catalog_name)

# Create spark session
spark = SparkSession.builder.config(conf=conf).getOrCreate() # type: ignore
spark.sparkContext.setLogLevel("ERROR")

'''
Create sample RDD, convert to data frame and show it
'''
columns = ["id", "name","age","gender"]
data = [(1, "James",30,"M"), (2, "Ann",40,"F"),
    (3, "Jeff",41,"M"),(4, "Jennifer",20,"F")]
sampleDF = spark.sparkContext.parallelize(data).toDF(columns)
sampleDF.show()


'''
Read from sql server
'''
print("""
===========================
Reading from sql server now
===========================
""")

## local host for local run
## sql service service when running in container
SERVER = os.getenv('DB_HOST')
DATABASE = 'product-db'
USER = 'sa'
PWD = 'StrongPwd@123'
# df = spark.read \
#   .format("jdbc") \
#   .option("url", f"jdbc:sqlserver://{SERVER};databaseName={DATABASE};trusted_connection=yes;trustServerCertificate=true;integratedSecurity=true;") \
#   .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
#   .option("dbtable", "users") \
#   .load()

df = spark.read \
  .format("com.microsoft.sqlserver.jdbc.spark") \
  .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
  .option("url", f"jdbc:sqlserver://{SERVER};databaseName={DATABASE};trusted_connection=yes;trustServerCertificate=true;integratedSecurity=false;") \
  .option("dbtable", "product") \
  .option("user", USER) \
  .option("password", PWD) \
  .load()

  #.format("com.microsoft.sqlserver.jdbc.spark") \
  # .format("jdbc") \
df.show()

'''
Create iceberg table if not exists
'''
print("""
===========================
Creating / Replacing ice berg table
===========================
""")

# Create database
# spark.sql(f"CREATE DATABASE IF NOT EXISTS productdb")

# spark.sql("""
#   CREATE TABLE IF NOT EXISTS product.productdb.product (
#     id INT,
#     name STRING,
#     description STRING
#   ) USING iceberg
#   PARTITIONED BY (name)
#   """)

# Write and read Iceberg table
table_name = f"product_ice_db.product"
df.write.format("iceberg").mode("overwrite").saveAsTable(f"{table_name}")
iceberg_df = spark.read.format("iceberg").load(f"{table_name}")
iceberg_df.printSchema()
iceberg_df.show()

