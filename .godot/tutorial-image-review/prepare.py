from pathlib import Path
import shutil, re

root = Path(__file__).resolve().parents[2]
qa = Path(__file__).resolve().parent / 'qa'
seeds = [
 'scene/screengameplays/left_sliding_panel.tscn',
 'scene/screengameplays/kyc_panel.tscn',
 'scene/screengameplays/credit_scoring_panel.tscn',
 'theme/game_theme.tres',
 'models3d/characters/F/alyssa_cruz.tscn',
 'models3d/characters/F/maria_santos.tscn',
 'models3d/characters/M/mark_reyes.tscn',
 'images/applicants info/FraudDetection/a2/fd_r02_location_convenience_counter.png',
 'images/applicants info/FraudDetection/a2/fd_r02_item_laundry_detergent.png',
 'images/applicants info/KYC/a1/a1_id.png',
 'images/applicants info/CreditScoring/a1/cs_a1_GI.png',
 'images/applicants info/CreditScoring/a1/cs_a1_PH.png',
 'images/applicants info/CreditScoring/a1/cs_a1_arrears.png',
 'images/applicants info/CreditScoring/a1/cs_a1_DR.png',
]
seen = set()
def copy_resource(rel):
    if rel in seen: return
    seen.add(rel)
    src = root / rel
    if not src.is_file():
        print('MISSING', rel)
        return
    dst = qa / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    if src.suffix in ('.tscn','.tres','.gd','.import'):
        text = src.read_text(encoding='utf-8-sig')
        for dependency in re.findall(r'"res://([^"\n]+)"', text):
            copy_resource(dependency)
    if Path(str(src)+'.import').exists(): copy_resource(rel+'.import')
    if Path(str(src)+'.uid').exists(): copy_resource(rel+'.uid')

for seed in seeds: copy_resource(seed)
for folder in ('F','M'):
    for tex in (root / 'assets/Applicants/newmodels' / folder).glob('*.png'):
        copy_resource(tex.relative_to(root).as_posix())
print('COPIED', len(seen), 'resources')
