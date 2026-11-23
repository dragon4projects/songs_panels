#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, math
from pathlib import Path
BATCH="TEEA_INT_20261123_004"

def load(p:Path): return json.loads(p.read_text(encoding="utf-8"))
def bounds(fp):
    xs=[float(p[0]) for p in fp]; zs=[float(p[1]) for p in fp]
    return min(xs),max(xs),min(zs),max(zs)
def hit_vertical(x,z0,z1,fp):
    xmin,xmax,zmin,zmax=bounds(fp); a,b=sorted((z0,z1))
    return xmin<=x<=xmax and max(a,zmin)<=min(b,zmax)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--payload-root",required=True)
    ap.add_argument("--report",default="private_review/teea004_geometry_report.json")
    a=ap.parse_args(); payload=Path(a.payload_root)
    anchors=load(payload/"data/asset_proposals/TEEA_INT_20261123_004_furniture_anchors_candidate.json")
    fg=load(payload/"data/asset_proposals/TEEA_INT_20261123_004_foreground_layers_candidate.json")
    assert anchors["batch_id"]==BATCH and anchors.get("approved") is False
    assert fg["batch_id"]==BATCH and fg.get("approved") is False
    errors=[]; stations_total=0; non_station_total=0
    for key,entry in anchors["room_variants"].items():
        stations=entry.get("stations",[]); stations_total+=len(stations)
        obstacles=[]
        for s in stations:
            if s.get("collision_footprint_group"):
                obstacles.append((str(s["furniture_id"]),s["collision_footprint_group"]))
            if abs(float(s["cell_local_x"]))>1.90:
                errors.append((key,s["id"],"cell_x"))
        for o in entry.get("non_station_furniture",[]):
            non_station_total+=1
            obstacles.append((str(o["furniture_id"]),o["collision_footprint_group"]))
        for i,s in enumerate(stations):
            for other in stations[i+1:]:
                d=math.dist([float(s["group_local_x"]),float(s["cell_local_z"])],
                            [float(other["group_local_x"]),float(other["cell_local_z"])])
                if d<0.65:
                    errors.append((key,s["id"],other["id"],"spacing",d))
            foreign=[]
            x=float(s["group_local_x"]); z=float(s["cell_local_z"]); az=float(s["approach_local_z"])
            for oid,fp in obstacles:
                if oid==str(s["furniture_id"]): continue
                if hit_vertical(x,z,az,fp): foreign.append(oid)
            if foreign:
                errors.append((key,s["id"],"foreign",foreign))
    assert stations_total==26
    assert len(fg["layers"])==4
    for key,row in fg["layers"].items():
        if abs(float(row["physical_z"])+0.10)>1e-9:
            errors.append((key,"physical_z",row["physical_z"]))
    report={"batch_id":BATCH,"owner_approved":False,"station_count":stations_total,
            "non_station_furniture_count":non_station_total,
            "foreground_count":len(fg["layers"]),"errors":errors,
            "status":"PASS" if not errors else "FAIL"}
    out=Path(a.report); out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    assert not errors, errors
    print(f"TEEA004_GEOMETRY_QA_PASS stations={stations_total} obstacles={non_station_total} approach_errors=0 foreground=4")
if __name__=="__main__": main()
