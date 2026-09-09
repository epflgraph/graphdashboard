<img src="assets/icon-e6221781.png" alt="Project logo" height="64">

[![License](https://img.shields.io/github/license/epflgraph/graphdashboard)](https://github.com/epflgraph/graphdashboard/blob/master/LICENSE)
[![Latest Release on Github](https://img.shields.io/github/v/release/epflgraph/graphdashboard?sort=semver)](https://github.com/epflgraph/graphdashboard/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/epflgraph/graphdashboard?style=social)](https://github.com/epflgraph/graphdashboard/stargazers)
[![Contributors](https://img.shields.io/github/contributors/epflgraph/graphdashboard)](https://github.com/epflgraph/graphdashboard/graphs/contributors)
[![Last Commit](https://img.shields.io/github/last-commit/epflgraph/graphdashboard)](https://github.com/epflgraph/graphdashboard/commits/master)
[![Open Issues](https://img.shields.io/github/issues/epflgraph/graphdashboard)](https://github.com/epflgraph/graphdashboard/issues)
[![Open PRs](https://img.shields.io/github/issues-pr/epflgraph/graphdashboard)](https://github.com/epflgraph/graphdashboard/pulls)

Why Graph?
==========
The *Graph Data Platform* - developed by the AI engineering team at the [EPFL Center for Digital Education](https://www.epfl.ch/education/educational-initiatives/cede/) - is an open-source alternative to proprietary research information systems like Elsevier Pure. It federates educational and institutional data into a semantically interconnected knowledge graph of people, publications, labs, startups, courses, video lectures, and other educational resources. The [GraphSearch](https://graphsearch.epfl.ch/en) application provides lightning-fast search and discovery of the knowledge graph, as well as LLM-powered [chatbot](https://graphsearch.epfl.ch/en/chatbot) interaction with the indexed resources.

**List of Graph services:**<br/>
[Registry](https://github.com/epflgraph/graphregistry) |
[AI](https://github.com/epflgraph/graphai) |
[Ontology](https://github.com/epflgraph/graphontology) |
[Search](https://github.com/epflgraph/graphsearch_ui) |
[Chat](https://github.com/epflgraph/graphchatbot) |
Dash |
[DB client](https://github.com/epflgraph/graphdb-client) |
[ES client](https://github.com/epflgraph/graphes-client) |
[SDK](https://github.com/epflgraph/graph-sdk) |
[Agents](https://github.com/epflgraph/graphagents)

Graph Dash
==========
*Graph Dash* (Graph Dashboard) is the monitoring and observability layer of the Graph Data Platform. It aggregates service links, metrics, logs, and secrets management behind a single nginx reverse proxy with SSL termination.

What it provides
----------------
- **Dashy** — a configurable landing page with live status checks for all platform services.
- **Grafana** — dashboards and visualization for Prometheus metrics.
- **Prometheus** — scraping of platform exporters and time-series storage.
- **Loki** — log aggregation for the stack.
- **Infisical** — central secrets manager, backed by PostgreSQL and Redis.
- **nginx** — reverse proxy routing HTTPS traffic to each component.

Tech stack
----------
| Component | Technology |
| --- | --- |
| Orchestration | Docker Compose |
| Dashboard | Dashy (`lissy93/dashy`) |
| Metrics / visualization | Grafana + Prometheus |
| Logs | Grafana Loki 3.3.2 |
| Secrets manager | Infisical |
| Secrets backend | PostgreSQL 16 + Redis 7 |
| Reverse proxy | nginx 1.27 with Let's Encrypt SSL |
| Helper scripts | Python 3, Bash |

Compose services
----------------
| Service | Image | Purpose |
| --- | --- | --- |
| `loki` | `grafana/loki:3.3.2` | Log aggregation |
| `prometheus` | `prom/prometheus:latest` | Metrics scraper and TSDB |
| `grafana` | `grafana/grafana:latest` | Metrics visualization |
| `postgres` | `postgres:16` | Infisical database |
| `redis` | `redis:7` | Infisical cache/backend |
| `infisical` | `infisical/infisical:latest` | Secrets manager UI/API |
| `dashy` | `lissy93/dashy:latest` | Service dashboard |
| `reverse-proxy` | `nginx:1.27` | SSL terminator and router |

Public endpoints
----------------
All HTTPS endpoints are served from `graphdash.graphcert.cede-apps.ch`:

| Port | Service | Upstream |
| --- | --- | --- |
| `8444` | Dashy | `http://dashy:8080/` |
| `9444` | Grafana | `http://grafana:3000` |
| `9445` | Prometheus | `http://prometheus:9090` |
| `9446` | Infisical | `http://infisical:8080` (with websocket upgrade) |
| `80` | Loki | `http://loki:3100/loki/` under `/loki/` |

Key configuration files
-----------------------
- `docker-compose.yml` — stack definition.
- `prometheus.yml` — Prometheus scrape configuration.
- `loki-config.yaml` — Loki server and storage configuration.
- `nginx.graphdash-https.conf` — nginx upstream and SSL configuration.
- `config/dashy/config.yml` — Dashy sections, items, auth users, and icons.
- `config/grafana/provisioning/` — Grafana data sources and dashboard providers.
- `config/grafana/dashboards/` — JSON dashboard definitions.
- `scripts/infisical/` — backup, login, and secret-management helpers.
- `infisical.yml` — required secrets per environment.

Environment files
-----------------
The following files contain environment variables and credentials and are **not** committed to the repository:

- `.env` — Compose environment variables.
- `.infisical.env` — Infisical CLI credentials.

Quick start
-----------
Start the stack:

```bash
cd ~/dev/graphdashboard
docker compose up -d
```

Restart a service:

```bash
docker compose restart <service>
```

View logs:

```bash
docker compose logs -f <service>
```

Reload nginx after config changes:

```bash
docker compose exec reverse-proxy nginx -s reload
```

Validate the Prometheus configuration:

```bash
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

Prometheus targets
------------------
Prometheus scrapes the following external targets on `10.92.36.18` every 15 seconds:

| Job | Target | Purpose |
| --- | --- | --- |
| `celery` | `:9808` | Celery metrics exporter |
| `rabbitmq` | `:15672` | RabbitMQ management / exporter |
| `docker` | `:9417` | Docker Compose/container stats exporter |
| `gpu` | `:9400` | NVIDIA GPU metrics exporter |

Troubleshooting
---------------
1. Check container health: `docker compose ps`.
2. Inspect logs for the failing service: `docker compose logs --tail 100 <service>`.
3. Verify `.env` variables are exported before running Compose.
4. Verify bind-mount permissions (most services run as `${HOST_UID}:${HOST_GID}`; Loki runs as root).
5. Verify nginx config syntax before reloading.
6. Verify Prometheus targets are reachable from the Prometheus container.
7. Verify Dashy status-check URLs are reachable from the browser.
8. For Infisical issues, verify PostgreSQL and Redis are healthy first.
