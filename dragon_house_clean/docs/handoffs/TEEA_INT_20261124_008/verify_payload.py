import hashlib,json,sys
from pathlib import Path
r=Path(sys.argv[1]).resolve();d=json.loads((r/'data/asset_proposals/TEEA_INT_20261124_008/dependency_manifest.json').read_text())
bad=[]
for x in d['items']:
 p=r/x['path']
 if not p.is_file() or p.stat().st_size!=x['bytes'] or hashlib.sha256(p.read_bytes()).hexdigest()!=x['sha256']:bad.append(x['path'])
print('checked',len(d['items']),'errors',len(bad))
for p in bad:print(p)
sys.exit(bool(bad))
