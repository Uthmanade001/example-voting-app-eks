
# Example Voting App — AWS EKS + CI/CD

[![Build & Deploy Voting App to EKS](https://github.com/Uthmanade001/example-voting-app-eks/actions/workflows/deploy.yml/badge.svg)](https://github.com/Uthmanade001/example-voting-app-eks/actions/workflows/deploy.yml)

A production-style deployment of the classic **Example Voting App** on **Amazon EKS**, with **GitHub Actions OIDC** (no static keys), images in **ECR**, and fully automated rollout + smoke tests.

## 🚀 Live Demo
- **Vote:** http://a9f8fdd9b21184588b35a06613713592-1106780232.eu-west-2.elb.amazonaws.com  
- **Result:** http://a755e1154c1254defbd3ad2103c3b9ba-1729462898.eu-west-2.elb.amazonaws.com

> For demo only — endpoints may be cycled. Account IDs are not exposed in this README.

---

## 🧭 Highlights
- **CI/CD**: GitHub Actions → OIDC → assume role → build & push to ECR → `kubectl` rollout → smoke test.
- **Kubernetes**: Deployments, Services (LoadBalancer), gp3 PVC for Postgres, probes, requests/limits.
- **Security**: No long-lived AWS keys; least-privilege inline `eks:DescribeCluster`; cluster-admin via EKS Access Entries.
- **Scalability**: HPA on `vote` & `result` at 70% CPU (min 2, max 5).
- **Hygiene**: ECR lifecycle — keep last 10 images.

# Example Voting App — AWS EKS + CI/CD

[![Build & Deploy Voting App to EKS](https://github.com/Uthmanade001/example-voting-app-eks/actions/workflows/deploy.yml/badge.svg)](https://github.com/Uthmanade001/example-voting-app-eks/actions/workflows/deploy.yml)

A production-style deployment of the classic **Example Voting App** on **Amazon EKS**, with **GitHub Actions OIDC**, images in **ECR**, automated rollout and smoke tests.

## 🚀 Live Demo
- **Vote:** http://a9f8fdd9b21184588b35a06613713592-1106780232.eu-west-2.elb.amazonaws.com  
- **Result:** http://a755e1154c1254defbd3ad2103c3b9ba-1729462898.eu-west-2.elb.amazonaws.com

> Demo endpoints may rotate. Account IDs are not exposed in this README.

## 🧭 Highlights
- **CI/CD:** GitHub Actions → OIDC → ECR push → EKS rollout → smoke test  
- **Kubernetes:** Deployments, Services (LoadBalancer), gp3 PVC for Postgres  
- **Reliability:** Liveness/Readiness probes, resource requests/limits  
- **Scaling:** HPA (vote & result) at 70% CPU (min 2, max 5)  
- **Hygiene:** ECR lifecycle (keep last 10 images)

## ⚙️ Prerequisites
- Windows 11 + Git Bash  
- Docker Desktop, kubectl, Terraform, AWS CLI v2  
- AWS EKS cluster `eks-voting-app` (eu-west-2)  
- IAM OIDC provider for `token.actions.githubusercontent.com`  
- IAM role `github-eks-deployer` with:
  - `AmazonEC2ContainerRegistryPowerUser`
  - `AmazonEKSClusterPolicy`
  - Inline policy for `eks:DescribeCluster` (and optional `ListClusters`)
- ECR repos: `vote`, `result`, `worker`

---

## ��� CI/CD Pipeline (deploy.yml)
**Flow:** OIDC assume role → ensure ECR repos → build & push (tag = short SHA) → kubeconfig → apply manifests → set images → wait rollout → smoke test → print URLs.

**Variables (GitHub → Settings → Actions → Variables):**  
`AWS_REGION, AWS_ACCOUNT_ID, EKS_CLUSTER_NAME, AWS_ROLE_TO_ASSUME, ECR_REPO_VOTE, ECR_REPO_RESULT, ECR_REPO_WORKER`

**Triggers:** `push` to `main` and `workflow_dispatch`.

## 🛠️ Operations Cheatsheet
```bash
# Public endpoints
kubectl -n voting get svc vote   -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
kubectl -n voting get svc result -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo

# Current images (12-char SHA tags)
kubectl -n voting get deploy vote   -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl -n voting get deploy result -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl -n voting get deploy worker -o jsonpath='{.spec.template.spec.containers[0].image}'; echo

