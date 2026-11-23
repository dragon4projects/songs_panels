#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,math
from pathlib import Path
BATCH="TEEA_INT_20261123_005"
def load(p): return json.loads(Path(p).read_text())
def bounds(fp):
    xs=[float(p[0]) for p in fp]; zs=[float(p[1]) for p in fp]
    return min(xs),max(xs),min(zs),max(zs)
def hit_vertical(x,z0,z1,fp):
    xmin,xmax,zmin,zmax=bounds(fp); a,b=sorted((z0,z1))
    return xmin<=x<=xmax and max(a,zmin)<=min(b,zmax)
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--payload-root",required=True); ap.add_argument("--report",default="private_review/teea005_depth_report.json")
    a=ap.parse_args(); root=Path(a.payload_root)
    anchors=load(root/"data/asset_proposals/TEEA_INT_20261123_005_furniture_anchors_candidate.json")
    fg=load(root/"data/asset_proposals/TEEA_INT_20261123_005_foreground_layers_candidate.json")
    depth=load(root/"docs/art_review/TEEA_INT_20261123_005_depth_readability_report.json")
    errors=[]; total=0; obstacles=0
    for key,entry in anchors["room_variants"].items():
        st=entry.get("stations",[]); total+=len(st); obs=[]
        for s in st:
            fp=s.get("collision_footprint_group")
            if fp: obs.append((str(s["furniture_id"]),fp))
            if abs(float(s["cell_local_x"]))>1.90: errors.append((key,s["id"],"x"))
        for o in entry.get("non_station_furniture",[]):
            obstacles+=1; obs.append((str(o["furniture_id"]),o["collision_footprint_group"]))
        for i,s in enumerate(st):
            for other in st[i+1:]:
                d=math.dist([float(s["group_local_x"]),float(s["cell_local_z"])],[float(other["group_local_x"]),float(other["cell_local_z"])])
                if d<0.65: errors.append((key,s["id"],other["id"],"spacing",d))
            x=float(s["group_local_x"]); z=float(s["cell_local_z"]); az=float(s["approach_local_z"])
            bad=[oid for oid,fp in obs if oid!=str(s["furniture_id"]) and hit_vertical(x,z,az,fp)]
            if bad: errors.append((key,s["id"],"foreign",bad))
    assert total==26 and len(fg["layers"])==8 and depth["machine_pass"] is True
    for k,v in fg["layers"].items():
        if abs(float(v["physical_z"])-0.15)>1e-9: errors.append((k,"physical_z"))
    for k,v in depth["variants"].items():
        if not v["pass"] or float(v["minimum_cross_band_station_separation_m"])<0.35:
            errors.append((k,"depth"))
    report={"batch_id":BATCH,"owner_approved":False,"stations":total,"collision_only":obstacles,"foreground":8,"depth_pass_variants":8,"errors":errors}
    out=Path(a.report); out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(report,indent=2)+"\n")
    assert not errors,errors
    print(f"TEEA005_DEPTH_GEOMETRY_QA_PASS stations={total} foreground=8 depth=8/8 foreign=0")
if __name__=="__main__": main()
