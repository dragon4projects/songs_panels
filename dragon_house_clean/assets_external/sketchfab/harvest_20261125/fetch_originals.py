#!/usr/bin/env python3
"""Restore six exact original GLB files before staging with Git LFS."""
import hashlib, json, pathlib, urllib.request, tempfile, os, struct
root=pathlib.Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text())
for row in manifest['items']:
    p=root/row['git_path']
    p.parent.mkdir(parents=True,exist_ok=True)
    def valid(f):
        if not f.is_file() or f.stat().st_size!=row['bytes']: return False
        with f.open('rb') as h:
            if struct.unpack('<3I',h.read(12))!=(0x46546c67,2,row['bytes']): return False
        h=hashlib.sha256()
        with f.open('rb') as f1:
            for b in iter(lambda:f1.read(1048576),b''):h.update(b)
        return h.hexdigest()==row['sha256']
    if valid(p):
        print('PASS existing',p.name)
        continue
    if p.exists(): raise SystemExit('Existing file differs; not overwriting: '+str(p))
    fd,tmp=tempfile.mkstemp(prefix=p.name+'.',suffix='.tmp',dir=p.parent)
    os.close(fd)
    try:
        with urllib.request.urlopen(row['download_url'],timeout=120) as resp,open(tmp,'wb') as out:
            while b:=resp.read(1048576):out.write(b)
        if not valid(pathlib.Path(tmp)):raise RuntimeError('SHA/GLB mismatch: '+p.name)
        os.replace(tmp,p)
        print('PASS downloaded',p.name)
    finally:
        pathlib.Path(tmp).unlink(missing_ok=True)
print('All originals verified. Stage raw/ using the existing Git LFS rules.')
