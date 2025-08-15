cat > README.md <<'MD'
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

---

## 🏗️ Architecture (Mermaid)
```mermaid
flowchart LR
  subgraph GitHub Actions
    A[Checkout] --> B[OIDC → Assume Role]
    B --> C[Build 3 images]
    C --> D[Push to ECR]
    D --> E[aws eks update-kubeconfig]
    E --> F[kubectl apply + set image]
    F --> G[Smoke test Job]
  end

  subgraph AWS
    ECR[(ECR: vote/result/worker)]
    EKS[(EKS: eks-voting-app)]
    ELB1[(ELB: /vote)]
    ELB2[(ELB: /result)]
  end

  C --> ECR
  F --> EKS
  EKS --> ELB1
  EKS --> ELB2



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
