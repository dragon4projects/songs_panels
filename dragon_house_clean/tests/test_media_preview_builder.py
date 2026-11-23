#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
TOOL=ROOT/"tools/build_media_previews.py"
FILM=ROOT/"tests/fixtures/test_video.ogv"
TRACK=ROOT/"tests/fixtures/test_chime.wav"
PRODUCTION=ROOT/"data/media_catalog.json"

def digest(p:Path)->str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def run(*args:str):
    return subprocess.run(
        ["python3",str(TOOL),*map(str,args)],
        cwd=ROOT,capture_output=True,text=True
    )

assert FILM.is_file() and TRACK.is_file()
assert shutil.which("ffmpeg") and shutil.which("ffprobe")
prod_before=PRODUCTION.read_bytes()
film_sha=digest(FILM)
track_sha=digest(TRACK)

with tempfile.TemporaryDirectory(prefix="dragon-media-preview-") as td:
    work=Path(td)
    catalog=work/"catalog.json"
    outdir=work/"previews"
    enriched=work/"catalog.with_previews.json"
    report=work/"report.json"
    doc={
        "schema":1,
        "books":[{
            "id":"BOOK_META_ONLY_001",
            "title":"Metadata-only QA book",
            "physical":False,
            "preview":""
        }],
        "films":[{
            "id":"FILM_REAL_001",
            "title":"Real QA source film",
            "file_path":"res://tests/fixtures/test_video.ogv",
            "source":"generated QA fixture"
        }],
        "tracks":[{
            "id":"TRACK_REAL_001",
            "title":"Real QA source track",
            "file_path":"res://tests/fixtures/test_chime.wav",
            "source":"generated QA fixture"
        }]
    }
    catalog.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

    # Default is dry-run: no catalog or previews may be created.
    result=run(
        "--catalog",catalog,
        "--project",ROOT,
        "--output-dir",outdir,
        "--output-catalog",enriched,
        "--report",report
    )
    assert result.returncode==0,result.stderr
    dry=json.loads(report.read_text(encoding="utf-8"))
    assert dry["status"]=="DRY_RUN"
    assert dry["generated_planned"]==2
    assert dry["book_preview_fabrication"] is False
    assert dry["source_media_modified"] is False
    assert not outdir.exists()
    assert not enriched.exists()

    # Apply generates previews only from the actual source files.
    result=run(
        "--catalog",catalog,
        "--project",ROOT,
        "--output-dir",outdir,
        "--output-catalog",enriched,
        "--apply",
        "--report",report
    )
    assert result.returncode==0,result.stderr
    applied=json.loads(report.read_text(encoding="utf-8"))
    assert applied["status"]=="APPLIED"
    film_preview=outdir/"film_FILM_REAL_001.jpg"
    track_preview=outdir/"track_TRACK_REAL_001.png"
    assert film_preview.is_file() and film_preview.stat().st_size>128
    assert track_preview.is_file() and track_preview.stat().st_size>128
    assert film_preview.read_bytes()[:2]==b"\xff\xd8"
    assert track_preview.read_bytes()[:8]==b"\x89PNG\r\n\x1a\n"

    updated=json.loads(enriched.read_text(encoding="utf-8"))
    assert updated["films"][0]["preview_kind"]=="film_frame"
    assert updated["tracks"][0]["preview_kind"]=="audio_waveform"
    assert updated["books"][0].get("preview","")==""  # never fabricated
    assert updated["films"][0]["preview_source_file_sha256"]==film_sha
    assert updated["tracks"][0]["preview_source_file_sha256"]==track_sha
    assert updated["films"][0]["preview_sha256"]==digest(film_preview)
    assert updated["tracks"][0]["preview_sha256"]==digest(track_preview)

    # Existing generated outputs are not silently overwritten.
    result=run(
        "--catalog",catalog,
        "--project",ROOT,
        "--output-dir",outdir,
        "--output-catalog",work/"second.json",
        "--apply"
    )
    assert result.returncode==2
    assert "refuse overwrite" in result.stderr

    # In-place catalog rewrite is explicitly forbidden.
    result=run(
        "--catalog",catalog,
        "--project",ROOT,
        "--output-dir",work/"other",
        "--output-catalog",catalog,
        "--apply",
        "--force"
    )
    assert result.returncode==2
    assert "in-place catalog rewrite" in result.stderr

assert digest(FILM)==film_sha
assert digest(TRACK)==track_sha
assert PRODUCTION.read_bytes()==prod_before
production=json.loads(prod_before)
assert production=={"schema":1,"books":[],"films":[],"tracks":[]}

print("MEDIA_PREVIEW_BUILDER_V016_PASS dry_run=no_write film=real_frame track=real_waveform books=no_fabrication production_catalog=unchanged")
