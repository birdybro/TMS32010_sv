#!/usr/bin/env python3
"""Shared, standard-library-only reference manifest helpers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any, Iterable

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = REPOSITORY_ROOT / "docs" / "references" / "manifest.yaml"
DEFAULT_CACHE = REPOSITORY_ROOT / "reference-cache"

REQUIRED_FIELDS = {
    "id",
    "title",
    "author_or_organization",
    "publication_number",
    "publication_date",
    "revision",
    "source_url",
    "retrieval_date",
    "local_filename",
    "sha256",
    "document_type",
    "media_type",
    "license_or_redistribution_status",
    "relevance",
    "authority_level",
    "notes",
    "may_commit",
    "sections_or_pages_used",
    "status",
    "download",
}
VALID_STATUSES = {"cataloged", "acquired", "unavailable", "metadata_only"}


class ManifestError(ValueError):
    """The committed reference manifest violates its schema or safety policy."""


def load_manifest(path: Path = DEFAULT_MANIFEST) -> dict[str, Any]:
    """Load the JSON-syntax YAML manifest and validate its safety invariants."""
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"cannot load {path}: {error}") from error

    if data.get("schema_version") != 1:
        raise ManifestError("unsupported or missing manifest schema_version")
    sources = data.get("sources")
    if not isinstance(sources, list):
        raise ManifestError("manifest sources must be a list")

    seen_ids: set[str] = set()
    seen_filenames: set[str] = set()
    for index, source in enumerate(sources):
        if not isinstance(source, dict):
            raise ManifestError(f"source {index} is not an object")
        missing = REQUIRED_FIELDS - source.keys()
        if missing:
            raise ManifestError(
                f"source {index} is missing fields: {', '.join(sorted(missing))}"
            )

        source_id = source["id"]
        if not isinstance(source_id, str) or not source_id:
            raise ManifestError(f"source {index} has invalid id")
        if source_id in seen_ids:
            raise ManifestError(f"duplicate source id: {source_id}")
        seen_ids.add(source_id)

        relative = Path(source["local_filename"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ManifestError(f"{source_id}: unsafe local_filename")
        normalized = relative.as_posix()
        if normalized in seen_filenames:
            raise ManifestError(f"duplicate local_filename: {normalized}")
        seen_filenames.add(normalized)

        status = source["status"]
        if status not in VALID_STATUSES:
            raise ManifestError(f"{source_id}: invalid status {status!r}")
        digest = source["sha256"]
        if digest is not None and (
            not isinstance(digest, str)
            or len(digest) != 64
            or any(character not in "0123456789abcdef" for character in digest)
        ):
            raise ManifestError(f"{source_id}: invalid lowercase SHA-256")
        if status == "acquired" and digest is None:
            raise ManifestError(f"{source_id}: acquired source has no SHA-256")

        if not isinstance(source["authority_level"], int) or not (
            1 <= source["authority_level"] <= 8
        ):
            raise ManifestError(f"{source_id}: authority_level must be 1..8")
        if not isinstance(source["may_commit"], bool):
            raise ManifestError(f"{source_id}: may_commit must be boolean")
        if not isinstance(source["sections_or_pages_used"], list):
            raise ManifestError(
                f"{source_id}: sections_or_pages_used must be a list"
            )

        download = source["download"]
        if not isinstance(download, dict) or set(download) != {
            "enabled",
            "expected_content_types",
        }:
            raise ManifestError(f"{source_id}: invalid download policy")
        if not isinstance(download["enabled"], bool):
            raise ManifestError(f"{source_id}: download.enabled must be boolean")
        content_types = download["expected_content_types"]
        if not isinstance(content_types, list) or not content_types:
            raise ManifestError(
                f"{source_id}: expected_content_types must be nonempty"
            )
        if not source["source_url"].startswith("https://"):
            raise ManifestError(f"{source_id}: only direct HTTPS URLs are allowed")

    return data


def select_sources(
    manifest: dict[str, Any], selected_ids: Iterable[str]
) -> list[dict[str, Any]]:
    """Return enabled sources, checking that every requested ID exists."""
    requested = list(selected_ids)
    sources = manifest["sources"]
    if not requested:
        return [source for source in sources if source["download"]["enabled"]]

    by_id = {source["id"]: source for source in sources}
    unknown = sorted(set(requested) - by_id.keys())
    if unknown:
        raise ManifestError(f"unknown source IDs: {', '.join(unknown)}")
    return [by_id[source_id] for source_id in requested]


def cache_path(source: dict[str, Any], cache_root: Path = DEFAULT_CACHE) -> Path:
    """Resolve a validated manifest filename below the selected cache root."""
    relative = Path(source["local_filename"])
    candidate = (cache_root / relative).resolve()
    root = cache_root.resolve()
    if candidate != root and root not in candidate.parents:
        raise ManifestError(f"{source['id']}: cache path escapes cache root")
    return candidate


def sha256_file(path: Path) -> str:
    """Hash a file without loading the entire reference into memory."""
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()
