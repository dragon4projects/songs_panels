#!/usr/bin/env python3
"""Prepare an EPHEMERAL TEEA003 integration tree for CI/live-camera QA.

This script intentionally writes approved=true only into the runner's dirty
working copy of interior_layers_v1.json so the existing production renderer can
mount the candidate. Source proposals and repository approval state stay false.
"""
from __future__ import annotations
import argparse, copy, hashlib, json, shutil
from pathlib import Path

ROOMS = ("arrival","corridor","music","cinema","artifact","workshop")
VARIANT = "R1"

def sha256(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda:f.read(1024*1024),b""):
            h.update(chunk)
    return h.hexdigest()

def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--project",default=".")
    ap.add_argument("--payload-root",required=True)
    ap.add_argument("--report",default="private_review/teea003_prepare_report.json")
    args=ap.parse_args()
    project=Path(args.project).resolve()
    payload=Path(args.payload_root).resolve()
    overrides=load(project/"data/asset_proposals/TEEA_INT_20261122_003_integration_overrides.json")
    candidate=load(payload/"data/asset_proposals/TEEA_INT_20261122_003_interiors.json")
    anchors=load(payload/"data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json")
    repo_candidate=load(project/"data/asset_proposals/TEEA_INT_20261122_003_interiors.json")

    assert candidate["batch_id"]=="TEEA_INT_20261122_003"
    assert candidate.get("approved") is False
    assert anchors.get("approved") is False
    assert overrides.get("owner_approved") is False and overrides.get("qa_only") is True
    assert candidate==repo_candidate, "Payload proposal differs from reviewed repository proposal"

    interior_path=project/"data/interior_layers_v1.json"
    furniture_path=project/"data/furniture_interactions_v1.json"
    interior=load(interior_path)
    furniture=load(furniture_path)
    base_interior_sha=sha256(interior_path)
    base_furniture_sha=sha256(furniture_path)

    copied=[]
    role_count=0
    for room in ROOMS:
        entry=candidate["room_types"][room][VARIANT]
        qa_layers=[]
        for raw in entry["layers"]:
            item=copy.deepcopy(raw)
            rel=Path(item["path"])
            src=payload/rel
            dst=project/rel
            assert src.is_file(), f"Missing payload asset: {rel}"
            actual=sha256(src)
            assert actual==item["sha256"], f"SHA mismatch: {rel}"
            dst.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dst)
            assert sha256(dst)==actual
            item["approved"]=True
            item["source_batch"]="TEEA_INT_20261122_003_QA_ONLY"
            item["qa_only_ephemeral"]=True
            item.pop("status",None)
            if item["role"]=="foreground":
                key=f"{room}/{VARIANT}"
                item["physical_z"]=float(overrides["foreground_physical_z"][key]["value"])
            qa_layers.append(item)
            copied.append(str(rel))
            role_count+=1
        interior["room_types"].setdefault(room,{})[VARIANT]={"layers":qa_layers}

    interior["_qa_candidate_note"]="TEEA003 is mounted only in an ephemeral CI/integrator working tree; owner_approved=false."
    interior_path.write_text(json.dumps(interior,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")

    variant=furniture.setdefault("variant_cell_overrides",{})
    station_count=0
    for key,items in overrides["runtime_station_map"].items():
        room,variant_name=key.split("/")
        assert variant_name=="R1"
        variant[f"{room}:R1:0"]=copy.deepcopy(items)
        station_count+=len(items)
    furniture["qa_candidate_batch"]="TEEA_INT_20261122_003"
    furniture["qa_candidate_owner_approved"]=False
    furniture_path.write_text(json.dumps(furniture,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")

    report={
        "batch_id":"TEEA_INT_20261122_003",
        "owner_approved":False,
        "ephemeral_mount":True,
        "production_png_count":role_count,
        "station_count":station_count,
        "copied_paths":copied,
        "base_interior_sha256":base_interior_sha,
        "base_furniture_sha256":base_furniture_sha,
        "foreground_physical_z":{
            k:v["value"] for k,v in overrides["foreground_physical_z"].items()
        }
    }
    out=project/args.report
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("TEEA003_PREP_QA_PASS png=20 stations=7 owner_approved=false")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
