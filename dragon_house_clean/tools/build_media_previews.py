#!/usr/bin/env python3
"""Build preview images for an explicit Dragon House media catalog.

This tool never invents media entries and never modifies source media.
Dry-run is the default. --apply writes previews plus a NEW output catalog.

Film preview:
- ffmpeg frame extracted from the real source file.

Track preview:
- ffmpeg waveform generated from the real source file.

Books:
- existing preview metadata is preserved; no preview is fabricated from title text.

Preview generation does NOT imply runtime-playable media. Godot runtime support
continues to be decided by media_runtime.gd and actual file format/availability.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any

SAFE_ID = re.compile(r"^[A-Za-z0-9_.-]{1,96}$")


def fail(message: str) -> None:
    raise ValueError(message)


def load_catalog(path: Path) -> dict[str, Any]:
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as err:
        raise ValueError(f"invalid catalog: {err}") from err
    if not isinstance(doc, dict) or doc.get("schema") != 1:
        fail("catalog schema must be 1")
    for category in ("books", "films", "tracks"):
        items = doc.get(category, [])
        if not isinstance(items, list):
            fail(f"{category} must be an array")
        seen: set[str] = set()
        for item in items:
            if not isinstance(item, dict):
                fail(f"{category} entry must be an object")
            item_id = str(item.get("id", ""))
            title = str(item.get("title", ""))
            if not SAFE_ID.fullmatch(item_id):
                fail(f"unsafe or empty id: {item_id!r}")
            if item_id in seen:
                fail(f"duplicate {category} id: {item_id}")
            if not title:
                fail(f"missing title for {category}/{item_id}")
            seen.add(item_id)
    return doc


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def source_path(raw: str, project: Path) -> Path:
    if raw.startswith("res://"):
        return (project / raw.removeprefix("res://")).resolve()
    return Path(raw).expanduser().resolve()


def preview_value(path: Path, project: Path) -> str:
    try:
        rel = path.resolve().relative_to(project.resolve())
        return "res://" + rel.as_posix()
    except ValueError:
        return str(path.resolve())


def require_program(name: str) -> str:
    resolved = shutil.which(name)
    if not resolved:
        fail(f"required program not found: {name}")
    return resolved


def probe_duration(ffprobe: str, source: Path) -> float:
    proc = subprocess.run(
        [
            ffprobe, "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", str(source)
        ],
        capture_output=True, text=True, timeout=30, check=False,
    )
    if proc.returncode != 0:
        return 0.0
    try:
        return max(0.0, float(proc.stdout.strip()))
    except ValueError:
        return 0.0


def run_ffmpeg(args: list[str]) -> None:
    proc = subprocess.run(args, capture_output=True, text=True, timeout=180, check=False)
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout)[-3000:]
        fail("ffmpeg failed:\n" + tail)


def film_preview(ffmpeg: str, ffprobe: str, source: Path, output: Path) -> None:
    duration = probe_duration(ffprobe, source)
    seek = 1.0 if duration <= 0.0 else min(30.0, max(1.0, duration * 0.12))
    run_ffmpeg([
        ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
        "-ss", f"{seek:.3f}", "-i", str(source),
        "-frames:v", "1",
        "-vf",
        "scale=640:360:force_original_aspect_ratio=decrease,"
        "pad=640:360:(ow-iw)/2:(oh-ih)/2",
        "-q:v", "2", str(output)
    ])


def track_preview(ffmpeg: str, source: Path, output: Path) -> None:
    run_ffmpeg([
        ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(source),
        "-filter_complex",
        "aformat=channel_layouts=mono,"
        "showwavespic=s=640x360:split_channels=0",
        "-frames:v", "1", str(output)
    ])


def build(
    catalog_path: Path,
    project: Path,
    output_dir: Path,
    output_catalog: Path,
    apply: bool,
    force: bool,
    ffmpeg_name: str,
    ffprobe_name: str,
) -> dict[str, Any]:
    doc = load_catalog(catalog_path)
    output_dir = output_dir.expanduser().resolve()
    output_catalog = output_catalog.expanduser().resolve()
    project = project.expanduser().resolve()

    plan: list[dict[str, Any]] = []
    generated = 0
    skipped_no_file = 0
    preserved = 0

    for category, extension in (("films", ".jpg"), ("tracks", ".png")):
        for item in doc[category]:
            item_id = str(item["id"])
            raw_file = str(item.get("file_path", ""))
            if not raw_file:
                plan.append({
                    "category": category, "id": item_id,
                    "action": "SKIP_NO_SOURCE_FILE"
                })
                skipped_no_file += 1
                continue
            src = source_path(raw_file, project)
            if not src.is_file():
                plan.append({
                    "category": category, "id": item_id,
                    "action": "SKIP_MISSING_SOURCE", "source": str(src)
                })
                skipped_no_file += 1
                continue

            current_preview = str(item.get("preview", ""))
            if current_preview and not force:
                existing = source_path(current_preview, project)
                if existing.is_file():
                    plan.append({
                        "category": category, "id": item_id,
                        "action": "PRESERVE_EXISTING", "preview": current_preview
                    })
                    preserved += 1
                    continue

            dest = output_dir / f"{category[:-1]}_{item_id}{extension}"
            plan.append({
                "category": category,
                "id": item_id,
                "action": "GENERATE",
                "source": str(src),
                "source_sha256": sha256(src),
                "output": str(dest),
            })
            if apply:
                output_dir.mkdir(parents=True, exist_ok=True)
                if dest.exists() and not force:
                    fail(f"refuse overwrite without --force: {dest}")
                if category == "films":
                    ffmpeg = require_program(ffmpeg_name)
                    ffprobe = require_program(ffprobe_name)
                    film_preview(ffmpeg, ffprobe, src, dest)
                    item["preview_kind"] = "film_frame"
                else:
                    ffmpeg = require_program(ffmpeg_name)
                    track_preview(ffmpeg, src, dest)
                    item["preview_kind"] = "audio_waveform"
                if not dest.is_file() or dest.stat().st_size < 128:
                    fail(f"preview was not created correctly: {dest}")
                item["preview"] = preview_value(dest, project)
                item["preview_source_file_sha256"] = sha256(src)
                item["preview_sha256"] = sha256(dest)
            generated += 1

    # Never fabricate book previews. Preserve exact existing book metadata.
    for item in doc["books"]:
        plan.append({
            "category": "books",
            "id": str(item["id"]),
            "action": "PRESERVE_METADATA_ONLY"
        })

    if apply:
        if output_catalog.resolve() == catalog_path.resolve():
            fail("refuse in-place catalog rewrite; choose a separate --output-catalog")
        output_catalog.parent.mkdir(parents=True, exist_ok=True)
        output_catalog.write_text(
            json.dumps(doc, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8"
        )

    report = {
        "status": "APPLIED" if apply else "DRY_RUN",
        "catalog": str(catalog_path.resolve()),
        "project": str(project),
        "output_dir": str(output_dir),
        "output_catalog": str(output_catalog),
        "generated_planned": generated,
        "skipped_no_or_missing_source": skipped_no_file,
        "preserved_existing_preview": preserved,
        "book_preview_fabrication": False,
        "source_media_modified": False,
        "plan": plan,
    }
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--catalog", type=Path, required=True)
    ap.add_argument("--project", type=Path, default=Path("."))
    ap.add_argument("--output-dir", type=Path, required=True)
    ap.add_argument("--output-catalog", type=Path, required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--ffprobe", default="ffprobe")
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()
    try:
        result = build(
            args.catalog, args.project, args.output_dir, args.output_catalog,
            args.apply, args.force, args.ffmpeg, args.ffprobe
        )
        text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(text, encoding="utf-8")
        print(text, end="")
        return 0
    except Exception as err:
        print(f"MEDIA_PREVIEW_BUILD_FAILED: {err}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
