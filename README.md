# homelab

A personal homelab configuration repository containing Kubernetes manifests (k3s + Flux), infrastructure configuration, and a collection of local service docker-compose projects.

## Table of Contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
  - Prerequisites
  - Inspect manifests
  - [Deploy with Flux (bootstrap GitHub)](#deploy-with-flux-bootstrap-github)
  - Run local services
- [Secrets and sensitive data](#secrets-and-sensitive-data)
- [Useful paths](#useful-paths)
- [Development & contributing](#development--contributing)
- [License & contact](#license--contact)

## Overview

This repository captures the infrastructure-as-code and service manifests used to run a small personal homelab. It is intentionally organized so you can:

- Manage Kubernetes manifests and Kustomize overlays under `clusters/`.
- Keep small standalone services using Docker Compose under `services/`.
- Store helper scripts (for example `update-secrets.sh`) and shared infra configs.

The repo is designed for reproducibility and easy inspection; sensitive values are expected to be sealed or kept out of source control.

## Repository layout

Top-level layout (relevant folders in this repo):

- `clusters/` — Kubernetes configuration, kustomize overlays and Flux (GitOps) manifests.
  - `k3s/` — manifests and overlays targeted for a k3s cluster.
    - `apps/` — per-application kustomize overlays (example apps: `mealie`, `teslamate`, `vaultwarden`, etc.).
    - `infrastructure/` — cluster-level controllers, storage, and shared configs.
    - `flux-system/` — Flux (gotk) components and sync configuration for GitOps.
- `services/` — small local services (each folder usually contains a `docker-compose.yaml`). Examples: `immich`, `llama`, `teslamate`, `tower`, `network`.
- `update-secrets.sh` — convenience script used to update or re-seal secrets (read it before running).

Note: The exact subfolders and files are in the repository — inspect them before performing destructive actions.

## Quick start

This quick start gives a high-level workflow to inspect and deploy parts of the repository. It assumes you already have the repository checked out locally.

### Prerequisites

- Git (repo is already present locally in this workspace)
- kubectl — to apply manifests to a Kubernetes cluster
- kustomize or kubectl with Kustomize support (`kubectl apply -k`)
- flux CLI (optional) if you want to bootstrap or interact with Flux GitOps
- k3s or another Kubernetes distribution where you will apply the manifests
- docker & docker-compose (or Docker Desktop) for running local services
- kubeseal (if you work with sealed secrets) and/or sops (if you use SOPS-encrypted secrets)

### Inspect manifests

View cluster manifests and overlays:

```bash
# List top-level k3s folders
ls clusters/k3s

# Inspect an app overlay (example)
ls clusters/k3s/apps/mealie

# Show the kustomization used at the root of the k3s overlay
sed -n '1,200p' clusters/k3s/kustomization.yaml
```

## Deploy with Flux (bootstrap GitHub)

This repository is structured to be used with Flux (GitOps). The recommended way to install Flux and connect it to this Git repository is to use the `flux bootstrap github` command which will install the Flux controllers in-cluster and create the required GitHub workflow/links to sync the repository path where your cluster overlays live (for example `clusters/k3s`).

Before running the bootstrap command:

- Install the `flux` CLI on your machine: https://fluxcd.io/docs/installation/
- Create a GitHub personal access token with repository permissions (at minimum `repo`) and any additional required scopes for workflow setup. Keep this token secret.
- Decide which Git branch and repository path you want Flux to sync from (this repo uses `clusters/k3s` for the k3s overlay).

Example commands (replace placeholders before running):

POSIX (bash/powershell for humans):

```bash
export GITHUB_TOKEN=ghp_your_token_here
flux bootstrap github \
  --owner=GITHUB_USER \
  --repository=homelab \
  --branch=main \
  --path=clusters/k3s \
  --personal
```

Windows (cmd.exe):

```bat
set GITHUB_TOKEN=ghp_your_token_here && flux bootstrap github --owner=GITHUB_USER --repository=homelab --branch=main --path=clusters/k3s --personal
```

Notes:

- Replace `GITHUB_USER`, `homelab`, `main`, and the token with values appropriate for your GitHub account/repo.
- If the repository is under an organization, omit `--personal` and ensure the token has the correct permissions.
- The bootstrap command will create the necessary Flux components and add a GitHub workflow (if applicable) so the cluster stays in sync with the Git repository path.

Important: do NOT apply the entire `clusters/k3s` overlay with a single `kubectl apply -k`.

The repository contains multiple overlays, controllers, CRDs and cross-resource dependencies that must be created in a specific order (Flux, CRDs, controllers, storage, then apps). Attempting to apply the whole `clusters/k3s` overlay at once can cause transient failures or broken resources. Instead, test changes locally by applying individual overlays or manifests for the specific component you are working on.

Examples — testing a single app (Mealie)

POSIX (bash / PowerShell Core):

```bash
# preview the changes that would be applied
kubectl diff -k clusters/k3s/apps/mealie

# apply just the Mealie overlay to the current context
kubectl apply -k clusters/k3s/apps/mealie

# wait for the Mealie deployment to become ready (replace with actual deployment name if different)
kubectl -n mealie rollout status deployment/mealie
```

Windows (cmd.exe):

```bat
kubectl diff -k clusters/k3s/apps/mealie
kubectl apply -k clusters/k3s/apps/mealie
kubectl -n mealie rollout status deployment/mealie
```

Alternate approaches:

- Use `kustomize build clusters/k3s/apps/mealie | kubectl apply -f -` to inspect generated YAML before applying.
- Apply individual manifest files within an app overlay, e.g. `kubectl -n mealie apply -f clusters/k3s/apps/mealie/deployment.yaml`.
- If you're using Flux, prefer committing changes to the Git repository (or using `flux reconcile kustomization`) so the cluster follows the GitOps flow; for local testing you can still apply single overlays as shown above.

### Run local services

Several services are provided as Docker Compose projects under `services/`. Many of these are placed in `services/` intentionally because they are designed to run as standalone containers on a local host (for example an Unraid server) where you can expose hardware resources (GPU, large local storage) that a k3s cluster may not have or where you prefer to keep certain workloads outside the cluster.

Why some services live in `services/`

- Local hardware access: services like `llama` (LLM runners) or `jellyfin` (media server) can use host GPUs and direct-attached storage more easily when run as host containers.
- Resource isolation: running resource-heavy workloads directly on a host keeps them from competing with cluster workloads.
- Simpler local development: quick iteration (build/run) with Docker Compose without creating Kubernetes objects.

Running GPU-enabled services on Unraid (high level)

1. Confirm the host can see the GPU and the container runtime is configured:

```bash
# check the GPU on the host
nvidia-smi

# check Docker can use GPUs (host)
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

```bash
cd services/immich
# start the compose stack (Docker Compose v2 plugin)
docker compose up -d
```

## Secrets and sensitive data

This repo includes examples of sealed secrets and references to shared secret overlays (for example under `clusters/k3s/infrastructure/configs/shared-secrets/`). Do not commit plain-text secrets. Recommended approaches:

- Use `kubeseal` + Sealed Secrets to store encrypted secrets in Git.
- Use SOPS (with a key manager such as GPG, AWS KMS, or another supported backend) for encrypted files.
- Keep any unsealed or plaintext credentials outside the repository and inject them during CI or cluster bootstrapping.

There is an `update-secrets.sh` helper script — read it before running and ensure you have the right tooling (kubeseal, sops, environment keys).

## Useful paths

- `clusters/k3s/kustomization.yaml` — root overlay for k3s
- `clusters/k3s/flux-system` — Flux components and synchronization config
- `clusters/k3s/apps/` — application overlays (each app typically has `deployment.yaml`, `namespace.yaml`, `pvc.yaml`, `kustomization.yaml`)
- `clusters/k3s/infrastructure/configs/shared-secrets/` — sealed/shared secret examples
- `services/` — docker-compose-based services