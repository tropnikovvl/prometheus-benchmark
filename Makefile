include services/Makefile

# k8s namespace for installing the chart
# It can be overriden via NAMESPACE environment variable
NAMESPACE ?= vm-benchmark

# the deployment prefix
CHART_NAME := my-bench

# print resulting manifests to console without applying them
debug:
	helm install --dry-run --debug $(CHART_NAME) -n $(NAMESPACE) chart/

# install the chart to configured namespace
install:
	helm upgrade -i $(CHART_NAME) -n $(NAMESPACE) --create-namespace chart/

# delete the chart from configured namespace
delete:
	helm uninstall $(CHART_NAME) -n $(NAMESPACE)

monitor:
	kubectl -n $(NAMESPACE) port-forward deployment/$(CHART_NAME)-prometheus-benchmark-vmsingle 8428

re-install: delete install

install-deps:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add vm https://victoriametrics.github.io/helm-charts/
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade -i prom-crd prometheus-community/prometheus-operator-crds -n prom-crd --create-namespace
	helm upgrade -i vm-stack vm/victoria-metrics-k8s-stack -f deployments/vm-stack.yaml -n vm-stack --create-namespace
	helm upgrade -i vms vm/victoria-metrics-single -f deployments/vm.yaml -n vm --create-namespace
	helm upgrade -i mimir grafana/mimir-distributed -f deployments/mimir.yaml -n mimir --create-namespace
	helm upgrade -i prom prometheus-community/prometheus -f deployments/prom.yaml -n prom --create-namespace

delete-deps:
	helm delete prom -n prom
	helm delete mimir -n mimir
	helm delete vms -n vm
	helm delete vm-stack -n vm-stack
	helm delete prom-crd -n prom-crd
