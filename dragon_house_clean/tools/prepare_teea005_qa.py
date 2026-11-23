#!/usr/bin/env python3
from __future__ import annotations
import argparse, copy, hashlib, json, shutil
from pathlib import Path
BATCH="TEEA_INT_20261123_005"
ROOMS=("common","study","rest","library")

def load(p:Path): return json.loads(p.read_text(encoding="utf-8"))
def sha256(p:Path)->str:
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""): h.update(b)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--project",default=".")
    ap.add_argument("--payload-root",required=True)
    ap.add_argument("--report",default="private_review/teea005_prepare_report.json")
    a=ap.parse_args(); project=Path(a.project).resolve(); payload=Path(a.payload_root).resolve()
    proposal=load(payload/"data/asset_proposals/TEEA_INT_20261123_005_interiors.json")
    anchors=load(payload/"data/asset_proposals/TEEA_INT_20261123_005_furniture_anchors_candidate.json")
    fg=load(payload/"data/asset_proposals/TEEA_INT_20261123_005_foreground_layers_candidate.json")
    assert proposal["batch_id"]==BATCH and proposal.get("approved") is False
    assert anchors["batch_id"]==BATCH and anchors.get("approved") is False
    assert fg["batch_id"]==BATCH and fg.get("approved") is False
    ip=project/"data/interior_layers_v1.json"; fp=project/"data/furniture_interactions_v1.json"
    interior=load(ip); furniture=load(fp)
    copied=[]; layer_count=0
    for room,variants in proposal["room_types"].items():
        assert room in ROOMS
        for rv,entry in variants.items():
            layers=[]
            for raw in entry["layers"]:
                item=copy.deepcopy(raw); rel=Path(item["path"]); src=payload/rel; dst=project/rel
                assert src.is_file(), rel
                actual=sha256(src); assert actual==item["sha256"], rel
                dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,dst); assert sha256(dst)==actual
                item["approved"]=True
                item["source_batch"]=BATCH+"_QA_ONLY"
                item["qa_only_ephemeral"]=True
                item.pop("status",None)
                if item["role"]=="foreground":
                    key=f"{room}/{rv}"
                    assert key in fg["layers"]
                    item["physical_z"]=float(fg["layers"][key]["physical_z"])
                layers.append(item); copied.append(str(rel)); layer_count+=1
            interior["room_types"].setdefault(room,{})[rv]={"layers":layers}
    overrides=furniture.setdefault("variant_cell_overrides",{})
    station_count=0
    for key,items in anchors["runtime_variant_cell_overrides_preview"].items():
        overrides[key]=copy.deepcopy(items); station_count+=len(items)
    interior["_qa_candidate_note_005"]="TEEA005 missing width-matrix variants mounted only in ephemeral integrator tree; owner_approved=false."
    furniture["qa_candidate_batch_005"]=BATCH
    furniture["qa_candidate_owner_approved_005"]=False
    ip.write_text(json.dumps(interior,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    fp.write_text(json.dumps(furniture,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    report={"batch_id":BATCH,"owner_approved":False,"ephemeral_mount":True,
            "production_png_count":layer_count,"station_count":station_count,
            "foreground_count":len(fg["layers"]),"copied_paths":copied}
    out=project/a.report; out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    assert layer_count==32 and station_count==26 and len(fg["layers"])==8
    print("TEEA005_PREP_QA_PASS png=32 stations=26 foreground=8 owner_approved=false")
if __name__=="__main__": main()
