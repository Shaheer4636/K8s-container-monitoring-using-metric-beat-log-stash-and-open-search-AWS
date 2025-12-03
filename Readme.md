
# 1. Executive Summary

This project implements an **end-to-end logging and observability stack** for Kubernetes workloads using:

* **AWS OpenSearch Service** (managed search / analytics)
* **OpenSearch Dashboards** (UI)
* **Fluent Bit** (log collection from pods / nodes)
* **Logstash** (log processing and enrichment)
* **Metricbeat** (Kubernetes & node metrics)
* **Kubernetes** (application workloads)

Application logs and cluster metrics are centralized into OpenSearch, where they can be searched, visualized, and used to troubleshoot issues in near real time.

---

# 2. High-Level Architecture

**Components**

* **Demo application (`demo-api`)**

  * Simple HTTP API running in Kubernetes.
  * Writes logs to stdout (standard console logs).

* **Fluent Bit DaemonSet**

  * Runs on each Kubernetes node.
  * Tails container log files from `/var/log/containers`.
  * Sends logs to **Logstash** via the Beats protocol (port **5044**).

* **Logstash Deployment**

  * Receives logs from Fluent Bit.
  * Enriches events with Kubernetes metadata (namespace, pod, node).
  * Forwards logs to **AWS OpenSearch** in index pattern:
    `k8s-logs-YYYY.MM.DD`.

* **Metricbeat Deployment**

  * Collects Kubernetes and node metrics (pods, nodes, system).
  * Sends metrics directly to **AWS OpenSearch** in index pattern:
    `k8s-metrics-*`.

* **AWS OpenSearch Domain (`k8s-logs-demo`)**

  * Managed OpenSearch cluster on AWS.
  * Stores logs and metrics from Logstash and Metricbeat.
  * Exposed via HTTPS endpoint, protected with master username/password.

* **OpenSearch Dashboards**

  * Used to search logs, explore metrics, and build dashboards.

---

## 2.1 Data Flow

**Logs path**

1. Application container writes logs → **stdout**.
2. Kubernetes writes container logs to `/var/log/containers/...`.
3. **Fluent Bit** tail these log files and parses basic fields.
4. Fluent Bit sends events → **Logstash (Beats input on port 5044)**.
5. **Logstash**:

   * Enriches with Kubernetes metadata.
   * Sends to **OpenSearch** with index pattern `k8s-logs-YYYY.MM.DD`.
6. **OpenSearch Dashboards** is used to search/view `k8s-logs-*`.

**Metrics path**

1. **Metricbeat** runs in the cluster (Deployment).
2. Metricbeat modules collect:

   * Kubernetes pods
   * Nodes
   * Container stats
   * System metrics
3. Metricbeat sends all metrics directly to **OpenSearch**.
4. Metrics are indexed under `k8s-metrics-*` and visualized in dashboards.

---

# 3. Project Structure

You can describe the code layout like this (adapt names to your repo):

```text
k8s-aws-opensearch-logging-observability/
├── infra/
│   └── terraform/
│       ├── main.tf              # OpenSearch domain, security policy, etc.
│       ├── variables.tf
│       └── outputs.tf
└── k8s/
    ├── base/
    │   ├── namespace.yaml       # Namespace `obser`
    │   ├── secrets-opensearch.yaml (optional; or created via kubectl)
    │   └── rbac.yaml            # ServiceAccount / Roles for metricbeat, etc.
    ├── demo-app/
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── fluent-bit/
    │   ├── configmap.yaml       # fluent-bit.conf
    │   └── daemonset.yaml
    ├── logstash/
    │   ├── logstash-deployment.yaml
    │   └── logstash-pipeline-configmap.yaml
    └── metricbeat/
        ├── metricbeat-configmap.yaml
        └── metricbeat-deployment.yaml
```

---



### 4. Provision AWS OpenSearch with Terraform

From `infra/terraform`:

```bash
terraform init
terraform apply
```

Input variables (example):

* `aws_account_id = 691593026061`
* `allowed_ip_cidr = X.X.X.X/32` (or `0.0.0.0/0` for demo only)
* `master_user_name = "admin"`
* `master_user_password = "********"`


---

### 5 Configure Kubernetes Namespace & Secrets

Create namespace:

```bash
kubectl apply -f k8s/base/namespace.yaml
# namespace: obser
```

Create OpenSearch credentials secret (PowerShell example):

```powershell
kubectl create secret generic opensearch-credentials `
  -n obser `
  --from-literal=username=admin `
  --from-literal=password='YOUR_PASSWORD' `
  --from-literal=endpoint='search-k8s-logs-demo-xxxx.us-east-1.es.amazonaws.com'
```

This secret is used by **Logstash** and **Metricbeat**.

---

### 6 Deploy Demo Application

```bash
kubectl apply -n obser -f k8s/demo-app/
```

This creates:

* `Deployment demo-api`
* `Service demo-api`

You can generate some traffic with:

```bash
kubectl port-forward svc/demo-api -n obser 8080:80
# and locally:
while ($true) { curl http://localhost:8080/hello; Start-Sleep -Seconds 1 }
```

---

### 7 Deploy Fluent Bit

```bash
kubectl apply -n obser -f k8s/fluent-bit/
```

Configuration:

* Input: tail container logs from `/var/log/containers/*`.
* Output: `forward` to Logstash:

```ini
[OUTPUT]
    Name    forward
    Match   *
    Host    logstash
    Port    5044
```







If you want, next step I can:

* Turn this into a **polished README.md** with some ASCII diagrams, or
* Write a **video script** (what to click and say step-by-step while recording the demo for your client).
