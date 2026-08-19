#!/usr/bin/env bash
# ============================================================================
# render-manifests.sh - render the Kubernetes Deployment/Service/HPA/PDB
# manifests for EVERY service in stack.json (the single source of truth).
#
# Outputs one multi-document YAML on stdout - pipe it into kubectl apply:
#
#   bash kubernetes/scripts/render-manifests.sh | kubectl apply -f -
#
# This is the Kubernetes equivalent of the EC2 path, where the compute
# user-data emits docker-compose.yml from the same stack.json. Adding a service
# to stack.json automatically gets a Deployment, a Service, an HPA and a PDB -
# no manifest edits, in any pipeline.
#
# Conventions rendered for every service (mirrors the old hand-written
# manifests, which this script replaces):
#   - env contract: PORT (from stack.json) + NODE_ENV / DB_* / JWT_SECRET from
#     the shared app-config ConfigMap and the app-db-secret Secret (created at
#     deploy time from AWS Secrets Manager - never stored in Git)
#   - readiness probe on <health_path>; liveness probe on <health_path> for
#     internal services and "/" for the public one (nginx serves the SPA
#     itself, so it must NOT be restarted just because the backend is down)
#   - the single public service -> LoadBalancer (AWS NLB, internet-facing)
#     :80 -> :<port>; every other service -> ClusterIP
#   - image placeholder <project>/<svc>:latest - scripts/deploy.sh points the
#     deployments at the exact ECR image with `kubectl set image`
#
# Usage: bash kubernetes/scripts/render-manifests.sh [project] [namespace]
#   project   default: stack.json project (used for the image placeholder)
#   namespace default: secure-ntier
#
# Requires: jq on PATH (stack-info.sh reads the manifest).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFO="$REPO_ROOT/cicd/scripts/stack-info.sh"

PROJECT="${1:-$("$INFO" project)}"
NAMESPACE="${2:-secure-ntier}"

for SVC in $("$INFO" list); do
  PORT=$("$INFO" field "$SVC" port)
  PUBLIC=$("$INFO" field "$SVC" public)
  HEALTH=$("$INFO" field "$SVC" health_path)

  # jq -r prints "null" for a missing key - fall back to the platform default.
  [ "$HEALTH" = "null" ] || [ -z "$HEALTH" ] && HEALTH="/health"

  if [ "$PUBLIC" = "true" ]; then
    LIVENESS="/"
    REQ_CPU="50m";  REQ_MEM="64Mi"
    LIM_CPU="250m"; LIM_MEM="128Mi"
    SECCTX="        runAsNonRoot: true"
  else
    LIVENESS="$HEALTH"
    REQ_CPU="100m"; REQ_MEM="128Mi"
    LIM_CPU="500m"; LIM_MEM="256Mi"
    SECCTX=$'        runAsNonRoot: true\n        fsGroup: 10001'
  fi

  # --- Deployment -----------------------------------------------------------
  cat <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SVC
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $SVC
    app.kubernetes.io/part-of: $PROJECT
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $SVC
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: $SVC
    spec:
      securityContext:
$SECCTX
      containers:
        - name: $SVC
          image: $PROJECT/$SVC:latest
          ports:
            - containerPort: $PORT
          env:
            - name: PORT
              value: "$PORT"
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: app-db-secret
          readinessProbe:
            httpGet:
              path: $HEALTH
              port: $PORT
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: $LIVENESS
              port: $PORT
            initialDelaySeconds: 10
            periodSeconds: 15
          resources:
            requests:
              cpu: $REQ_CPU
              memory: $REQ_MEM
            limits:
              cpu: $LIM_CPU
              memory: $LIM_MEM
EOF

  # --- Service ---------------------------------------------------------------
  if [ "$PUBLIC" = "true" ]; then
    # Public entry point: AWS NLB on :80 -> container :<port>.
    cat <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: $SVC
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $SVC
    app.kubernetes.io/part-of: $PROJECT
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  selector:
    app: $SVC
  ports:
    - port: 80
      targetPort: $PORT
      protocol: TCP
EOF
  else
    # ClusterIP - internal only.
    cat <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: $SVC
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $SVC
    app.kubernetes.io/part-of: $PROJECT
spec:
  selector:
    app: $SVC
  ports:
    - port: $PORT
      targetPort: $PORT
      protocol: TCP
EOF
  fi

  # --- HorizontalPodAutoscaler (CPU 70%, like the EC2 scaling policy) --------
  cat <<EOF
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $SVC
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $SVC
    app.kubernetes.io/part-of: $PROJECT
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $SVC
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
EOF

  # --- PodDisruptionBudget ---------------------------------------------------
  cat <<EOF
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: $SVC
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: $SVC
    app.kubernetes.io/part-of: $PROJECT
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: $SVC
EOF
done