from pathlib import Path
import json
s=Path(__file__).resolve().parent;t=(s/'epoch_boundary.bend').read_text()
def block(start,end,old,new):
 a=t.index(start);b=t.index(end,a);part=t[a:b];assert part.count(old)==1,(start,old,part.count(old));return t[:a]+part.replace(old,new)+t[b:]
cases={
 'stale_birth_world':(block('def Boundary.point(', 'type Boundary.OK', 'Boundary.State{H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode),True{}}', 'Boundary.State{start,TL.TickLife.after(current,mode),True{}}'),'Boundary.observe'),
 'stale_birth_record':(block('def Boundary.point(', 'type Boundary.OK', 'Boundary.State{H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode),True{}}', 'Boundary.State{H.History.step(start,H.History.Tick{timer}),current,True{}}'),'Boundary.observe'),
 'stale_wait_record':(block('def Boundary.point(', 'type Boundary.OK', 'later(H.History.step(start,H.History.Tick{timer}),TL.TickLife.after(current,mode))', 'later(H.History.step(start,H.History.Tick{timer}),current)'),'Boundary.observe'),
 'skipped_command_world':(block('def Boundary.point(', 'type Boundary.OK', 'later(H.History.step(start,operation),current)', 'later(start,current)'),'Boundary.observe'),
 'false_birth_marker':(block('def Boundary.point(', 'type Boundary.OK', 'TL.TickLife.after(current,mode),True{}}', 'TL.TickLife.after(current,mode),False{}}'),'Boundary.observe'),
 'stale_lookup_record':(block('law Boundary.lookup:', 'def Boundary.lookup(', 'Some{Boundary.monster(point)}', 'Some{original}'),'Boundary.lookup'),
 'assumed_boundary_validity':(block('def Boundary.valid(', '# Keep the full Path', '(start => (current => (valid => H.History.step_seeded(start,H.History.Tick{timer},states,valid))))', '(start => (current => (valid => valid)))'),'Boundary.valid')
}
for n,(body,loc) in cases.items(): (s/('negative_'+n+'.bend')).write_text(body)
(s/'negative_cases.json').write_text(json.dumps({n:l for n,(b,l) in cases.items()},indent=2)+'\n')
print('PASS prepared seven intended negative mutations.')
