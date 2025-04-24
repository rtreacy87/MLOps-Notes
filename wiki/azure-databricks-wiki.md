# Azure Databricks for Spark Processing

This guide covers using Azure Databricks for big data processing with Apache Spark, focusing on Python with supplementary R support.

## Overview

Azure Databricks is a fast, easy, and collaborative Apache Spark-based analytics platform optimized for Azure. It provides:

- Fully managed Spark clusters
- Interactive workspace with notebooks
- Enterprise security features
- Seamless integration with Azure services
- Support for Python, R, SQL, and Scala

## Key Components

- **Workspace**: Collaborative environment for notebooks and libraries
- **Clusters**: Managed Spark compute resources
- **Notebooks**: Interactive documents with code, visualizations, and text
- **Jobs**: Scheduled or triggered execution of notebooks or JAR files
- **MLflow**: Platform for managing the ML lifecycle
- **Delta Lake**: Storage layer for reliable data lakes

## Getting Started

### Creating a Databricks Workspace

1. In the Azure Portal, search for "Databricks"
2. Click "Create" and fill in the details:
   - Workspace name
   - Subscription
   - Resource group
   - Location
   - Pricing tier (Standard, Premium, or Trial)
3. Click "Review + Create" and then "Create"
4. Once deployment completes, click "Go to resource" and then "Launch Workspace"

### Creating a Cluster

1. In the Databricks workspace, click "Compute" in the sidebar
2. Click "Create Cluster"
3. Configure your cluster:
   - Name: Give your cluster a descriptive name
   - Cluster Mode: Standard or High Concurrency
   - Pool: Select a pool (if available)
   - Databricks Runtime Version: Choose version with ML libraries if needed
   - Node Type: Select VM size
   - Autoscaling: Enable/disable and set min/max workers
   - Auto-termination: Set idle time before shutdown
4. Click "Create Cluster"

## Python in Databricks

### Creating a Python Notebook

1. In the Databricks workspace, click "Workspace" in the sidebar
2. Navigate to your folder or create a new one
3. Click the dropdown next to your folder and select "Create" > "Notebook"
4. Enter a name and select "Python" as the language
5. Click "Create"

### Basic PySpark Example

```python
# Import libraries
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, split, count, desc
import matplotlib.pyplot as plt
import pandas as pd

# Create a DataFrame from a sample dataset
data = [
    ("John", 25, "New York"),
    ("Jane", 30, "San Francisco"),
    ("Bob", 40, "Chicago"),
    ("Alice", 35, "New York")
]
columns = ["name", "age", "city"]
df = spark.createDataFrame(data, columns)

# Display the DataFrame
display(df)

# Perform transformations
city_counts = df.groupBy("city").count().orderBy(desc("count"))
display(city_counts)

# Convert to Pandas for matplotlib visualization
pdf = city_counts.toPandas()
plt.figure(figsize=(10, 6))
plt.bar(pdf["city"], pdf["count"])
plt.title("Count by City")
plt.xlabel("City")
plt.ylabel("Count")
display(plt.gcf())

# Save the DataFrame as a Delta table
df.write.format("delta").mode("overwrite").saveAsTable("people")
```

### Working with Data Sources

```python
# Read from various sources

# CSV
csv_df = spark.read.csv("/mnt/data/mydata.csv", header=True, inferSchema=True)

# Parquet
parquet_df = spark.read.parquet("/mnt/data/mydata.parquet")

# JSON
json_df = spark.read.json("/mnt/data/mydata.json")

# JDBC (SQL Database)
jdbc_df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:sqlserver://server:1433;database=mydb") \
    .option("dbtable", "schema.table") \
    .option("user", "username") \
    .option("password", "password") \
    .load()

# Delta Lake
delta_df = spark.read.format("delta").load("/mnt/delta/mytable")

# Azure Data Lake Storage Gen2
adls_df = spark.read.csv("abfss://container@account.dfs.core.windows.net/path/to/file.csv", 
                         header=True, inferSchema=True)
```

### Machine Learning with MLflow

```python
# Import libraries
import mlflow
import mlflow.sklearn
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
import numpy as np

# Load data
data = spark.table("diamonds").toPandas()
X = data.drop(["price"], axis=1)
y = data["price"]

# One-hot encode categorical features
X = pd.get_dummies(X)

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Start MLflow run
with mlflow.start_run(run_name="Random Forest Model"):
    # Set parameters
    n_estimators = 100
    max_depth = 10
    
    # Log parameters
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    
    # Train model
    rf = RandomForestRegressor(n_estimators=n_estimators, max_depth=max_depth, random_state=42)
    rf.fit(X_train, y_train)
    
    # Make predictions
    predictions = rf.predict(X_test)
    
    # Log metrics
    mse = mean_squared_error(y_test, predictions)
    rmse = np.sqrt(mse)
    r2 = r2_score(y_test, predictions)
    
    mlflow.log_metric("mse", mse)
    mlflow.log_metric("rmse", rmse)
    mlflow.log_metric("r2", r2)
    
    # Log model
    mlflow.sklearn.log_model(rf, "random_forest_model")
    
    # Display results
    print(f"MSE: {mse:.2f}")
    print(f"RMSE: {rmse:.2f}")
    print(f"R²: {r2:.2f}")
```

## R in Databricks

### Creating an R Notebook

1. In the Databricks workspace, click "Workspace" in the sidebar
2. Navigate to your folder or create a new one
3. Click the dropdown next to your folder and select "Create" > "Notebook"
4. Enter a name and select "R" as the language
5. Click "Create"

### Basic SparkR Example

```r
# Import libraries
library(SparkR)
library(ggplot2)

# Create a DataFrame
data <- data.frame(
  name = c("John", "Jane", "Bob", "Alice"),
  age = c(25, 30, 40, 35),
  city = c("New York", "San Francisco", "Chicago", "New York")
)
df <- createDataFrame(data)

# Display the DataFrame
display(df)

# Perform transformations
city_counts <- count(groupBy(df, "city"))
city_counts <- arrange(city_counts, desc(city_counts$count))
display(city_counts)

# Convert to R data.frame for ggplot visualization
r_df <- collect(city_counts)
p <- ggplot(r_df, aes(x = city, y = count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  labs(title = "Count by City", x = "City", y = "Count")
display(p)

# Save the DataFrame as a Delta table
write.df(df, "people_r", "delta", mode = "overwrite")
```

### Working with Data Sources in R

```r
# Read from various sources

# CSV
csv_df <- read.df("/mnt/data/mydata.csv", source = "csv", header = "true", inferSchema = "true")

# Parquet
parquet_df <- read.df("/mnt/data/mydata.parquet", source = "parquet")

# JSON
json_df <- read.df("/mnt/data/mydata.json", source = "json")

# JDBC (SQL Database)
jdbc_df <- read.jdbc("jdbc:sqlserver://server:1433;database=mydb", 
                     "schema.table", 
                     user = "username", 
                     password = "password")

# Delta Lake
delta_df <- read.df("/mnt/delta/mytable", source = "delta")

# Azure Data Lake Storage Gen2
adls_df <- read.df("abfss://container@account.dfs.core.windows.net/path/to/file.csv", 
                   source = "csv", header = "true", inferSchema = "true")
```

### Machine Learning with R and MLflow

```r
# Import libraries
library(mlflow)
library(randomForest)
library(caret)
library(dplyr)

# Load data
data <- as.data.frame(table("diamonds"))

# Prepare data
X <- data %>% select(-price)
y <- data$price

# Convert categorical variables to factors
X <- X %>% mutate_if(is.character, as.factor)

# Split data
set.seed(42)
train_index <- createDataPartition(y, p = 0.8, list = FALSE)
X_train <- X[train_index, ]
X_test <- X[-train_index, ]
y_train <- y[train_index]
y_test <- y[-train_index]

# Start MLflow run
mlflow_start_run(run_name = "Random Forest Model R")

# Set parameters
n_estimators <- 100
max_depth <- 10

# Log parameters
mlflow_log_param("n_estimators", n_estimators)
mlflow_log_param("max_depth", max_depth)

# Train model
rf <- randomForest(
  x = X_train,
  y = y_train,
  ntree = n_estimators,
  maxdepth = max_depth
)

# Make predictions
predictions <- predict(rf, X_test)

# Calculate metrics
mse <- mean((y_test - predictions)^2)
rmse <- sqrt(mse)
r2 <- 1 - sum((y_test - predictions)^2) / sum((y_test - mean(y_test))^2)

# Log metrics
mlflow_log_metric("mse", mse)
mlflow_log_metric("rmse", rmse)
mlflow_log_metric("r2", r2)

# Log model
mlflow_log_model(rf, "random_forest_model_r")

# End run
mlflow_end_run()

# Display results
cat(sprintf("MSE: %.2f\n", mse))
cat(sprintf("RMSE: %.2f\n", rmse))
cat(sprintf("R²: %.2f\n", r2))
```

## Integrating Python and R

### Using R in a Python Notebook

```python
# Use %r magic command to run R code in a Python notebook
%r
# R code here
library(ggplot2)
data <- data.frame(x = 1:10, y = 1:10)
ggplot(data, aes(x, y)) + geom_point()
```

### Using Python in an R Notebook

```r
# Use %python magic command to run Python code in an R notebook
%python
# Python code here
import matplotlib.pyplot as plt
import numpy as np
x = np.linspace(0, 10, 100)
y = np.sin(x)
plt.plot(x, y)
plt.title("Sine Wave")
plt.show()
```

## Best Practices

1. **Optimize Cluster Configuration**:
   - Right-size your clusters for your workload
   - Use autoscaling to handle variable loads
   - Enable auto-termination to save costs

2. **Data Management**:
   - Use Delta Lake for reliable data storage
   - Partition large tables appropriately
   - Cache frequently accessed data

3. **Performance Tuning**:
   - Use broadcast joins for small tables
   - Repartition data when necessary
   - Monitor and tune Spark configurations

4. **Development Workflow**:
   - Use notebooks for exploration
   - Refactor code into libraries for production
   - Use Databricks Repos for version control

5. **Security**:
   - Use Secrets for sensitive information
   - Implement proper access controls
   - Enable table access control in Unity Catalog

## Next Steps

- [Azure Data Factory/Synapse for Orchestration](azure-data-orchestration.md)
- [Azure Functions for Serverless Processing](azure-functions-wiki.md)
