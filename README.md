# Example Voting App

A simple distributed application running across multiple Docker containers.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. [Docker Compose](https://docs.docker.com/compose) will be automatically installed. On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

This solution uses Python, Node.js, .NET, with Redis for messaging and Postgres for storage.

Run in this directory to build and run the app:

```shell
docker compose up
```

The `vote` app will be running at [http://localhost:8080](http://localhost:8080), and the `results` will be at [http://localhost:8081](http://localhost:8081).

Alternately, if you want to run it on a [Docker Swarm](https://docs.docker.com/engine/swarm/), first make sure you have a swarm. If you don't, run:

```shell
docker swarm init
```

Once you have your swarm, in this directory run:

```shell
docker stack deploy --compose-file docker-stack.yml vote
```

## Run the app in Kubernetes

The folder k8s-specifications contains the YAML specifications of the Voting App's services.

Run the following command to create the deployments and services. Note it will create these resources in your current namespace (`default` if you haven't changed it.)

```shell
kubectl create -f k8s-specifications/
```

The `vote` web app is then available on port 31000 on each host of the cluster, the `result` web app is available on port 31001.

To remove them, run:

```shell
kubectl delete -f k8s-specifications/
```

## Architecture

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time

## Notes

The voting application only accepts one vote per client browser. It does not register additional votes if a vote has already been submitted from a client.

This isn't an example of a properly architected perfectly designed distributed app... it's just a simple
example of the various types of pieces and languages you might see (queues, persistent data, etc), and how to
deal with them in Docker at a basic level.




CI/CD to AWS ECR + EC2 (Example Voting App)
This project ships two GitHub Actions workflows:

Workflow 1 — Build & Push to ECR (.github/workflows/build-push-ecr.yml)
Builds Docker images for vote, worker, result, tags them as latest and short commit SHA, and pushes to Amazon ECR.

Workflow 2 — Deploy to EC2 via SSM (.github/workflows/deploy-ec2.yml)
Uses AWS Systems Manager (SSM) Run Command to SSH‑less deploy: logs in to ECR on the instance, runs docker compose pull && docker compose up -d.

Repo Layout (expected)
bash
Copy code
example-voting-app/
  vote/      # Dockerfile inside
  worker/    # Dockerfile inside
  result/    # Dockerfile inside
  .github/workflows/
    build-push-ecr.yml
    deploy-ec2.yml
  infra/ (optional)
One‑time AWS Setup
ECR Repos

Create repositories: vote, worker, result (region: eu-west-2).

Example registry: 389890955868.dkr.ecr.eu-west-2.amazonaws.com.

EC2 Instance

Amazon Linux 2023, public subnet + Elastic IP.

Security Group: allow TCP 22 (SSH) from your IP, 5000 (vote UI), 5001 (result UI).

IAM Role attached:

AmazonEC2ContainerRegistryReadOnly

AmazonSSMManagedInstanceCore (required for SSM deploy)

Compose on EC2

/opt/vote/docker-compose.yml uses ECR images for vote/worker/result.

Add restart: always to services.

Optional: cron or systemd on reboot to docker compose pull && up -d.

GitHub Secrets (Repository → Settings → Secrets and variables → Actions)
Required for both workflows:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

AWS_REGION → eu-west-2

ECR_REGISTRY → 389890955868.dkr.ecr.eu-west-2.amazonaws.com

Deploy workflow also needs:

EC2_INSTANCE_ID → e.g. i-0abc123...

The IAM user associated to AWS_ACCESS_KEY_ID/SECRET needs permissions for:
ECR (push), SSM (send/get command), and STS. A simple approach is AmazonEC2ContainerRegistryPowerUser + AmazonSSMFullAccess (tighten later).

How it Works
Workflow 1 — Build & Push
Triggers: push to main or manual run.

Builds images from:

./vote → ECR_REGISTRY/vote:latest and :SHORT_SHA

./worker → .../worker:latest and :SHORT_SHA

./result → .../result:latest and :SHORT_SHA

Workflow 2 — Deploy to EC2 (via SSM)
Triggers automatically after Workflow 1 succeeds, or manual run.

Executes on the instance:

ECR docker login

cd /opt/vote

docker compose pull

docker compose up -d

docker compose ps (for visibility)

No SSH or IP allowlisting needed. ✅

Rollback
Two options:

Pull a previous SHA tag

Edit /opt/vote/docker-compose.yml on EC2 to pin images, e.g.:

arduino
Copy code
image: 389890955868.dkr.ecr.eu-west-2.amazonaws.com/result:<SHORT_SHA>
Then:

nginx
Copy code
docker compose pull && docker compose up -d
Re-run Workflow 2 after pinning back to a known-good tag.

Tip: You can also add a workflow_dispatch input to deploy a specific SHA automatically.

Common Troubleshooting
EC2 can’t pull from ECR → Check EC2 role has AmazonEC2ContainerRegistryReadOnly and ECR repos are in the same region.

SSM command fails → Ensure EC2 role has AmazonSSMManagedInstanceCore, instance is “Managed” in SSM, and EC2_INSTANCE_ID is correct.

Result UI not updating → Confirm worker envs match DB (POSTGRES_USER/PASSWORD/DB/HOST) and DB is healthy. Check docker compose logs worker/db.

Ports not reachable → Verify SG inbound rules for 5000/5001, and that the instance has a public IP/Elastic IP.

Build failing in CI → Verify folder paths. We expect Dockerfiles in ./vote, ./worker, ./result.

Manual Deploy (quick)
From EC2:

bash
Copy code
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 389890955868.dkr.ecr.eu-west-2.amazonaws.com
cd /opt/vote
docker compose pull && docker compose up -d


### Phase 1 — Local Kubernetes (Windows 11 + Docker Desktop)

**Date:** 2025-08-13 (Europe/London)

**Cluster:** 
- Track: [Minikube | kind]
- Commands:
  - minikube delete
  - minikube config set driver docker
  - minikube start --driver=docker
  - kubectl get nodes

**App Deploy:**
- `kubectl apply -f k8s-local.yaml`
- `kubectl -n voting get pods,svc,pvc`

**Access:**
- Minikube: `minikube service -n voting vote`, `minikube service -n voting result`
- kind (port-forward): 
  - `kubectl -n voting port-forward svc/vote 5000:80`
  - `kubectl -n voting port-forward svc/result 5001:80`

**Result:** 
- Vote UI at http://localhost:5000 ✅
- Result UI at http://localhost:5001 ✅

**Notes:**
- Removed `--image-mirror-country=gb` (only `cn` is valid). 
- Used official `dockersamples/*` images for vote/result/worker.

### Phase 1 — Local Kubernetes (Windows 11 + Docker Desktop + Minikube)

Outcome:
- Cluster starts OK (minikube).
- App deployed with `kubectl apply -f k8s-local.yaml`.
- Verified pods: `kubectl -n voting get pods`.
- Verified traffic in logs: `kubectl -n voting logs deploy/vote --tail=60` (votes processed).
- Accessed UIs using `minikube service` one at a time:
  - Vote URL (printed by `minikube service -n voting vote --url`) ✅
  - Result URL (printed by `minikube service -n voting result --url`) ✅

Notes:
- Concurrent browsing isn’t required for the portfolio. Minikube’s built-in service tunnel is foreground-only, so we accept sequential checks for local dev.


### Phase 2 — EKS bring-up

- Auth fixed: kubectl lists nodes (2 Ready).
- Deployed app: `kubectl apply -f k8s/eks/voting-app.yaml`.
- LoadBalancers: annotated Services with public subnets and `internet-facing` (if pending).
- Result: Two external URLs for Vote & Result, both reachable simultaneously.
- DB: Ran one-time Job to create `votes` table -> Result UI now shows counts.

**Issue:** Postgres CrashLoopBackOff — initdb refused root of EBS volume (lost+found).
**Fix:** Set PGDATA to /var/lib/postgresql/data/pgdata; keep fsGroup=999 and initContainer chown.
**Result:** DB Running, db-init Job succeeded, Result UI shows live counts.


### Phase 2 — EKS hardening (storage + DB)
- Added default StorageClass (gp3, ebs.csi.aws.com).
- Committed one-time db-init Job to create `votes` table.
- DB Deployment pinned: PGDATA subdir + fsGroup + initContainer chown.
- Worker/Result envs made explicit (Redis + Postgres).
- Result: Public vote & result URLs work; votes reflect instantly. ✅
