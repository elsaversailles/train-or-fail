import json
from pathlib import Path

triangles=json.loads(Path('.godot/patrol-route-review/triangles.json').read_text())
def inside(x,z,tri):
    a,b,c=tri['points']
    ax,az=a[0],a[2]; bx,bz=b[0],b[2]; cx,cz=c[0],c[2]
    d=(bz-cz)*(ax-cx)+(cx-bx)*(az-cz)
    if abs(d)<1e-8:return False
    u=((bz-cz)*(x-cx)+(cx-bx)*(z-cz))/d
    v=((cz-az)*(x-cx)+(ax-cx)*(z-cz))/d
    return u>=-1e-6 and v>=-1e-6 and u+v<=1.000001
def hit(x,z):
    return [t['name'] for t in triangles if inside(x,z,t)]
positions={'Grandpa':(2.6428,-12.9011),'Assistant':(5.0703,-11.8233),'Mark':(-46.6775,-10.3370),'Cashier':(-44.3208,-10.2828),'Clara':(-208.7009,108.4852),'Supplier':(-209.1593,110.6895),'Jericho':(-124.7311,10.1470),'Joice':(-120.3725,10.0519),'Elena':(-198.9515,12.7016)}
for name,(x,z) in positions.items():
    print(name,(x,z),'surfaces',hit(x,z))
    for axis in ['x','z']:
        ranges=[]; start=None
        for d in range(-45,46):
            members=hit(x+(d if axis=='x' else 0),z+(d if axis=='z' else 0))
            if members and start is None:start=d
            if not members and start is not None:ranges.append((start,d-1));start=None
        if start is not None:ranges.append((start,45))
        print('  safe',axis,ranges)

for title,bounds in [('bakery',(-90,45,-35,35)),('hospital',(-240,-185,65,150)),('dealership',(-165,-85,-15,35))]:
    print('\n',title,bounds)
    x0,x1,z0,z1=bounds
    for z in range(z0,z1+1,2):
        line=''
        for x in range(x0,x1+1,2):
            h=hit(x,z)
            ch='.' if h else ' '
            if 'New Road' in h:ch='+'
            for name,(nx,nz) in positions.items():
                if abs(x-nx)<=1 and abs(z-nz)<=1:ch=name[0]
            line+=ch
        print(f'{z:5} {line}')
