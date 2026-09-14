# ketch cache ↔ fixtures + cross-platform capture tool matrix

Research ticket: [#15](https://github.com/kido5217/opencode-recursive-research/issues/15) (part of map [#14](https://github.com/kido5217/opencode-recursive-research/issues/14)).

Scope: (1) what the `ketch` 0.16.2 page cache stores, where it lives, how long it lasts, and how a skill that persists "fixtures" should relate to it — on both the MCP and CLI paths; (2) for each fixture kind (webpage markdown, raw HTML, search-result set, PDF/office document, audio, video, git repo), which tools exist and exactly what they yield, including pointer-only fallbacks.

Every claim is either **(a)** observed by running the tool on this host, **(b)** read from the `ketch` v0.16.2 source at tag `v0.16.2` (commit `0b3eb34f3a598c4696cb1c3320466877e277f756`), or **(c)** read from a tool's own `--help`/version on this host. Unverified items are flagged.

## Environment

| Fact | Value |
|---|---|
| `ketch` | `0.16.2`, `/nix/store/jl9qgq37p1xyy0ayh84hhv8hz94x2d7b-ketch-0.16.2/bin/ketch` (symlinked from `/etc/profiles/per-user/kido/bin/ketch`) |
| ketch config | `/home/kido/.config/ketch/config.json` (`backend: exa`, `cache_ttl: 72h`, `browser: chromium`) |
| ketch cache | `/home/kido/.cache/ketch/cache.db` — `BoltDB database`, 55.9 MB at time of research |
| Other cache file | `/home/kido/.cache/ketch/update-check.json` (update-check state, not page cache) |
| Config env override | `KETCH_CONFIG` (alternate config path); cache path follows `os.UserCacheDir()` |
| MCP server | `ketch mcp serve` (PID 397689 at research time, child of `opencode`) held the cache lock |
| Host tools present | `git` 2.54.0, `git-lfs` 3.7.1, `curl` 8.21.0, `wget` 1.25.0, `yt-dlp` 2026.08.19, `ffmpeg` 8.1.2, `jq`, `file`, `python3` |
| Host tools absent | `pandoc`, `pdftotext`, `tesseract`, `unzip`, `libreoffice`, `soffice`, `antiword`, `catdoc`, `xlsx2csv`, `docx2txt` |

---

# Part 1 — ketch cache ↔ fixtures

## 1.1 What the cache stores

The cache is a single embedded **bbolt** database (`go.etcd.io/bbolt`) with one bucket named `pages`. Each value is a JSON `cacheEntry` ([`cache/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/cache.go)):

```json
{
  "t": 1789060041,                 // CachedAt, unix seconds
  "s": "http",                     // fetch source: "http" | "http_shell" | "browser" (omitempty)
  "p": {                           // scrape.Page — the extracted representation
    "url": "...",                  // requested URL
    "fetched_url": "...",          // rewritten/redirected URL (omitempty)
    "title": "...",
    "markdown": "...",
    "etag": "...",                 // omitempty
    "last_modified": "...",        // omitempty
    "content_hash": "..."          // omitempty
  },
  "r": "<raw HTML>"                // RawHTML (omitempty; written ONLY by the --raw path)
}
```

Source: [`cache/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/cache.go) `type cacheEntry`, `Put`/`Get`/`PutRaw`/`GetRaw`; [`scrape/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/scrape.go) `type Page` and the `Source*` constants.

Observed entry (via `strings ~/.cache/ketch/cache.db`), matching the shape above:

```json
{"t":1789060041,"s":"http","p":{"url":"https://bevy.org/faq","title":"Bevy FAQ","markdown":""}}
```

Key points:

- The cache stores the **extracted `Page`** (markdown/title/metadata), not the original response bytes. PDFs are stored as their extracted markdown only.
- `RawHTML` is persisted **only** when a request used `--raw`/`raw=true`. A markdown-only entry deliberately omits it, and a raw request against a markdown-only entry refetches and back-fills `RawHTML` while keeping the cached `Page` (`CachedScrapeRaw` in [`scrape/pipeline.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/pipeline.go)). This keeps the common markdown path from paying the 20 MiB body cost.
- Because `RawHTML` is capped by the same 20 MiB `MaxBodyBytes` as the fetch, the cache is **not** a faithful byte archive even in raw mode.

## 1.2 Where it lives

`cache.DBPath()` = `os.UserCacheDir()/ketch/cache.db`, created with directory mode `0700` and file mode `0600` ([`cache/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/cache.go) `DBPath`, `ensurePrivateDir`; [`cache/bbolt.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/bbolt.go) `tightenDBPermissions`).

`os.UserCacheDir()` is platform-dependent ([Go `os` docs](https://pkg.go.dev/os#UserCacheDir)):

| OS | Cache root |
|---|---|
| Linux/Unix | `$XDG_CACHE_HOME`, else `$HOME/.cache` |
| macOS | `$HOME/Library/Caches` |
| Windows | `%LocalAppData%` |
| Plan 9 | `$home/lib/cache` |

So: **Linux** `~/.cache/ketch/cache.db`; **macOS** `~/Library/Caches/ketch/cache.db`; **Windows** `%LocalAppData%\ketch\cache.db`. `XDG_CACHE_HOME` (Linux) relocates it. There is **no** `KETCH_*` variable for the cache path (config is `KETCH_CONFIG`; cache is not configurable).

The config file itself uses `os.UserConfigDir()` ([`config/config.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/config/config.go) `Path`): Linux `$XDG_CONFIG_HOME`/`~/.config`, macOS `~/Library/Application Support`, Windows `%AppData%` ([Go docs](https://pkg.go.dev/os#UserConfigDir)).

## 1.3 How long, and eviction

- TTL is the config key `cache_ttl`, default `"72h"` ([`internal/configbase/config.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/internal/configbase/config.go) `Defaults()`). On this host it is explicitly `72h`.
- Expiry is **logical**, checked on read as `time.Since(CachedAt) > ttl` ([`cache/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/cache.go) `Get`/`GetRaw`). A parse failure of `cache_ttl` falls back to **1 hour** (`NewFromConfig`).
- There is **no eviction, pruning, compaction, or size cap**. Expired entries remain on disk until `ketch cache clear` (which deletes and recreates the bucket) or manual deletion ([`cache/bbolt.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/bbolt.go) `Clear`; [`cmd/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/cache.go)). The DB therefore grows unbounded (55.9 MB on this host).
- There is no sliding refresh: a hit does not extend `CachedAt`.
- Cache keys are `hex(sha256(url)[:8])` (16 hex chars) over the **rewritten** fetch URL, namespaced further by `\x00cookies:<jar fingerprint>` when a cookie jar is configured and `\x00ua:<hash>` when a User-Agent is explicitly configured ([`scrape/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/scrape.go) `CacheKey`; `cache/cache.go` `cacheKey`). One page can therefore have several cache keys.

## 1.4 Which surfaces read/write the cache (MCP + CLI)

| Surface | Cache behavior | Bypass |
|---|---|---|
| CLI `ketch scrape` | read/write | `--no-cache` |
| CLI `ketch scrape --select` | **always bypasses** the cache ([`scrape/pipeline.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/pipeline.go) `ScrapeSelector` comment) | n/a |
| CLI `ketch scrape --force-browser` | read/write, but reuses only **browser-sourced** entries | `--no-cache` |
| CLI `ketch search --scrape` | read/write, **always on** | **no `--no-cache` flag** (observed: `Error: unknown flag: --no-cache`) |
| CLI `ketch crawl` | read/write | `--no-cache` |
| CLI `ketch extract` | never fetches, never caches, never renders ([`cmd/extract.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/extract.go) / `ketch extract --help`) | n/a |
| MCP `scrape` tool | read/write | `no_cache: true` ([`mcp/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/scrape.go) `ScrapeInput.NoCache`) |
| MCP `crawl` tool | read/write | `no_cache: true` ([`mcp/crawl.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/crawl.go) `CrawlInput.NoCache`) |
| MCP `search` tool with `scrape: true` | read/write, **always on** | **no `no_cache` field** ([`mcp/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/search.go) `SearchInput`; `scrapeSearchResults` calls `CachedScrape(ctx, s.pageCache(false), …)`) |

The MCP server builds **one** cache handle at startup and shares it for the server's lifetime (`NewServer` → `cache.NewFromConfig(cfg)`; `Close` releases it) ([`mcp/server.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/server.go)). CLI `search --scrape` likewise hardcodes `newPageCache(false)`.

## 1.5 The single-writer lock — and why CLI caching is off while MCP runs

bbolt takes an exclusive file lock; `openBBolt` opens with a **1-second timeout** ([`cache/bbolt.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/bbolt.go)). `cache.New` returns **nil** on any open failure, and a nil `*Cache` is a silent no-op — so a locked cache means the command runs **uncached with no warning**.

Observed on this host:

```console
$ lsof ~/.cache/ketch/cache.db
COMMAND    PID USER FD   TYPE ... NAME
ketch   397689 kido 4u   REG ... /home/kido/.cache/ketch/cache.db
$ ps -o pid,ppid,args -p 397689
397689  397575 ketch mcp serve          # parent 397575 = opencode

$ ketch cache --json
{"path":"/home/kido/.cache/ketch/cache.db","entries":null,"size_bytes":58667008,
 "size":"55.9 MB","ttl":"72h","locked":true}

$ time ketch scrape --json "https://example.com/?probe=$(date +%s)" >/dev/null
real 0m1.552s          # ~1s lock wait + fetch; cache.db mtime unchanged
$ time ketch scrape --no-cache --json "https://example.com/?nc=$(date +%s)" >/dev/null
real 0m0.600s          # no open attempt → no lock wait
```

Consequences for the skill:

- Inside opencode, `ketch mcp serve` normally owns the cache lock for the whole session. **CLI `ketch` then runs uncached and pays ~1s per invocation** unless `--no-cache` is passed. The CLI and MCP do **not** share a live cache in that state.
- `ketch cache` / `ketch doctor` also can't read entry counts while the MCP server holds the lock; they fall back to file size ([`cmd/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/cache.go) `runCacheStats`; `ketch doctor` reported `cache bbolt ok ... locked by another process`).
- Conversely, if a CLI process holds the lock when `ketch mcp serve` starts, the MCP server comes up with caching disabled for its lifetime.

## 1.6 How the fixture design should relate to the cache

1. **Fixture ≠ cache.** The cache is a transient, 72h, URL-keyed, single-process-locked optimization that stores extracted text (and optionally capped raw HTML) — never original bytes. A fixture is durable evidence; persist it explicitly under `memory/research/<slug>/fixtures/` and index it in `fixtures/registry.json`.
2. **Avoid double-fetch.** Capture at scrape time from the single fetch that produced the content: `ketch scrape --json` yields markdown; `ketch scrape --raw --json` yields markdown **and** `raw_html` **and** `source` in one fetch. For search-result sets, `ketch search --json` (or MCP `search`) is the artifact. If you already hold HTML bytes (e.g. via `curl`), run `curl … | ketch extract` to get markdown with **no** fetch, cache, or browser.
3. **Survive cache eviction.** Never re-read a fixture from the cache: TTL is 72h, there is no pruning guarantee, and `ketch cache clear` wipes everything. Record `captured_at` and `sha256` in the registry — the cache can supply neither.
4. **Honour `--no-cache` for freshness.** Use CLI `--no-cache` (scrape/crawl) or MCP `no_cache: true` (scrape/crawl). The **search** scrape path has no bypass on either surface — for a freshness-critical fixture, scrape the URL directly with `no_cache` rather than relying on `search --scrape`.
5. **Don't assume the cache is warm across surfaces.** Because of the lock, a fixture captured through MCP and then re-scraped through the CLI (or vice versa) may refetch. This is fine — fixtures are the durable layer; the cache is best-effort.
6. **Record the effective URL.** Cache keys use the rewritten fetch URL and one page may map to several keys; the registry should store both `url` and any `fetched_url`.
7. **Privacy.** The cache DB can hold authenticated page content and is protected `0700`/`0600`; the README warns to use `--no-cache` if content must not be stored. Fixtures inherit the same sensitivity — `PRIVACY.md` should say so.

---

# Part 2 — Capture tool matrix

Each row: the fixture kind, the primary tool/command, the exact yield, and the pointer-only / absent-tool fallback. Output shapes were observed on this host unless cited to source.

## 2.1 Summary matrix

| Fixture kind | Primary tool / command | Exact yield | Fallback (incl. pointer-only) |
|---|---|---|---|
| Webpage markdown | `ketch scrape <url>`; `ketch scrape --json <url>`; MCP `scrape` | plain: YAML frontmatter `url`/`title`/`words` + markdown body; JSON: `{url, fetched_url?, title, markdown}`; MCP: `{results:[{url, title, markdown, …}]}` | built-in web fetch; or `curl -L <url> \| ketch extract` (no fetch/cache/browser) |
| Raw HTML | `ketch scrape --raw <url>`; `--raw --json`; MCP `scrape` `raw:true` | bare HTML; JSON `{url, fetched_url?, title, source, raw_html}`; `source` ∈ `http`/`http_shell`/`browser`. Raw bypasses the `/llms.txt` probe; PDFs are rejected | `curl -L <url>` / `wget -O` (unlimited bytes, no extraction) |
| Search-result set | `ketch search <q> --json`; `--multi` / `--random`; MCP `search` | JSON array `[{title, url, description, content?, backends?}]`; plain frontmatter `query`/`backend`/`result_count`; MCP `{results, backend?, errors?}` | built-in web search; pointer-only if none |
| PDF | `ketch scrape <url>` (built-in pure-Go parser) | extracted markdown text; scanned/image-only → `ErrPDFNoText`, exit **5** with an OCR-converter hint; `--raw`/`--select` reject PDFs, exit **2** | raw bytes via `curl`/`wget`; `pdftotext`/`pandoc` (absent here); pointer-only if no converter |
| Office document (docx/xlsx/pptx) | **none in ketch** (only HTML/PDF are special-cased) | n/a | `pandoc`/`libreoffice`/`unzip` (absent); `python3` stdlib `zipfile` can unzip + read XML (docx/xlsx are zip+XML); pointer-only otherwise |
| Audio | `yt-dlp -x --audio-format <fmt> <url>`; direct `curl`/`wget`; `ffmpeg` to transcode | audio file (`-x` extracts audio); metadata via `yt-dlp --write-info-json` (`.info.json`) or `-j/--dump-json` | pointer-only: URL + metadata (title/uploader/duration) |
| Video | `yt-dlp -f <fmt> <url>`; `--merge-output-format`; `--write-subs`; `--write-thumbnail`; direct `curl`/`wget`; `ffmpeg` remux/transcode | video container (yt-dlp merges best video+audio); optional subs/thumbnail/metadata | pointer-only: URL + metadata |
| Git repo | `git clone <url>` (full; charter says **no** `--depth 1`) | working tree + `.git`; `git clone --mirror`/`--bare` for full refs; `--recurse-submodules` for submodules | pointer-only: remote URL + `git rev-parse HEAD` commit SHA, no clone |

## 2.2 ketch output shapes (observed)

```console
$ ketch scrape https://example.com
---
url: https://example.com
title: Example Domain
words: 17
---
This domain is for use in documentation examples without needing permission. …

$ ketch scrape --json https://example.com
{"url":"https://example.com","title":"Example Domain","markdown":"…"}

$ ketch scrape --raw --json https://example.com
{"url":"https://example.com","title":"Example Domain","source":"http","raw_html":"<!doctype html>…"}

$ ketch search "nixos" -l 2
---
query: nixos
backend: exa
result_count: 2
---
Nix & NixOS | Declarative builds and deployments
  https://nixos.org/
  …

$ ketch crawl --json --depth 1 https://example.com
{"url":"https://example.com","title":"Example Domain","words":17,"status":"new","source":"seed","body":"…"}
```

Notes:

- `ketch search --json` emits a bare array; the MCP `search` tool wraps it as `{results, backend?, errors?}` ([`mcp/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/search.go)).
- `search.Result` is `{title, url, fetched_url?, description?, content?, backends?}` ([`search/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/search/search.go)). The configured backend (`exa` here) populated `content` even **without** `--scrape`; treat `content` as backend-dependent.
- `ketch crawl --json` streams per-page objects using `body` (not `markdown`) plus `status`/`source`, followed by a summary block.
- Exit-code taxonomy (README "Why it works well for agents"): `2` bad input, `3` not found, `4` upstream/network, `5` missing precondition, `6` cancelled. Confirmed `2` for `--raw` on a PDF.

## 2.3 PDFs and documents

- ketch detects PDFs by MIME type or `%PDF-` magic and extracts text with a **built-in pure-Go parser** (`github.com/ledongthuc/pdf`) ([`extract/pdf.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/extract/pdf.go); README "PDF extraction"). Observed: a text-layer PDF returned `{"markdown":"Dummy PDF file"}`; `--raw` returned `Error: raw output is not supported for PDF documents` (exit 2).
- A valid PDF with no text layer returns `ErrPDFNoText` → CLI exit 5 with a hint to configure `external_pdf_to_md_converter_command` ([`extract/pdf.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/extract/pdf.go); [`mcp/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/scrape.go) `classifyScrapeFailure`). OCR is **not** built in.
- An operator can set `external_pdf_to_md_converter_command` (shlex-parsed, exactly one `{input}` placeholder; stdout capped at 10 MiB; timeout `external_pdf_to_md_converter_timeout_sec`, default 300s). When set it is **authoritative** — failures are returned, not silently falling back ([`extract/pdf_external.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/extract/pdf_external.go); README). Example in README: `ketch config set external_pdf_to_md_converter_command 'pdftotext "{input}" -'` — but `pdftotext` is **absent on this host**.
- **Office formats are not supported by ketch.** Only `text/html`/`application/xhtml+xml` and `application/pdf` get dedicated handling; any other content type is passed through the HTML extractor, which yields nothing useful for OOXML/OLE binaries ([`scrape/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/scrape.go) `effectiveContentType`, `isHTMLContentType`). Converters on this host: `pandoc` ✗, `pdftotext` ✗, `tesseract` ✗, `unzip` ✗, `libreoffice`/`soffice` ✗, `antiword`/`catdoc`/`xlsx2csv`/`docx2txt` ✗. `python3` **is** present, and its stdlib `zipfile` module can open docx/xlsx/pptx (they are ZIP + XML) — a partial, dependency-free fallback. Otherwise: capture the raw bytes with `curl`/`wget` and mark `status: pointer-only`.

## 2.4 Media (audio/video)

- `yt-dlp` (present, `2026.08.19`) is the primary capture path for streaming sites. Relevant flags from `yt-dlp --help` on this host:
  - `-x, --extract-audio` + `--audio-format FORMAT` → audio-only file.
  - `-f, --format FORMAT` and `--merge-output-format FORMAT` → video, with audio/video merged into the chosen container.
  - `--write-info-json` → sidecar `<id>.info.json` metadata; `-j, --dump-json` → metadata to stdout (no download).
  - `--write-subs`, `--write-thumbnail`, `--cookies FILE`, `--no-playlist`.
- For direct media URLs, `curl -L` / `wget` capture bytes. `ffmpeg` 8.1.2 can transcode/remux/extract (`ffmpeg -i in -vn -acodec … out`).
- If neither tool is available, fall back to `status: pointer-only` with URL + metadata (title, uploader, duration).

## 2.5 Git repositories

- `git clone <url>` produces a full working tree plus `.git`; the map's charter mandates **full clones (no `--depth 1`)**. `git clone --mirror` (implies `--bare`) captures all refs; `--recurse-submodules` fetches submodules (`git clone -h` on this host).
- `git-lfs` 3.7.1 is present, but a clone of an LFS repo leaves **pointer files** until `git lfs pull` (or `git lfs install` + checkout) materializes the objects. Record whether LFS objects were fetched.
- Pointer-only fallback: store the remote URL + the commit SHA (`git rev-parse HEAD`) without cloning, when cloning is too heavy or git is absent.

## 2.6 Cross-platform notes

- ketch ships for linux/darwin/windows on amd64/arm64 (README "Install"). Cache/config paths differ per OS (§1.2).
- The capture ladder should probe with `command -v` and degrade to pointer-only, because converter availability is host-specific: this NixOS host lacks `pandoc`, `pdftotext`, `tesseract`, and `unzip`, but other hosts commonly have them.
- `ketch extract` is the portable no-fetch bridge: `curl -L <url> | ketch extract` turns captured HTML into markdown on any host with ketch, without a browser or network fetch.

---

## Sources

**ketch (primary)**

- Tag `v0.16.2` source, commit `0b3eb34f3a598c4696cb1c3320466877e277f756`:
  - [`cache/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/cache.go), [`cache/bbolt.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cache/bbolt.go), [`cmd/cache.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/cache.go)
  - [`scrape/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/scrape.go), [`scrape/pipeline.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/scrape/pipeline.go), [`cmd/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/scrape.go)
  - [`cmd/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/cmd/search.go), [`search/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/search/search.go)
  - [`mcp/server.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/server.go), [`mcp/scrape.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/scrape.go), [`mcp/search.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/search.go), [`mcp/crawl.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/mcp/crawl.go)
  - [`config/config.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/config/config.go), [`internal/configbase/config.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/internal/configbase/config.go)
  - [`extract/pdf.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/extract/pdf.go), [`extract/pdf_external.go`](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/extract/pdf_external.go)
  - [`README.md` (v0.16.2)](https://github.com/1broseidon/ketch/blob/0b3eb34f3a598c4696cb1c3320466877e277f756/README.md)
- `ketch` CLI on this host: `--help` for `ketch`, `scrape`, `search`, `crawl`, `cache`, `extract`, `mcp`, `doctor`, `config`, `code`, `docs`; observed runs of `cache --json`, `scrape`, `scrape --json`, `scrape --raw`, `scrape --raw --json`, `search`, `search --json`, `crawl --json`, and PDF scrape.

**Other tools (primary, this host)**

- `git --version` 2.54.0, `git clone -h`, `git lfs help`, `git-lfs` 3.7.1
- `yt-dlp --version` 2026.08.19 and `yt-dlp --help`
- `ffmpeg -version` 8.1.2
- `curl --version` 8.21.0, `wget --version` 1.25.0
- Go standard library: [`os.UserCacheDir`](https://pkg.go.dev/os#UserCacheDir), [`os.UserConfigDir`](https://pkg.go.dev/os#UserConfigDir)
- `go.etcd.io/bbolt` (embedded key/value store used by ketch's cache)

## Uncertainties / not verified

- `git clone -h` on this host did not surface `--depth` in the grep window (help output is long); `--depth`/full-vs-shallow behavior is asserted from standard git semantics, not observed here. The charter already forbids `--depth 1` regardless.
- The `exa` backend returning `content` without `--scrape` was observed once; whether other backends do the same was not tested.
- Converter availability (`pandoc`, `pdftotext`, `tesseract`, `unzip`, LibreOffice) was verified only on this NixOS host.
- Only one `ketch mcp serve` process was observed. Whether multiple opencode sessions each spawn their own server and contend for the lock (rather than sharing one) was not tested.
- The exact bbolt on-disk key/value framing (key immediately followed by value) is inferred from `strings` output plus source; entry counts could not be read directly because the MCP server held the lock.
