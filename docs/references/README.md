# Reference handling

This directory stores metadata, citations, retrieval instructions, and integrity
information. It does not store third-party manuals, ROMs, or source snapshots
unless redistribution permission is independently established.

## Manifest format

`manifest.yaml` is written in JSON syntax, which is a valid YAML 1.2 subset.
That choice lets the reference tools use only Python's standard library in a
clean checkout. Each source record includes:

- identity and bibliographic metadata;
- a stable, direct source URL;
- retrieval date and ignored local filename;
- SHA-256 for acquired content;
- content type;
- license/redistribution assessment and commit permission;
- project relevance and authority level;
- notes and exact pages/sections used.

`status` is one of:

- `cataloged`: metadata exists but a local copy has not been integrity-pinned;
- `acquired`: the ignored local copy was downloaded and its SHA-256 recorded;
- `unavailable`: lawful retrieval was attempted but is currently unavailable;
- `metadata_only`: the source is intentionally not downloaded by automation.

An empty `sha256` is permitted only for non-acquired records. Acquiring a
source is a meaningful research change: record its checksum and retrieval date
in the manifest with a normal reviewed commit.

## Safe acquisition

```sh
python3 scripts/fetch_references.py
python3 scripts/verify_reference_hashes.py
```

The fetcher:

- uses direct HTTPS URLs from the manifest;
- downloads only records explicitly marked `download.enabled`;
- validates final content type against the per-record allowlist;
- writes to a temporary file and atomically installs a successful download;
- computes SHA-256 and checks pinned hashes;
- reuses a valid cached file;
- reports unavailable sources while continuing with the remaining records.

Select records with repeated `--id SOURCE_ID`. Use `--list` to inspect the
catalog. The script never executes a downloaded file.

Downloads go under the repository-root `reference-cache/`, which is ignored by
Git. Do not move them into tracked directories. The checksum verifier returns a
failure for a missing or mismatched acquired source; use `--allow-missing` only
for metadata checks on clean CI clones where reference downloads are
intentionally absent.

## Copyright policy

Access does not imply permission to redistribute. Historical TI and Atari
manuals in this catalog are marked `may_commit: false` unless a specific
license says otherwise. MAME source is open source, but snapshots remain in the
ignored cache to maintain a strong clean-room boundary; this project records
the upstream license and exact commit instead of vendoring it.

Short, necessary quotations may be used with precise citations. Prefer concise
paraphrase. Never add game ROMs or execute a legacy development binary.

## Adding a source

1. Prefer the most authoritative lawful source and a stable direct URL.
2. Add every required manifest field with honest `unknown` values where
   necessary.
3. Run `python3 scripts/fetch_references.py --id SOURCE_ID`.
4. Independently compute the hash (for example with `sha256sum`) and patch the
   manifest to `status: acquired`.
5. Run `python3 scripts/verify_reference_hashes.py`.
6. Record used sections as architectural research proceeds.

Do not overwrite an existing hash merely because upstream content changed.
Treat a hash change as a new revision or a provenance incident.
