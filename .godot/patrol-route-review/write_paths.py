import json
from pathlib import Path

candidate_file = Path('.godot/patrol-route-review/candidates.json')
routes = json.loads(candidate_file.read_text())
routes['Joice'][0][2] = -15.0
candidate_file.write_text(json.dumps(routes))
lines = ['[gd_scene load_steps=9 format=3]', '']
for name, points in routes.items():
    values = []
    for x, y, z in points:
        values.extend([0, 0, 0, 0, 0, 0, x, y, z])
    lines.extend([
        f'[sub_resource type="Curve3D" id="Curve3D_{name}"]',
        'bake_interval = 0.25',
        '_data = {',
        '"points": PackedVector3Array(' + ', '.join(str(v) for v in values) + '),',
        '"tilts": PackedFloat32Array(' + ', '.join('0' for _ in points) + ')',
        '}',
        f'point_count = {len(points)}',
        '',
    ])
lines.extend(['[node name="NpcPatrolRoutes" type="Node3D"]', ''])
for name in routes:
    lines.extend([
        f'[node name="{name}" type="Path3D" parent="."]',
        f'curve = SubResource("Curve3D_{name}")',
        '',
    ])
Path('scene/outdoor_npc_paths.tscn').write_text('\n'.join(lines))
print('Wrote eight routes to scene/outdoor_npc_paths.tscn')
