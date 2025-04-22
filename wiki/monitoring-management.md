# Monitoring and Management for Azure ML

This guide covers how to set up monitoring for deployed models and implement logging strategies using command-line tools.

## Table of Contents
- [Introduction to ML Monitoring](#introduction-to-ml-monitoring)
- [Setting Up Model Monitoring](#setting-up-model-monitoring)
- [Logging Strategies](#logging-strategies)
- [Data and Model Drift Detection](#data-and-model-drift-detection)
- [Performance Monitoring](#performance-monitoring)
- [Alerting and Notifications](#alerting-and-notifications)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)

## Introduction to ML Monitoring

Monitoring machine learning systems in production is critical for:
- Ensuring model performance meets business requirements
- Detecting data and model drift
- Identifying performance bottlenecks
- Troubleshooting issues
- Meeting compliance requirements

## Setting Up Model Monitoring

### Enabling Application Insights

When deploying a model, enable Application Insights for monitoring:

```bash
# Deploy a model with monitoring enabled
az ml online-endpoint create --file endpoint.yml --workspace-name myworkspace --resource-group myresourcegroup
az ml online-deployment create --file deployment.yml --endpoint-name myendpoint --workspace-name myworkspace --resource-group myresourcegroup
```

Example deployment YAML with monitoring:

```yaml
# deployment.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: production
endpoint_name: myendpoint
model: azureml:mymodel:1
instance_type: Standard_DS3_v2
instance_count: 1
app_insights_enabled: true
```

### Checking Monitoring Status

```bash
# Check if monitoring is enabled for a deployment
az ml online-deployment show --name production --endpoint-name myendpoint --workspace-name myworkspace --resource-group myresourcegroup --query appInsightsEnabled
```

## Logging Strategies

### Configuring Logging in Scoring Scripts

Include proper logging in your scoring script:

```python
# score.py
import logging
import json
import os
import numpy as np
from inference_schema.schema_decorators import input_schema, output_schema
from inference_schema.parameter_types.numpy_parameter_type import NumpyParameterType

def init():
    global model
    # AZUREML_MODEL_DIR is an environment variable created during deployment
    model_path = os.path.join(os.getenv('AZUREML_MODEL_DIR'), 'model.pkl')
    # Load the model
    model = joblib.load(model_path)
    logging.info("Model loaded successfully")

@input_schema('data', NumpyParameterType(np.array([[0.0, 0.0, 0.0, 0.0]]))
@output_schema(NumpyParameterType(np.array([0.0])))
def run(data):
    try:
        # Log input data statistics
        logging.info(f"Input data shape: {data.shape}")
        
        # Make prediction
        result = model.predict(data)
        
        # Log prediction statistics
        logging.info(f"Prediction made successfully. Output shape: {result.shape}")
        
        return result.tolist()
    except Exception as e:
        logging.error(f"Exception during prediction: {str(e)}")
        return {"error": str(e)}
```

### Retrieving Logs

```bash
# Get logs from a deployment
az ml online-deployment get-logs --name production --endpoint-name myendpoint --workspace-name myworkspace --resource-group myresourcegroup

# Filter logs by time
az ml online-deployment get-logs --name production --endpoint-name myendpoint --lines 100 --since 1h --workspace-name myworkspace --resource-group myresourcegroup
```

## Data and Model Drift Detection

### Setting Up Data Drift Monitoring

```bash
# Create a data drift monitor
az ml data-drift-monitor create --file drift-monitor.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example data drift monitor YAML:

```yaml
# drift-monitor.yml
$schema: https://azuremlschemas.azureedge.net/latest/dataDriftMonitor.schema.json
name: production_drift_monitor
target_dataset:
  path: azureml:production_data:1
  mode: ro_mount
reference_dataset:
  path: azureml:training_data:1
  mode: ro_mount
compute: azureml:cpu-cluster
frequency: Day
features_to_monitor:
  - feature1
  - feature2
  - feature3
alert_settings:
  email:
    - user@example.com
  threshold: 0.3
```

### Checking Drift Metrics

```bash
# Get drift metrics
az ml data-drift-monitor show-metrics --name production_drift_monitor --workspace-name myworkspace --resource-group myresourcegroup
```

## Performance Monitoring

### Monitoring Endpoint Performance

```bash
# Get endpoint metrics
az ml online-endpoint get-metrics --name myendpoint --workspace-name myworkspace --resource-group myresourcegroup
```

### Setting Up Custom Metrics

Include custom metrics in your scoring script:

```python
# In score.py
from opencensus.ext.azure.metrics_exporter import AzureMetricsExporter
from opencensus.stats import aggregation as aggregation_module
from opencensus.stats import measure as measure_module
from opencensus.stats import stats as stats_module
from opencensus.stats import view as view_module
from opencensus.tags import tag_map as tag_map_module

# Create metrics
prediction_time = measure_module.MeasureFloat("prediction_time", "Time to make prediction", "ms")
prediction_count = measure_module.MeasureInt("prediction_count", "Number of predictions", "predictions")

# Create views
prediction_time_view = view_module.View("prediction_time", "Time to make prediction",
                                       [], prediction_time, aggregation_module.LastValueAggregation())
prediction_count_view = view_module.View("prediction_count", "Number of predictions",
                                        [], prediction_count, aggregation_module.CountAggregation())

# Register views
stats = stats_module.stats
view_manager = stats.view_manager
view_manager.register_view(prediction_time_view)
view_manager.register_view(prediction_count_view)

# Create metrics exporter
exporter = AzureMetricsExporter()
view_manager.register_exporter(exporter)

def run(data):
    try:
        # Create measurement map
        mmap = stats.stats_recorder.new_measurement_map()
        tmap = tag_map_module.TagMap()
        
        # Record start time
        start_time = time.time()
        
        # Make prediction
        result = model.predict(data)
        
        # Record metrics
        prediction_time_ms = (time.time() - start_time) * 1000.0
        mmap.measure_float_put(prediction_time, prediction_time_ms)
        mmap.measure_int_put(prediction_count, 1)
        mmap.record(tmap)
        
        return result.tolist()
    except Exception as e:
        logging.error(f"Exception during prediction: {str(e)}")
        return {"error": str(e)}
```

## Alerting and Notifications

### Setting Up Alerts with Azure Monitor

```bash
# Create an alert rule
az monitor alert create --name high-latency-alert \
  --resource-group myresourcegroup \
  --scopes /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.MachineLearningServices/workspaces/myworkspace/onlineEndpoints/myendpoint \
  --condition "avg Latency > 200" \
  --description "Alert when average latency exceeds 200ms" \
  --evaluation-frequency 5m \
  --window-size 5m
```

### Configuring Action Groups

```bash
# Create an action group for email notifications
az monitor action-group create --name ml-alerts \
  --resource-group myresourcegroup \
  --action email ml-team ml-team@example.com \
  --short-name mlalerts
```

## Troubleshooting Common Issues

### Common Monitoring Issues

1. **Missing Logs**: Ensure Application Insights is enabled and properly configured
2. **High Latency**: Check resource allocation and optimize scoring script
3. **Memory Issues**: Monitor memory usage and adjust instance size if needed
4. **Failed Requests**: Check input validation and error handling in scoring script

### Diagnostic Commands

```bash
# Check endpoint health
az ml online-endpoint get-logs --name myendpoint --deployment production --workspace-name myworkspace --resource-group myresourcegroup

# Check compute resource usage
az ml online-deployment get-metrics --name production --endpoint-name myendpoint --workspace-name myworkspace --resource-group myresourcegroup
```

## Next Steps

- Implement [governance and compliance](governance-compliance.md) for your ML systems
- Learn about [cost management](cost-management.md) for ML workloads
- Explore [security best practices](security-practices.md) for ML environments
