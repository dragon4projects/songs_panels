#!/usr/bin/env python3
"""Integrator-side geometry/approach QA for TEEA_INT_20261122_003."""
from __future__ import annotations
import argparse, json
from pathlib import Path

def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

def bounds(fp):
    xs=[float(p[0]) for p in fp]
    zs=[float(p[1]) for p in fp]
    return min(xs),max(xs),min(zs),max(zs)

def vertical_segment_hits(x,z0,z1,fp):
    xmin,xmax,zmin,zmax=bounds(fp)
    a,b=sorted((z0,z1))
    return xmin <= x <= xmax and max(a,zmin) <= min(b,zmax)

def main()->int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--project",default=".")
    ap.add_argument("--payload-root",required=True)
    ap.add_argument("--report",default="private_review/teea003_geometry_report.json")
    args=ap.parse_args()
    project=Path(args.project).resolve()
    payload=Path(args.payload_root).resolve()
    anchors=load(payload/"data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json")
    fg=load(payload/"data/asset_proposals/TEEA_INT_20261122_003_foreground_layers_candidate.json")
    measurements=load(payload/"docs/art_review/TEEA_INT_20261122_003_anchor_measurements.json")
    overrides=load(project/"data/asset_proposals/TEEA_INT_20261122_003_integration_overrides.json")

    assert anchors.get("approved") is False
    assert fg.get("approved") is False
    assert set(fg["additive_layers"])=={"music/R1","cinema/R1"}

    expected_z={
        "music/R1":float(measurements["music"]["music_listen_chair"]["godot_z_front"]),
        "cinema/R1":float(measurements["cinema"]["cinema_sofa"]["godot_z_front"]),
    }
    for key,value in expected_z.items():
        actual=float(overrides["foreground_physical_z"][key]["value"])
        assert abs(actual-value)<1e-9, (key,actual,value)

    rows=[]
    errors=[]
    station_count=0
    obstacle_count=0
    for key,entry in anchors["room_variants"].items():
        stations=entry.get("stations",[])
        station_count+=len(stations)
        obstacles=[]
        for s in stations:
            fp=s.get("collision_footprint")
            if fp:
                obstacles.append((str(s["furniture_id"]),fp,"station_furniture"))
        for o in entry.get("non_station_furniture",[]):
            obstacle_count+=1
            obstacles.append((str(o["furniture_id"]),o["collision_footprint"],"collision_only"))
        for s in stations:
            sid=str(s["id"])
            own_id=str(s["furniture_id"])
            x=float(s["cell_local_x"])
            z=float(s["cell_local_z"])
            approach=float(s["approach_local_z"])
            foreign=[]
            own_inside=None
            for oid,fp,kind in obstacles:
                if oid==own_id:
                    xmin,xmax,zmin,zmax=bounds(fp)
                    own_inside=xmin<=x<=xmax and zmin<=z<=zmax
                    continue
                if vertical_segment_hits(x,z,approach,fp):
                    foreign.append(oid)
            if foreign:
                errors.append({"variant":key,"station":sid,"foreign_collision":foreign})
            rows.append({
                "variant":key,"station":sid,"x":x,"z":z,"approach_z":approach,
                "foreign_collision":foreign,"inside_own_footprint":own_inside
            })

    assert station_count==7
    assert obstacle_count==7
    assert len(anchors["room_variants"]["arrival/R1"]["stations"])==0
    assert len(anchors["room_variants"]["corridor/R1"]["stations"])==0
    assert not errors, errors

    report={
        "batch_id":"TEEA_INT_20261122_003",
        "owner_approved":False,
        "station_count":station_count,
        "non_station_furniture_count":obstacle_count,
        "approach_collision_errors":errors,
        "foreground_physical_z":expected_z,
        "station_rows":rows,
        "status":"PASS"
    }
    out=project/args.report
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("TEEA003_GEOMETRY_QA_PASS stations=7 obstacles=7 approach_errors=0 foreground=2")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
