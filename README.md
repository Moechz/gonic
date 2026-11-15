# gonic-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Gonic](https://github.com/sentriz/gonic).

## What this is

A four-file TOS Docker application archive (`gonicdocker.tar.gz`) that installs
Gonic on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `gonicdocker`)
- `gonicdocker.lang` — 23-language superset (TOS requires 14)
- `gonicdocker.svg` — application icon (274 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `sentriz/gonic:v0.23.0`

## How it works

| | |
|---|---|
| Container image | `sentriz/gonic:v0.23.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8154/` (container port 4747) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/data` → `/Volume1/DockerAppData/gonicdocker/data`, `/music` → `/Volume1/DockerAppData/gonicdocker/music`, `/cache` → `/Volume1/DockerAppData/gonicdocker/cache`, `/playlists` → `/Volume1/DockerAppData/gonicdocker/playlists` |
| Logs | `docker logs gonicdocker` (stdout/stderr) |

`/data` keeps `gonic.db` and podcasts; `/cache` keeps transcodes and cover art; `/playlists` keeps M3U playlists; `/music` (mounted from `.../music`) is the read-only library.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: creates the podcast/playlist folders and starts gonic on port 4747 with explicit `-music-path`, `-playlists-path`, `-cache-path` and `-db-path` arguments.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 4747.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Port moved to 4747.** The image defaults to port 80, which uid 1000 cannot bind; the wrapper passes `-listen-addr`.
- **Folders prepared up front.** Gonic refuses to start when the podcast folder is missing, so the wrapper creates it.

## Privacy

This application runs entirely on your NAS. It does not include analytics, telemetry or advertising SDKs, and the packaging contains no code that sends data to the packager. Data is only exchanged with the services you configure yourself (for example media servers, notification endpoints or model APIs), and only from the container. Everything the application stores lives in the application data folder described above; removing the app with its data deletes it.

## Third-party components

The package runs the upstream image `sentriz/gonic:v0.23.0` unmodified. Its components and their licences are those of the upstream project (https://github.com/sentriz/gonic), which is distributed under **GPL-3.0**. No upstream source code is redistributed in this repository; only the four packaging files are original work.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/gonicdocker/data` | Gonic application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/gonicdocker/music` | Gonic application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/gonicdocker/cache` | Gonic application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/gonicdocker/playlists` | Gonic application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/gonicdocker.tar.gz + .sha256
scripts/build.sh 0.23.0-2   # packaging iteration bump
scripts/build.sh 0.23.0-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/gonicdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v0.23.0-1`**, assets `gonicdocker.tar.gz` +
   `gonicdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `gonicdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `0.23.0-1` → automated validation → review.

## License / branding

Gonic is distributed by its upstream authors under **GPL-3.0**. The container image is the official image from Docker Hub (`sentriz/gonic:v0.23.0`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- Clients must speak the Subsonic API; there is no official mobile app.
- Scanning large libraries takes a while on first start.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
