# spoke-books

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E21U3S1R)

Spoke module for book-related media services:

- [Audiobookshelf](https://www.audiobookshelf.org/) — self-hosted audiobook and podcast server
- [Calibre](https://calibre-ebook.com/) — ebook library manager with web GUI ([LinuxServer image](https://docs.linuxserver.io/images/docker-calibre/))
- [GraphicAudio Scraper](https://github.com/binyaminyblatt/graphicaudio_scraper) — custom ABS metadata provider for GraphicAudio titles (local PHP build)

## Services

| Service          | Description                        | Port  | Network | Auth     |
|------------------|------------------------------------|-------|---------|----------|
| audiobookshelf   | Audiobooks & podcasts media server | 80    | troxy   | Optional |
| calibre          | Ebook library manager (desktop GUI)| 8080  | troxy   | Authentik required |
| graphicaudio     | GraphicAudio ABS metadata scraper  | 80    | troxy   | Internal only (no Traefik route) |

> **Security**: Calibre provides full desktop access with passwordless sudo in its terminal. It must be protected by Authentik forward auth and should never be exposed without it.
>
> **GraphicAudio scraper** is internal-only — no external route. Register it in ABS under Settings → Custom Metadata Providers using the troxy IP: `http://<GRAPHICAUDIO_IP>/audiobookshelf/search?query={query}`

## Prerequisites

- Spoke hub deployed with `troxy` network
- Traefik available as a hub service
- Authentik configured (`chain-authentik-no-crowdsec` middleware) for Calibre

## Quick Start

```bash
cp .env.example .env
# Edit .env — set IPs and media paths for your system
docker compose up -d
```

## Module Environment Variables

| Variable               | Default                                   | Description                        |
|------------------------|-------------------------------------------|------------------------------------|
| `AUDIOBOOKSHELF_IMAGE` | `ghcr.io/advplyr/audiobookshelf:2.33.2`   | Audiobookshelf container image     |
| `AUDIOBOOKSHELF_IP`    | `192.168.35.89`                           | Static IP on troxy network         |
| `AUDIOBOOKSHELF_PORT`  | `13378`                                   | Host port                          |
| `CALIBRE_IMAGE`        | `lscr.io/linuxserver/calibre:9.7.0`       | Calibre container image            |
| `CALIBRE_IP`           | `192.168.35.90`                           | Static IP on troxy network         |
| `CALIBRE_PORT`         | `8080`                                    | Host port                          |
| `MEDIA_DIR`            | `/mnt/media`                              | Base media directory               |
| `AUDIOBOOKS_DIR`       | `${MEDIA_DIR}/books`                      | Shared library: audiobooks + ebooks; mounted as `/books/` in both ABS (`:rw`) and Calibre (`:rw`) |
| `PODCASTS_DIR`         | `${MEDIA_DIR}/podcasts`                   | Podcasts library path              |
| `GRAPHICAUDIO_IMAGE`   | `spoke-books/graphicaudio:latest`         | GraphicAudio scraper image (local build)   |
| `GRAPHICAUDIO_IP`      | `192.168.35.91`                           | Static IP on troxy network                 |
| `GRAPHICAUDIO_PORT`    | `8093`                                    | Host port                                  |
| `GRAPHICAUDIO_REFRESH_KEY` | `changeme`                            | Secret key to protect the `/refresh` endpoint |
| `GRAPHICAUDIO_ABS_KEY` | `abs`                                     | ABS API key for cover art (leave `abs` if ABS auth is off) |

## Traefik Routing

| Route                      | Middleware                    | Service        |
|----------------------------|-------------------------------|----------------|
| `books.${DOMAIN}`          | chain-media                   | audiobookshelf |
| `calibre.${DOMAIN}`        | chain-authentik-no-crowdsec   | calibre        |

## Calibre Setup Notes

**On first launch**, Calibre's setup wizard asks for a library location. Set it to `/config/Calibre Library` (the default) — this keeps `metadata.db` and Calibre's internal structure in the appdata volume, not in the shared `/books/` directory.

**Adding books**: Use _Add books_ → _Add books from directories, including subdirectories_ → browse to `/books/` → **uncheck "Copy books to library folder"**. Calibre will index the files in-place without creating author/title directories inside `/books/`.

The Calibre content server (port 8081) is disabled by default. If you wish to enable it, do so via Calibre Preferences → Sharing over the net, and add a port mapping via `docker-compose.override.yml`.

## GraphicAudio Scraper Notes

The scraper is a custom PHP build that fetches `results.json` from the upstream GitHub repo — no Node.js or local scraping needed.

**ABS registration** (Settings → Custom Metadata Providers):
- Name: `GraphicAudio`
- URL: `http://<GRAPHICAUDIO_IP>/audiobookshelf/search?query={query}`

**Cache refresh** (POST to protected endpoint):
```bash
curl -X POST http://<GRAPHICAUDIO_IP>/refresh -H "X-Refresh-Key: <GRAPHICAUDIO_REFRESH_KEY>"
```

**Build**: Image is built locally from `dockerfiles/graphicaudio/Dockerfile` on first deploy (`docker compose up -d --build`).

## References

- [Audiobookshelf Docs](https://www.audiobookshelf.org/docs)
- [Calibre LinuxServer Docs](https://docs.linuxserver.io/images/docker-calibre/)
- [Calibre](https://calibre-ebook.com/)
- [GraphicAudio Scraper](https://github.com/binyaminyblatt/graphicaudio_scraper)
