# homelab

Docker Compose definitions for a personal homelab, primarily targeting an Unraid host with shared storage, shared PostgreSQL services, Tailscale access, and `tsdproxy`-published apps.

## Overview

This repository is a collection of standalone Compose projects under `services/`. Each directory contains a `docker-compose.yaml` for one stack or one logical group of services.

The repo currently contains:

- standalone apps such as Mealie, Stirling PDF, Actual Budget, LibreSpeed, and pgAdmin
- multi-container stacks such as Immich, Paperless-ngx, TeslaMate, KaraKeep, and the `tower` utility stack
- network-facing helpers such as `tsdproxy`, Tailscale-enabled containers, and Nginx Proxy Manager
- GPU-enabled workloads such as Immich, Jellyfin, and Ollama

This is not a Kubernetes or Flux repository in its current form.

## Repository Layout

```text
services/
  budget/
  immich/
  jellyfin/
  karakeep/
  librespeed/
  llama/
  mealie/
  network/
  nginx-proxy-manager/
  paperless-ngx/
  pgadmin4/
  stirlingpdf/
  teslamate/
  tower/
LICENSE
README.md
```

## How To Use

Each service is managed independently.

```powershell
cd services\mealie
docker compose up -d
```

To stop a stack:

```powershell
docker compose down
```

To inspect the rendered configuration before starting:

```powershell
docker compose config
```

## Environment Assumptions

The compose files rely on environment variables that are not stored in this repository. Common examples include:

- `PATH_APPDATA_UNRAID`
- `PG_SHARED_INTERNAL_HOST`
- `PG_SHARED_USER`
- `PG_PASS`
- `IMMICH_DB_PASSWORD`
- `TAILSCALE_HOMEPAGE_URL`
- `MEILI_MASTER_KEY`
- `NEXTAUTH_SECRET`
- `PAPERLESS_API_TOKEN`
- `TESLAMATE_*`
- `MQTT_*`

Several stacks also assume host paths such as `/mnt/user/...`, Unraid-specific appdata locations, Docker socket access, or NVIDIA GPU runtime/device support.

Before starting a stack, make sure the required variables, bind mounts, databases, and host devices exist in your environment.

## Service Inventory

| Stack | Main purpose | Notes |
| --- | --- | --- |
| `budget` | Actual Budget | Single container, persisted in `${PATH_APPDATA_UNRAID}/budget`, exposed on `5006` |
| `immich` | Photo management | Includes PostgreSQL + Redis + Immich app, uses NVIDIA runtime, photo storage at `/mnt/user/immich_photos` |
| `jellyfin` | Media server | Tailscale-enabled container with GPU devices and media mounted from `/mnt/user/media` |
| `karakeep` | Bookmark/archive app | Includes Chrome remote browser and Meilisearch |
| `librespeed` | Speed test | Single container, port driven by `PORT_NETWORK_LIBRESPEED` |
| `llama` | Ollama + Open WebUI | GPU-backed Ollama plus web UI on `8081` |
| `mealie` | Recipe manager | Uses a shared PostgreSQL server |
| `network` | `tsdproxy` | Watches Docker and publishes labeled services |
| `nginx-proxy-manager` | Reverse proxy manager | Exposes `80`, `81`, and `443` |
| `paperless-ngx` | Document management | Includes Redis, Gotenberg, Tika, Paperless, and `paperless-gpt` |
| `pgadmin4` | PostgreSQL admin UI | Single container on host port `5050` |
| `stirlingpdf` | PDF tools | Single container on host port `28282` |
| `teslamate` | Tesla telemetry | Includes TeslaMate, Grafana, and ABRP bridge; depends on PostgreSQL and MQTT |
| `tower` | Misc host utilities | Includes `hass-unraid`, Duplicati, Dozzle, and two Homepage instances |

## Access Patterns

The stacks use a mix of three exposure models:

- direct host port mappings such as `8080:8080` or `5006:5006`
- `tsdproxy` labels for Tailscale-served apps
- explicit Tailscale container integration in `jellyfin`

If you add new services, keep the existing patterns consistent with the rest of the repo instead of inventing a fourth access model.

## Notable Conventions

- Many containers include Unraid metadata labels such as `net.unraid.docker.managed` and `net.unraid.docker.webui`.
- Several services persist data under `${PATH_APPDATA_UNRAID}`.
- Some services use fixed host ports, while others use variable-driven ports.
- Shared PostgreSQL credentials are reused across multiple stacks.
- GPU workloads assume NVIDIA support on the host.

## Updating Or Adding Services

When changing a stack:

1. Edit the relevant `services/<name>/docker-compose.yaml`.
2. Validate it with `docker compose config`.
3. Start or recreate only that stack.
4. Verify the expected bind mounts, ports, and environment variables on the host.

## License

This repository is licensed under the MIT License. See [LICENSE](LICENSE).
