#!/usr/bin/env python3
"""Deterministic, non-promoting intake for immutable TEEA006/007 candidate drops.

This script ONLY writes candidate/evidence namespaces. It never overwrites
production room art or activates content. Promotion is a separate Integrator +
Dragon approval step.
"""
from __future__ import annotations
import argparse, hashlib, json, os, re, tempfile, zipfile
from pathlib import Path, PurePosixPath

EXPECTED_ARCHIVES = {
    "TEEA006": "7ca98ad9039ba36ca76f1e29f6e82489c1098c35d5243f639724d092546694bc",
    "TEEA007": "05f734b2af745a062a4942653834e38149b10301c9bb035b4682ae7004a78cbb",
    "TEEA007_CLOSURE": "abc63bc791fb5bd90e08dcc57bf9447df68385373675fec2ecd4a928f562292b",
}
EXPECTED_COUNTS = {
    "teea006_room_png": 48,
    "teea006_metadata": 7,
    "teea007_room_png": 13,
    "teea007_glb": 9,
    "teea007_metadata": 11,
    "closure": 5,
}

TEEA006_META = {
    "dragon_house_clean/data/asset_proposals/TEEA_INT_20261123_006_interiors.json",
    "dragon_house_clean/data/asset_proposals/TEEA_INT_20261123_006_furniture_anchors_candidate.json",
    "dragon_house_clean/data/asset_proposals/TEEA_INT_20261123_006_foreground_layers_candidate.json",
    "dragon_house_clean/docs/art_review/TEEA_INT_20261123_006_INTEGRATOR_HANDOFF.md",
    "dragon_house_clean/docs/art_review/TEEA_INT_20261123_006_SHA256SUMS.txt",
    "dragon_house_clean/docs/art_review/TEEA_INT_20261123_006_collision_spacing_report.json",
    "dragon_house_clean/docs/art_review/TEEA_INT_20261123_006_depth_readability_report.json",
}
TEEA007_META = {
    "metadata/TEEA_INT_20261123_007_common_function_addendum.json",
    "metadata/TEEA_INT_20261123_007_functional_dressing_status.json",
    "metadata/TEEA_INT_20261123_007_guest_rooms.json",
    "metadata/TEEA_INT_20261123_007_guest_station_candidate.json",
    "metadata/TEEA_INT_20261123_007_library_function_addendum.json",
    "metadata/TEEA_INT_20261123_007_media_binding_006_final.json",
    "metadata/TEEA_INT_20261123_007_media_hooks.json",
    "metadata/fur_rest_mat_manifest.json",
    "metadata/media_holder_manifest.json",
    "metadata/mug_manifest.json",
    "metadata/mug_tabletop_access.json",
}
CLOSURE_META = {
    "SHA256SUMS_GUEST_ALPHA_CLOSURE.txt",
    "TEEA_INT_20261123_007_GUEST_ALPHA_CLOSURE.json",
    "TEEA_INT_20261123_007_GUEST_ALPHA_CLOSURE.md",
    "TEEA_INT_20261123_007_guest_actual_alpha.json",
    "TEEA_INT_20261123_007_guest_actual_sprite_projection.json",
}

R006 = re.compile(
    r"^dragon_house_clean/assets/rooms/"
    r"(music|cinema|artifact|workshop)/R[123]/"
    r"(backdrop|back_decor|furniture_back|foreground)\.png$"
)
R007_ROOM = re.compile(
    r"^assets/rooms/(common/R2|guest_centaur/R1|guest_vampire/R1|guest_miu/R1)/"
    r"(backdrop|back_decor|furniture_back|foreground)\.png$"
)
R007_GLB = re.compile(r"^assets/props/[^/]+\.glb$")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_member(name: str) -> bool:
    p = PurePosixPath(name)
    return bool(name) and not name.startswith("/") and ".." not in p.parts and "\\" not in name


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        existing = path.read_bytes()
        if existing == data:
            return
        raise RuntimeError(f"Refusing to overwrite non-identical candidate file: {path}")
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def record(batch: str, member: str, target_rel: str, future_rel: str | None,
           role: str, data: bytes) -> dict:
    return {
        "batch": batch,
        "source_member": member,
        "candidate_path": target_rel,
        "future_runtime_path": future_rel,
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "role": role,
        "owner_approved": False,
    }


def intake_006(zpath: Path, project: Path, manifest: list[dict], counts: dict) -> None:
    with zipfile.ZipFile(zpath) as z:
        for member in sorted(z.namelist()):
            if not safe_member(member):
                raise RuntimeError(f"Unsafe ZIP member in TEEA006: {member!r}")
            if R006.fullmatch(member):
                rel = member.removeprefix("dragon_house_clean/assets/rooms/")
                target_rel = f"assets/candidates/teea006/rooms/{rel}"
                future_rel = f"assets/rooms/{rel}"
                data = z.read(member)
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA006", member, target_rel, future_rel,
                                       "room_layer_candidate", data))
                counts["teea006_room_png"] += 1
            elif member in TEEA006_META:
                data = z.read(member)
                target_rel = "data/asset_proposals/TEEA_INT_20261123_006_FINAL/" + PurePosixPath(member).name
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA006", member, target_rel, None,
                                       "candidate_metadata", data))
                counts["teea006_metadata"] += 1


def intake_007(zpath: Path, project: Path, manifest: list[dict], counts: dict) -> None:
    prefix = "dragon_house_teea007_drop_FINAL/"
    with zipfile.ZipFile(zpath) as z:
        for member in sorted(z.namelist()):
            if not safe_member(member):
                raise RuntimeError(f"Unsafe ZIP member in TEEA007: {member!r}")
            rel = member.removeprefix(prefix) if member.startswith(prefix) else member
            if R007_ROOM.fullmatch(rel):
                room_rel = rel.removeprefix("assets/rooms/")
                target_rel = f"assets/candidates/teea007/rooms/{room_rel}"
                future_rel = f"assets/rooms/{room_rel}"
                data = z.read(member)
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA007", member, target_rel, future_rel,
                                       "room_layer_candidate", data))
                counts["teea007_room_png"] += 1
            elif R007_GLB.fullmatch(rel):
                prop_rel = rel.removeprefix("assets/props/")
                target_rel = f"assets/candidates/teea007/props/{prop_rel}"
                future_rel = f"assets/props/{prop_rel}"
                data = z.read(member)
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA007", member, target_rel, future_rel,
                                       "runtime_mesh_candidate", data))
                counts["teea007_glb"] += 1
            elif rel in TEEA007_META:
                data = z.read(member)
                target_rel = "data/asset_proposals/TEEA_INT_20261123_007_FINAL/" + PurePosixPath(rel).name
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA007", member, target_rel, None,
                                       "candidate_metadata", data))
                counts["teea007_metadata"] += 1


def intake_closure(zpath: Path, project: Path, manifest: list[dict], counts: dict) -> None:
    with zipfile.ZipFile(zpath) as z:
        for member in sorted(z.namelist()):
            if not safe_member(member):
                raise RuntimeError(f"Unsafe ZIP member in TEEA007 closure: {member!r}")
            if member in CLOSURE_META:
                data = z.read(member)
                target_rel = "docs/handoffs/TEEA_INT_20261123_007_FINAL_CLOSURE/" + PurePosixPath(member).name
                atomic_write(project / target_rel, data)
                manifest.append(record("TEEA007_CLOSURE", member, target_rel, None,
                                       "evidence_only", data))
                counts["closure"] += 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True, type=Path)
    ap.add_argument("--teea006", required=True, type=Path)
    ap.add_argument("--teea007", required=True, type=Path)
    ap.add_argument("--teea007-closure", required=True, type=Path)
    args = ap.parse_args()
    project = args.project.resolve()

    archives = {
        "TEEA006": args.teea006.resolve(),
        "TEEA007": args.teea007.resolve(),
        "TEEA007_CLOSURE": args.teea007_closure.resolve(),
    }
    for key, path in archives.items():
        actual = sha256_file(path)
        expected = EXPECTED_ARCHIVES[key]
        if actual != expected:
            raise RuntimeError(f"{key} archive SHA mismatch: {actual} != {expected}")

    manifest: list[dict] = []
    counts = {k: 0 for k in EXPECTED_COUNTS}
    intake_006(archives["TEEA006"], project, manifest, counts)
    intake_007(archives["TEEA007"], project, manifest, counts)
    intake_closure(archives["TEEA007_CLOSURE"], project, manifest, counts)

    if counts != EXPECTED_COUNTS:
        raise RuntimeError(f"Intake counts mismatch: {counts} != {EXPECTED_COUNTS}")

    forbidden = [
        x for x in manifest
        if "/assets/rooms/RES_" in x["candidate_path"]
        or "/RES_22/" in x["candidate_path"]
        or "/RES_23/" in x["candidate_path"]
        or "/RES_24/" in x["candidate_path"]
        or x["candidate_path"].startswith("scripts/")
        or x["candidate_path"].startswith("scenes/")
    ]
    if forbidden:
        raise RuntimeError(f"Forbidden candidate paths: {forbidden}")

    output = {
        "schema": 1,
        "status": "STAGED_CANDIDATE_NOT_PROMOTED",
        "owner_approved": False,
        "archive_sha256": EXPECTED_ARCHIVES,
        "counts": counts,
        "rules": [
            "candidate namespaces only; current production room art is not overwritten",
            "only GLB runtime meshes are imported; Blender sources remain in immutable drop",
            "promotion to future_runtime_path is a separate Integrator/Dragon decision",
            "guest alpha closure is evidence only",
            "no private-room or RES_22/23/24 content is part of this intake",
        ],
        "files": manifest,
    }
    out = project / "data/asset_proposals/TEEA_INT_20261123_INTAKE_MANIFEST.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("TEEA_CANDIDATE_INTAKE_PASS " + " ".join(f"{k}={v}" for k, v in counts.items()))
    print(f"manifest={out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
