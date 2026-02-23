helm package kubeflow
rm docs/index.yaml
rm docs/kubeflow-flux*
mv kubeflow-flux* docs
helm repo index docs --url https://icc-guerrero.github.io/kubeflow-bootstrap
