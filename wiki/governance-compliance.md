# Governance and Compliance for Azure ML

This guide covers how to manage model registry and documentation through the command line to ensure proper governance and compliance of your ML systems.

## Table of Contents
- [Introduction to ML Governance](#introduction-to-ml-governance)
- [Model Registry Management](#model-registry-management)
- [Model Documentation](#model-documentation)
- [Audit and Compliance](#audit-and-compliance)
- [Responsible AI Practices](#responsible-ai-practices)
- [Regulatory Compliance](#regulatory-compliance)

## Introduction to ML Governance

ML governance is the framework for managing, documenting, and controlling machine learning assets throughout their lifecycle. Key aspects include:

- Model versioning and lineage tracking
- Documentation of model development and deployment
- Access control and permissions
- Audit trails for compliance
- Responsible AI practices

## Model Registry Management

### Registering Models

```bash
# Register a model with metadata
az ml model create --name customer-churn-model \
  --version 1 \
  --path azureml://jobs/<job-id>/outputs/model \
  --description "Customer churn prediction model" \
  --tags "algorithm=xgboost" "accuracy=0.85" "owner=data-science-team" \
  --workspace-name myworkspace \
  --resource-group myresourcegroup
```

### Managing Model Versions

```bash
# List all versions of a model
az ml model list --name customer-churn-model --workspace-name myworkspace --resource-group myresourcegroup

# Show details of a specific model version
az ml model show --name customer-churn-model --version 1 --workspace-name myworkspace --resource-group myresourcegroup

# Update model metadata
az ml model update --name customer-churn-model --version 1 --set tags.status=approved --workspace-name myworkspace --resource-group myresourcegroup
```

### Model Approval Workflow

```bash
# Tag a model as under review
az ml model update --name customer-churn-model --version 1 --set tags.status=under_review --workspace-name myworkspace --resource-group myresourcegroup

# Tag a model as approved after review
az ml model update --name customer-churn-model --version 1 --set tags.status=approved --workspace-name myworkspace --resource-group myresourcegroup

# Archive a deprecated model
az ml model archive --name customer-churn-model --version 1 --workspace-name myworkspace --resource-group myresourcegroup
```

## Model Documentation

### Model Cards

Create comprehensive model cards to document your models:

```bash
# Create a model card as a JSON file
cat > model-card.json << EOF
{
  "model_name": "customer-churn-model",
  "version": "1.0",
  "description": "Predicts customer churn probability based on usage patterns and demographics",
  "model_type": "XGBoost Classifier",
  "intended_use": "Customer retention campaigns",
  "performance_metrics": {
    "accuracy": 0.85,
    "precision": 0.82,
    "recall": 0.79,
    "f1_score": 0.80,
    "auc": 0.88
  },
  "training_data": {
    "source": "Customer database",
    "timeframe": "Jan 2022 - Dec 2022",
    "preprocessing": "Standard scaling, one-hot encoding, missing value imputation"
  },
  "evaluation_data": {
    "source": "Customer database",
    "timeframe": "Jan 2023 - Mar 2023",
    "preprocessing": "Same as training data"
  },
  "ethical_considerations": {
    "fairness_assessment": "Model tested for bias across demographic groups",
    "potential_risks": "May not perform well for new customer segments"
  },
  "limitations": [
    "Does not account for external market factors",
    "Limited to customers with at least 3 months of history"
  ],
  "maintenance": {
    "owner": "data-science-team@example.com",
    "review_schedule": "Quarterly",
    "retraining_frequency": "Bi-annually"
  }
}
EOF

# Attach the model card to the model
az ml model update --name customer-churn-model --version 1 --set tags.model_card=@model-card.json --workspace-name myworkspace --resource-group myresourcegroup
```

### Experiment Tracking

Document the experiments that led to the model:

```bash
# Get experiment details
az ml job show -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup --query "{experiment_name:experiment_name, parameters:inputs, metrics:metrics}" > experiment-details.json

# Attach experiment details to the model
az ml model update --name customer-churn-model --version 1 --set tags.experiment=@experiment-details.json --workspace-name myworkspace --resource-group myresourcegroup
```

## Audit and Compliance

### Tracking Model Lineage

```bash
# Get model lineage information
az ml model show --name customer-churn-model --version 1 --workspace-name myworkspace --resource-group myresourcegroup --query "{model:name, version:version, job:run.id, dataset:run.input_datasets}"
```

### Activity Logs

```bash
# Get activity logs for the workspace
az monitor activity-log list --resource-group myresourcegroup --resource-provider Microsoft.MachineLearningServices --resource-type workspaces --resource-name myworkspace

# Filter logs for model operations
az monitor activity-log list --resource-group myresourcegroup --resource-provider Microsoft.MachineLearningServices --resource-type workspaces --resource-name myworkspace --filter "eventName eq 'Microsoft.MachineLearningServices/workspaces/models/write'"
```

## Responsible AI Practices

### Fairness Assessment

```bash
# Install Fairlearn package
pip install fairlearn

# Run fairness assessment and save results
python -c "
import json
from fairlearn.metrics import demographic_parity_difference, equalized_odds_difference
# Run fairness assessment
fairness_metrics = {
    'demographic_parity': demographic_parity_difference(y_true, y_pred, sensitive_features=sex),
    'equalized_odds': equalized_odds_difference(y_true, y_pred, sensitive_features=sex)
}
with open('fairness-assessment.json', 'w') as f:
    json.dump(fairness_metrics, f)
"

# Attach fairness assessment to the model
az ml model update --name customer-churn-model --version 1 --set tags.fairness=@fairness-assessment.json --workspace-name myworkspace --resource-group myresourcegroup
```

### Explainability

```bash
# Install explainability packages
pip install shap interpret-community

# Generate model explanations and save results
python -c "
import json
import shap
# Generate SHAP values
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_test)
feature_importance = {feature: importance for feature, importance in zip(feature_names, shap_values.mean(axis=0))}
with open('model-explanations.json', 'w') as f:
    json.dump(feature_importance, f)
"

# Attach explanations to the model
az ml model update --name customer-churn-model --version 1 --set tags.explanations=@model-explanations.json --workspace-name myworkspace --resource-group myresourcegroup
```

## Regulatory Compliance

### GDPR Compliance

```bash
# Document GDPR compliance information
cat > gdpr-compliance.json << EOF
{
  "personal_data": {
    "contains_personal_data": true,
    "data_types": ["email", "demographics", "usage_patterns"],
    "data_minimization": "Only necessary fields are used for prediction",
    "retention_policy": "Data is deleted after model training"
  },
  "data_subject_rights": {
    "right_to_access": "Implemented through customer portal",
    "right_to_be_forgotten": "Process in place to remove customer data and retrain models"
  },
  "impact_assessment": {
    "completed_date": "2023-04-15",
    "risk_level": "medium",
    "mitigation_measures": [
      "Data encryption at rest and in transit",
      "Access controls and audit logging",
      "Regular compliance reviews"
    ]
  }
}
EOF

# Attach GDPR compliance information to the model
az ml model update --name customer-churn-model --version 1 --set tags.gdpr_compliance=@gdpr-compliance.json --workspace-name myworkspace --resource-group myresourcegroup
```

### Industry-Specific Compliance

For financial services, healthcare, or other regulated industries, document compliance with relevant regulations:

```bash
# Document industry-specific compliance
cat > industry-compliance.json << EOF
{
  "regulation": "HIPAA",
  "compliance_status": "Compliant",
  "assessment_date": "2023-05-20",
  "controls_implemented": [
    "PHI encryption",
    "Access controls and authentication",
    "Audit logging and monitoring",
    "Business associate agreements"
  ],
  "certification": {
    "certified_by": "Compliance Team",
    "certification_date": "2023-05-25",
    "expiration_date": "2024-05-25"
  }
}
EOF

# Attach industry compliance information to the model
az ml model update --name customer-churn-model --version 1 --set tags.industry_compliance=@industry-compliance.json --workspace-name myworkspace --resource-group myresourcegroup
```

## Next Steps

- Learn about [cost management](cost-management.md) for ML workloads
- Explore [security best practices](security-practices.md) for ML environments
- Implement [infrastructure as code](11.infrastructure-as-code.md) for your ML resources
