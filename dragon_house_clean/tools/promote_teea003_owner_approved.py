#!/usr/bin/env python3
"""Promote owner-approved TEEA_INT_20261122_003 into production data/assets.

This script is intentionally narrow:
- exact reviewed payload only;
- six R1 public room families only;
- no private-room assets;
- no resident-bank approval;
- no source-art mutation outside the production branch.
"""
from __future__ import annotations
import argparse, copy, hashlib, json, shutil
from pathlib import Path

# Integrator calibration provenance is committed beside this script before promotion.
# Cold CI runners may need several minutes for the first Godot import/test process.\n# Promotion run trigger after CI timeout fix.
BATCH="TEEA_INT_20261122_003"
ROOMS=("arrival","corridor","music","cinema","artifact","workshop")

def load(p:Path):
    return json.loads(p.read_text(encoding="utf-8"))

def sha256(p:Path)->str:
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""):
            h.update(b)
    return h.hexdigest()

def main()->int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--project",default=".")
    ap.add_argument("--payload-root",required=True)
    ap.add_argument("--report",default="TEEA003_OWNER_PROMOTION_REPORT.json")
    a=ap.parse_args()
    project=Path(a.project).resolve()
    payload=Path(a.payload_root).resolve()

    proposal_path=project/"data/asset_proposals/TEEA_INT_20261122_003_interiors.json"
    overrides_path=project/"data/asset_proposals/TEEA_INT_20261122_003_integration_overrides.json"
    anchors_path=payload/"data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json"
    payload_proposal=load(payload/"data/asset_proposals/TEEA_INT_20261122_003_interiors.json")
    proposal=load(proposal_path)
    overrides=load(overrides_path)
    anchors=load(anchors_path)

    assert proposal==payload_proposal, "Reviewed repo proposal differs from exact payload"
    assert proposal["batch_id"]==BATCH and proposal.get("approved") is False
    assert overrides["batch_id"]==BATCH and overrides.get("qa_only") is True
    assert overrides.get("owner_approved") is False
    assert anchors.get("approved") is False

    interior_path=project/"data/interior_layers_v1.json"
    furniture_path=project/"data/furniture_interactions_v1.json"
    interior=load(interior_path)
    furniture=load(furniture_path)

    copied=[]
    layer_count=0
    for room in ROOMS:
        entry=proposal["room_types"][room]["R1"]
        prod_layers=[]
        for raw in entry["layers"]:
            item=copy.deepcopy(raw)
            rel=Path(item["path"])
            src=payload/rel
            dst=project/rel
            assert src.is_file(), f"missing exact payload file: {rel}"
            actual=sha256(src)
            assert actual==item["sha256"], f"SHA mismatch: {rel}"
            if dst.exists():
                # Promotion is idempotent only for exact bytes.
                assert sha256(dst)==actual, f"refuse overwrite of different production asset: {rel}"
            else:
                dst.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(src,dst)
            item["approved"]=True
            item["source_batch"]=BATCH+"_OWNER_APPROVED"
            item.pop("status",None)
            if item["role"]=="foreground":
                key=f"{room}/R1"
                item["physical_z"]=float(overrides["foreground_physical_z"][key]["value"])
            prod_layers.append(item)
            copied.append(str(rel))
            layer_count+=1
        interior["room_types"].setdefault(room,{})["R1"]={"layers":prod_layers}

    variant=furniture.setdefault("variant_cell_overrides",{})
    station_count=0
    for key,items in overrides["runtime_station_map"].items():
        room,rv=key.split("/")
        assert rv=="R1"
        variant[f"{room}:R1:0"]=copy.deepcopy(items)
        station_count+=len(items)

    furniture["source"] = str(furniture.get("source","")) + " + owner-approved TEEA_INT_20261122_003 R1 anchors"
    align=furniture.setdefault("accepted_art_alignment",{})
    align[BATCH]={
        "owner_approved":"2026-11-23",
        "integrator_qa":"PASS frozen-yaw live resident sprites",
        "rooms":list(ROOMS),
        "stations":station_count
    }

    proposal["approved"]=True
    proposal["owner_review_status"]="OWNER_APPROVED"
    proposal["owner_approved_date"]="2026-11-23"
    proposal["integrator_qa"]="PASS"
    proposal["production_promotion"]="THIS_BRANCH"
    for room in ROOMS:
        for item in proposal["room_types"][room]["R1"]["layers"]:
            item["approved"]=True
            item["status"]="OWNER_APPROVED_PRODUCTION"

    overrides["owner_approved"]=True
    overrides["qa_only"]=False
    overrides["promotion_status"]="OWNER_APPROVED_PRODUCTION"
    overrides["owner_approved_date"]="2026-11-23"
    for row in overrides["foreground_physical_z"].values():
        row["status"]="OWNER_ACCEPTED_RUNTIME_CALIBRATION"

    interior["_note"]="Owner-accepted Teea 002 REWORK R1 + owner-approved Teea 003 R1 public-room assets. Unlisted variants remain procedural."
    interior_path.write_text(json.dumps(interior,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    furniture_path.write_text(json.dumps(furniture,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    proposal_path.write_text(json.dumps(proposal,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    overrides_path.write_text(json.dumps(overrides,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

    report={
        "batch_id":BATCH,
        "owner_approved":True,
        "owner_approved_date":"2026-11-23",
        "production_png_count":layer_count,
        "station_count":station_count,
        "rooms":list(ROOMS),
        "copied_paths":copied,
        "resident_bank_approval_changed":False,
        "private_room_assets_changed":False,
        "status":"READY_TO_COMMIT_AFTER_RUNTIME_QA"
    }
    (project/a.report).write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    assert layer_count==20 and station_count==7
    print("TEEA003_OWNER_PROMOTION_PREP_PASS png=20 stations=7 owner_approved=true")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
