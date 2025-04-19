# Advanced Features in Azure ML

This guide covers how to leverage automated ML and model interpretability tools using command-line interfaces.

## Table of Contents
- [Automated Machine Learning](#automated-machine-learning)
- [Model Interpretability](#model-interpretability)
- [Feature Store](#feature-store)
- [Responsible AI Dashboard](#responsible-ai-dashboard)
- [Distributed Training](#distributed-training)
- [Hyperparameter Optimization at Scale](#hyperparameter-optimization-at-scale)
- [Online Experimentation](#online-experimentation)
- [MLflow Integration](#mlflow-integration)
- [ONNX Model Export](#onnx-model-export)

## Automated Machine Learning

Automated Machine Learning (AutoML) automates the process of algorithm selection, feature engineering, hyperparameter tuning, and model evaluation.

### Creating an AutoML Job

```bash
# Create an AutoML job for classification
az ml job create --file automl-classification.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example AutoML job YAML:

```yaml
# automl-classification.yml
$schema: https://azuremlschemas.azureedge.net/latest/autoMLJob.schema.json
type: automl
experiment_name: automl-classification
compute: azureml:cpu-cluster
task: classification
primary_metric: accuracy
training_data:
  path: azureml:training-data:1
  type: mltable
validation_data:
  path: azureml:validation-data:1
  type: mltable
target_column_name: target
featurization:
  mode: auto
limits:
  timeout_minutes: 60
  max_trials: 20
  max_concurrent_trials: 4
training_parameters:
  early_stopping: True
  enable_model_explainability: True
  enable_voting_ensemble: True
  enable_stack_ensemble: True
```

### Retrieving AutoML Results

```bash
# Get the best model from AutoML
az ml job show --name <automl-job-name> --workspace-name myworkspace --resource-group myresourcegroup --query outputs.best_model

# Download AutoML outputs
az ml job download --name <automl-job-name> --workspace-name myworkspace --resource-group myresourcegroup --output-path ./automl-outputs
```

## Model Interpretability

Model interpretability helps understand how models make predictions and which features have the most impact.

### Generating Model Explanations

```bash
# Create a job to generate model explanations
az ml job create --file model-explain.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example model explanation job YAML:

```yaml
# model-explain.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python explain.py 
  --model-path ${{inputs.model}}
  --test-data ${{inputs.test_data}}
  --output-path ${{outputs.explanations}}
inputs:
  model:
    path: azureml:mymodel:1
  test_data:
    path: azureml:test-data:1
    mode: ro_mount
outputs:
  explanations:
    type: uri_folder
environment: azureml:explanation-env:1
compute: azureml:cpu-cluster
```

Example explanation script:

```python
# explain.py
import argparse
import mlflow
import pandas as pd
import numpy as np
from interpret.ext.blackbox import TabularExplainer
from azureml.core import Run

parser = argparse.ArgumentParser()
parser.add_argument("--model-path", type=str)
parser.add_argument("--test-data", type=str)
parser.add_argument("--output-path", type=str)
args = parser.parse_args()

# Load model
model = mlflow.sklearn.load_model(args.model_path)

# Load test data
test_data = pd.read_csv(args.test_data)
X_test = test_data.drop('target', axis=1)
feature_names = X_test.columns.tolist()

# Create explainer
explainer = TabularExplainer(model, X_test, features=feature_names)

# Generate global explanations
global_explanation = explainer.explain_global()

# Generate local explanations for a sample
sample_indices = np.random.choice(X_test.shape[0], 10, replace=False)
local_explanation = explainer.explain_local(X_test.iloc[sample_indices])

# Save explanations
import pickle
with open(f"{args.output_path}/global_explanation.pkl", "wb") as f:
    pickle.dump(global_explanation, f)
with open(f"{args.output_path}/local_explanation.pkl", "wb") as f:
    pickle.dump(local_explanation, f)

# Save feature importance plot data
import json
global_importance_values = global_explanation.get_feature_importance_dict()
with open(f"{args.output_path}/feature_importance.json", "w") as f:
    json.dump(global_importance_values, f)

print("Explanations generated successfully")
```

## Feature Store

Azure ML Feature Store allows you to create, share, and manage features for machine learning.

### Creating a Feature Store

```bash
# Create a feature store
az ml feature-store create --file feature-store.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example feature store YAML:

```yaml
# feature-store.yml
$schema: https://azuremlschemas.azureedge.net/latest/featureStore.schema.json
name: ml-feature-store
description: Feature store for ML projects
online_store:
  type: azure_sql
  resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.Sql/servers/myserver/databases/mydb
offline_store:
  type: azure_data_lake_gen2
  resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.Storage/storageAccounts/mystorageaccount
```

### Registering Features

```bash
# Register a feature set
az ml feature-set create --file customer-features.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example feature set YAML:

```yaml
# customer-features.yml
$schema: https://azuremlschemas.azureedge.net/latest/featureSet.schema.json
name: customer-features
version: 1
feature_store: ml-feature-store
entities:
  - name: customer_id
    type: string
features:
  - name: age
    type: int
  - name: income
    type: float
  - name: tenure
    type: int
  - name: has_credit_card
    type: boolean
source:
  type: spark
  path: azureml://datastores/customer_data/paths/customers.parquet
  timestamp_column: event_timestamp
  entity_column: customer_id
```

### Using Features in Training

```bash
# Create a feature retrieval job
az ml job create --file feature-retrieval.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example feature retrieval job YAML:

```yaml
# feature-retrieval.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python retrieve_features.py 
  --feature-set customer-features 
  --output-path ${{outputs.training_data}}
outputs:
  training_data:
    type: uri_folder
environment: azureml:feature-env:1
compute: azureml:cpu-cluster
```

## Responsible AI Dashboard

The Responsible AI dashboard provides tools for model assessment, fairness, and interpretability.

### Generating a Responsible AI Dashboard

```bash
# Create a job to generate a Responsible AI dashboard
az ml job create --file rai-dashboard.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example Responsible AI dashboard job YAML:

```yaml
# rai-dashboard.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python generate_rai_dashboard.py 
  --model-path ${{inputs.model}}
  --test-data ${{inputs.test_data}}
  --target-column target
  --categorical-columns category1 category2
  --sensitive-columns gender age
  --output-path ${{outputs.dashboard}}
inputs:
  model:
    path: azureml:mymodel:1
  test_data:
    path: azureml:test-data:1
    mode: ro_mount
outputs:
  dashboard:
    type: uri_folder
environment: azureml:rai-env:1
compute: azureml:cpu-cluster
```

Example RAI dashboard script:

```python
# generate_rai_dashboard.py
import argparse
import mlflow
import pandas as pd
from raiwidgets import ResponsibleAIDashboard
from responsibleai import RAIInsights

parser = argparse.ArgumentParser()
parser.add_argument("--model-path", type=str)
parser.add_argument("--test-data", type=str)
parser.add_argument("--target-column", type=str)
parser.add_argument("--categorical-columns", nargs="+", default=[])
parser.add_argument("--sensitive-columns", nargs="+", default=[])
parser.add_argument("--output-path", type=str)
args = parser.parse_args()

# Load model
model = mlflow.sklearn.load_model(args.model_path)

# Load test data
data = pd.read_csv(args.test_data)
X = data.drop(args.target_column, axis=1)
y = data[args.target_column]

# Create RAI insights
rai_insights = RAIInsights(
    model=model,
    name="Model Insights",
    description="Responsible AI insights for model",
    task_type="classification",
    dataset=X,
    target_column=args.target_column,
    categorical_features=args.categorical_columns,
    sensitive_features=args.sensitive_columns
)

# Add explainability
rai_insights.explainer.add()

# Add fairness
rai_insights.fairness.add(
    sensitive_features=args.sensitive_columns,
    prediction_type="probability"
)

# Add error analysis
rai_insights.error_analysis.add()

# Add causal analysis
rai_insights.causal.add()

# Compute insights
rai_insights.compute()

# Save insights
rai_insights.save(args.output_path)

print("Responsible AI dashboard generated successfully")
```

## Distributed Training

Azure ML supports distributed training for deep learning models across multiple nodes.

### Creating a Distributed Training Job

```bash
# Create a distributed training job
az ml job create --file distributed-training.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example distributed training job YAML:

```yaml
# distributed-training.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python distributed_train.py 
  --data-path ${{inputs.training_data}}
  --epochs 50
  --batch-size 32
inputs:
  training_data:
    path: azureml:training-data:1
    mode: ro_mount
environment: azureml:pytorch-env:1
compute: azureml:gpu-cluster
distribution:
  type: pytorch
  process_count_per_instance: 4
resources:
  instance_count: 2
```

Example distributed training script:

```python
# distributed_train.py
import argparse
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.nn.functional as F
from torch.nn.parallel import DistributedDataParallel
import torch.optim as optim
from torch.utils.data import DataLoader, DistributedSampler

parser = argparse.ArgumentParser()
parser.add_argument("--data-path", type=str)
parser.add_argument("--epochs", type=int, default=10)
parser.add_argument("--batch-size", type=int, default=32)
args = parser.parse_args()

# Initialize distributed training
dist.init_process_group(backend='nccl')
local_rank = dist.get_rank()
torch.cuda.set_device(local_rank)
device = torch.device("cuda", local_rank)

# Create model
model = MyModel().to(device)
model = DistributedDataParallel(model, device_ids=[local_rank])

# Load data with distributed sampler
train_dataset = MyDataset(args.data_path)
train_sampler = DistributedSampler(train_dataset)
train_loader = DataLoader(
    train_dataset,
    batch_size=args.batch_size,
    sampler=train_sampler,
    num_workers=4
)

# Training loop
optimizer = optim.Adam(model.parameters(), lr=0.001)
for epoch in range(args.epochs):
    train_sampler.set_epoch(epoch)
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.cross_entropy(output, target)
        loss.backward()
        optimizer.step()
        
        if local_rank == 0 and batch_idx % 10 == 0:
            print(f"Epoch: {epoch}, Batch: {batch_idx}, Loss: {loss.item()}")

# Save model (only on rank 0)
if local_rank == 0:
    torch.save(model.module.state_dict(), "model.pt")
```

## Hyperparameter Optimization at Scale

Azure ML supports large-scale hyperparameter optimization with various sampling methods.

### Creating a Large-Scale Sweep Job

```bash
# Create a hyperparameter tuning job
az ml job create --file large-sweep.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example large-scale sweep job YAML:

```yaml
# large-sweep.yml
$schema: https://azuremlschemas.azureedge.net/latest/sweepJob.schema.json
type: sweep
trial:
  command: >
    python train.py 
    --learning-rate ${{search_space.learning_rate}} 
    --batch-size ${{search_space.batch_size}}
    --optimizer ${{search_space.optimizer}}
    --hidden-units ${{search_space.hidden_units}}
    --dropout ${{search_space.dropout}}
  environment: azureml:training-env:1
  compute: azureml:gpu-cluster
  resources:
    instance_count: 1
search_space:
  learning_rate:
    type: uniform
    min_value: 0.0001
    max_value: 0.1
  batch_size:
    type: choice
    values: [16, 32, 64, 128, 256]
  optimizer:
    type: choice
    values: ["adam", "sgd", "rmsprop"]
  hidden_units:
    type: choice
    values: [64, 128, 256, 512, 1024]
  dropout:
    type: uniform
    min_value: 0.1
    max_value: 0.5
objective:
  primary_metric: accuracy
  goal: maximize
sampling_algorithm: bayesian
limits:
  max_total_trials: 100
  max_concurrent_trials: 10
  timeout: 14400
early_termination:
  type: bandit
  evaluation_interval: 2
  slack_factor: 0.2
  delay_evaluation: 6
```

## Online Experimentation

Azure ML supports online experimentation for A/B testing and multi-armed bandit scenarios.

### Setting Up an Online Endpoint with Traffic Split

```bash
# Create an online endpoint with multiple deployments
az ml online-endpoint create --file online-endpoint.yml --workspace-name myworkspace --resource-group myresourcegroup
az ml online-deployment create --file deployment-a.yml --endpoint-name experiment-endpoint --workspace-name myworkspace --resource-group myresourcegroup
az ml online-deployment create --file deployment-b.yml --endpoint-name experiment-endpoint --workspace-name myworkspace --resource-group myresourcegroup
```

Example online endpoint YAML:

```yaml
# online-endpoint.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: experiment-endpoint
auth_mode: key
traffic:
  model-a: 50
  model-b: 50
```

Example deployment YAML:

```yaml
# deployment-a.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: model-a
endpoint_name: experiment-endpoint
model: azureml:model-a:1
environment: azureml:serving-env:1
instance_type: Standard_DS3_v2
instance_count: 1
```

### Updating Traffic Allocation

```bash
# Update traffic allocation based on experiment results
az ml online-endpoint update --name experiment-endpoint --traffic "model-a=75 model-b=25" --workspace-name myworkspace --resource-group myresourcegroup
```

## MLflow Integration

Azure ML integrates with MLflow for experiment tracking, model management, and deployment.

### Tracking Experiments with MLflow

```bash
# Create a job with MLflow tracking
az ml job create --file mlflow-job.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example MLflow job YAML:

```yaml
# mlflow-job.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python mlflow_train.py 
  --data-path ${{inputs.training_data}}
  --learning-rate 0.01
inputs:
  training_data:
    path: azureml:training-data:1
    mode: ro_mount
environment: azureml:mlflow-env:1
compute: azureml:cpu-cluster
```

Example MLflow training script:

```python
# mlflow_train.py
import argparse
import mlflow
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

parser = argparse.ArgumentParser()
parser.add_argument("--data-path", type=str)
parser.add_argument("--learning-rate", type=float, default=0.01)
args = parser.parse_args()

# Start MLflow run
mlflow.start_run()

# Log parameters
mlflow.log_param("learning_rate", args.learning_rate)
mlflow.log_param("data_path", args.data_path)

# Load data
data = pd.read_csv(args.data_path)
X = data.drop("target", axis=1)
y = data["target"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Evaluate model
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, average='weighted')
recall = recall_score(y_test, y_pred, average='weighted')
f1 = f1_score(y_test, y_pred, average='weighted')

# Log metrics
mlflow.log_metric("accuracy", accuracy)
mlflow.log_metric("precision", precision)
mlflow.log_metric("recall", recall)
mlflow.log_metric("f1", f1)

# Log model
mlflow.sklearn.log_model(model, "model")

# End MLflow run
mlflow.end_run()
```

### Registering MLflow Models

```bash
# Register an MLflow model
az ml model create --name mlflow-model --version 1 --path azureml://jobs/<job-id>/outputs/model --type mlflow_model --workspace-name myworkspace --resource-group myresourcegroup
```

## ONNX Model Export

ONNX (Open Neural Network Exchange) provides interoperability between different ML frameworks.

### Exporting Models to ONNX

```bash
# Create a job to export a model to ONNX
az ml job create --file onnx-export.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example ONNX export job YAML:

```yaml
# onnx-export.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python export_to_onnx.py 
  --model-path ${{inputs.model}}
  --output-path ${{outputs.onnx_model}}
inputs:
  model:
    path: azureml:mymodel:1
outputs:
  onnx_model:
    type: uri_folder
environment: azureml:onnx-env:1
compute: azureml:cpu-cluster
```

Example ONNX export script:

```python
# export_to_onnx.py
import argparse
import mlflow
import numpy as np
import onnxmltools
from onnxmltools.convert import convert_sklearn
from onnxconverter_common.data_types import FloatTensorType

parser = argparse.ArgumentParser()
parser.add_argument("--model-path", type=str)
parser.add_argument("--output-path", type=str)
args = parser.parse_args()

# Load model
model = mlflow.sklearn.load_model(args.model_path)

# Get input shape
# Assuming the model expects a 2D array with n_features columns
n_features = model.n_features_in_ if hasattr(model, 'n_features_in_') else model.feature_importances_.shape[0]
initial_type = [('float_input', FloatTensorType([None, n_features]))]

# Convert to ONNX
onnx_model = convert_sklearn(model, initial_types=initial_type)

# Save ONNX model
onnx_path = f"{args.output_path}/model.onnx"
onnxmltools.utils.save_model(onnx_model, onnx_path)

print(f"Model exported to ONNX format at {onnx_path}")
```

## Next Steps

- Learn about [daily MLOps workflows](daily-workflows.md)
- Explore [Azure ecosystem integration](azure-ecosystem.md) for ML workflows
- Check out the [command-line cheat sheets](cheatsheets/aml-cli-commands.md) for quick reference
