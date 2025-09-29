helm package kubeflow
rm docs/*
mv kubeflow-flux* docs
helm repo index docs --url https://icc-guerrero.github.io/kubeflow-bootstrap
