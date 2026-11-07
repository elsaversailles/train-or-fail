import json
import math
from pathlib import Path

exec(Path('.godot/patrol-route-review/analyze.py').read_text().split('positions=')[0])
routes = json.loads(Path('.godot/patrol-route-review/candidates.json').read_text())
for name, points in routes.items():
    xmin=min(p[0] for p in points)-1.05; xmax=max(p[0] for p in points)+1.05
    zmin=min(p[2] for p in points)-1.05; zmax=max(p[2] for p in points)+1.05
    nearby=[t for t in triangles if t['name'] != 'New Road' and max(p[0] for p in t['points'])>=xmin and min(p[0] for p in t['points'])<=xmax and max(p[2] for p in t['points'])>=zmin and min(p[2] for p in t['points'])<=zmax]
    failures=[]; count=0
    for a,b in zip(points,points[1:]):
        length=math.dist(a,b); n=math.ceil(length/.25)
        for i in range(n+1):
            x=a[0]+(b[0]-a[0])*i/n; z=a[2]+(b[2]-a[2])*i/n
            for ox,oz in [(0,0)]+[(math.cos(j*math.tau/8),math.sin(j*math.tau/8)) for j in range(8)]:
                px,pz=x+ox,z+oz
                count+=1
                if not any(inside(px,pz,t) for t in nearby):failures.append((round(px,3),round(pz,3)))
    print(name,'sidewalk full 1m footprint checks=',count,'failures=',len(failures),'examples=',failures[:4])
