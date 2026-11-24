#!/usr/bin/env python3
"""Materialize the pinned free Blendkit harvest into a local ignored cache."""
import argparse,json,hashlib,requests,uuid,re,unicodedata
from pathlib import Path
HERE=Path(__file__).resolve().parent
MANIFEST=HERE/'BLENDKIT_HARVEST_20261124.json'
def slug(s):
    s=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+','_',s).strip('_')[:80]
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--cache',default=str(HERE/'raw_cache'))
    ap.add_argument('--title',action='append')
    args=ap.parse_args()
    doc=json.loads(MANIFEST.read_text(encoding='utf-8'))
    wanted=set(args.title or [])
    cache=Path(args.cache); cache.mkdir(parents=True,exist_ok=True)
    scene=str(uuid.uuid4())
    S=requests.Session(); S.headers['User-Agent']='DragonHouse-Blendkit-Harvest/1.0'
    failures=[]
    for item in doc['items']:
        title=item['requested_title']
        if wanted and title not in wanted: continue
        if not item.get('is_free'):
            print('SKIP FULL_PLAN',title); continue
        f=item.get('chosen_file') or {}
        endpoint=f.get('downloadUrl')
        if not endpoint:
            failures.append((title,'missing download endpoint')); continue
        rr=S.get(endpoint,params={'scene_uuid':scene},timeout=30)
        if rr.status_code!=200:
            failures.append((title,f'API HTTP {rr.status_code}')); continue
        j=rr.json(); url=j.get('filePath') or ((j.get('filePaths') or [{}])[0].get('url'))
        if not url:
            failures.append((title,'missing signed file URL')); continue
        ext='.glb' if f.get('fileType') in ('gltf','gltf_godot') else '.blend'
        outdir=cache/slug(title); outdir.mkdir(parents=True,exist_ok=True)
        out=outdir/('source'+ext); h=hashlib.sha256()
        with S.get(url,stream=True,timeout=180) as z:
            z.raise_for_status()
            with out.open('wb') as fo:
                for chunk in z.iter_content(1024*1024):
                    if chunk: fo.write(chunk); h.update(chunk)
        got=h.hexdigest(); expected=item.get('downloaded_sha256')
        if expected and got!=expected:
            failures.append((title,f'sha mismatch got={got} expected={expected}')); out.unlink(missing_ok=True); continue
        print('OK',title,out,got)
    if failures:
        for x in failures: print('FAIL',*x)
        raise SystemExit(2)
if __name__=='__main__': main()
