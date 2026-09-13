from pathlib import Path
import hashlib,json,re
s=Path(__file__).resolve().parent
r=s.parent.parent
for p,h in json.loads((s/'before_hashes.json').read_text()).items():assert hashlib.sha256(Path(p).read_bytes()).hexdigest()==h,('Baseline changed',p)
assert len(re.findall(r'^law ',(s/'epoch_boundary.bend').read_text(),re.M))==13
assert len(re.findall(r'^law ',(s/'boundary_probe.bend').read_text(),re.M))==23
assert (s/'module.txt').read_text()=='All terms check.\n'
assert (s/'probe.txt').read_text()=='All terms check.\n'
p=s/'proofs.bend';assert 'import ./epoch_boundary.bend' not in p.read_text();p.write_text(p.read_text().replace('import Base\n','import Base\nimport ./epoch_boundary.bend as Boundary\n',1))
p=s/'check-proofs.sh';t=p.read_text();assert "and ordinary-lifetime-once proofs'" in t;p.write_text(t.replace("and ordinary-lifetime-once proofs'","and ordinary-lifetime-once and exact-lifetime-boundary proofs'"))
p=s/'README.md';p.write_text(p.read_text()+'''
Lifetime certificates now identify the exact world and full monster record
at the first respawn, or at the end of a history with no respawn. Lookup by the
original monster ID is derived there, along with dead status and seeded-world
validity. The complete history path is retained for subsequent composition.
Boundary validation fixtures and evidence are kept in .proof-work/epoch-boundary.
''')
p=s/'PROOF_PLAN.md';p.write_text(p.read_text()+'''
Exact lifetime boundary (13 safe laws, proof-only):
- epoch_boundary.bend computes Boundary.State from the actual Epoch.Follow.
  Done retains the current world/record and a False birth marker; Birth uses
  the actual tick world and TickLife.after record with True. Wait advances both
  world and the changing corpse; Command advances the actual command world.
- point is structurally recursive in Follow before receiving its runtime
  world/monster arguments. observe requires equalities tying those arguments
  to the certificate indices; it cannot transport an arbitrary substituted
  starting world or monster into the boundary guarantee.
- Boundary.OK derives exact monster membership, unique final monster IDs,
  dead status 0 at Birth or 1 at Done, and preservation of the original MID.
  previous composes ID equalities through waiting updates. birth derives its
  actual new record and dead status from TickLife.Tracked and the True event.
- marker equates the point marker with Epoch.reborn. prefix_end proves that
  its world is the end world of the exact certified prefix. lookup recovers
  Some of the boundary's complete record by its original MID. alive/dead expose
  the respective dead flag from the checked boundary marker.
- valid derives SeededWorld.OK at the boundary by actual History.step_seeded
  through the certified prefix. It does not reuse input validity as if no
  command or tick had changed the world.
- Boundary.Report retains the full actual Run, its equality to the requested
  trace, the complete Epoch.Path including all post-birth entries, Follow,
  exact boundary point/equality, Boundary.OK, boundary SeededWorld.OK and its
  equality to the prefix end world. from_record/report consume affine request
  planners once through Epoch.record and derive these properties.
- report_lookup exposes the actual boundary lookup; to_cut preserves the
  established reward-prefix certificate from the same report. No suffix or
  final world is dropped merely because the boundary precedes a later kill.
- This provides the actual new monster and valid boundary world needed for
  later lifetime composition. Splitting the retained Path at that world and
  chaining successive reward epochs remain OPEN, as do all six original full
  scopes, liveness, quests/finalization/reload and persistence.
''')
(s/'install_files.json').write_text(json.dumps(['epoch_boundary.bend','proofs.bend','check-proofs.sh','README.md','PROOF_PLAN.md'])+'\n')
print('PASS baseline, 13 laws, 23 self-contained checks; mandatory import and docs staged.')

