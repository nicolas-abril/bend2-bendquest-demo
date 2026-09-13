#!/usr/bin/env python3
"""Native HELLO lifecycle regression. Build first; --binary selects a test build."""
from pathlib import Path
import argparse,os,socket,subprocess,tempfile,time
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--binary',type=Path,default=Path(__file__).resolve().parent/'.build/bendquest')
parser.add_argument('--port',type=int,default=4982)
args=parser.parse_args()
work=Path(tempfile.mkdtemp(prefix='bendquest-session-check-'))
env=os.environ.copy();env.pop('BQ_AUTO',None);env['BQ_SERVER_PORT']=str(args.port)
clients=[]
class Client:
 def __init__(self):
  self.sock=socket.create_connection(('127.0.0.1',args.port),timeout=2);self.sock.settimeout(.1);self.buf=b'';self.lines=[];clients.append(self)
 def send(self,line):self.sock.sendall((line+'\n').encode())
 def wait(self,predicate,seconds=4):
  end=time.monotonic()+seconds
  while time.monotonic()<end:
   while b'\n' in self.buf:
    raw,self.buf=self.buf.split(b'\n',1);line=raw.decode();self.lines.append(line)
    if predicate(line):return line
   try:
    data=self.sock.recv(65536);assert data,'Connection closed';self.buf+=data
   except socket.timeout:pass
  raise AssertionError(('Timed out',self.lines[-15:]))
 def hello(self,name):self.send('HELLO |'+name);return self.wait(lambda x:x.startswith('WELCOME '))
 def create(self):
  self.send('CREATE 1 0 2 1 0 0');return int(self.wait(lambda x:x.startswith('ME ')).split()[1])
 def snapshot(self,expected):
  def matches(line):
   if not line.startswith('SNAP '):return False
   words=list(map(int,line.split(' |')[0].split()[1:]))
   count=words[2]
   return count==len(expected) and {words[3+i*15] for i in range(count)}==expected
  return self.wait(matches)
 def reject(self,line):self.send(line);return self.wait(lambda x:x.startswith('ERR '))
 def say(self,marker,name):
  self.send('SAY |'+marker);line=self.wait(lambda x:x.startswith('EV ') and marker in x)
  assert line=='EV |'+name+': '+marker,line
 def close(self):self.sock.close()
p=subprocess.Popen([str(args.binary.resolve()),'--threads','2','--gpu','off'],cwd=work,env=env,stdout=open(work/'server.log','w'),stderr=subprocess.STDOUT)
try:
 end=time.monotonic()+10
 while True:
  assert p.poll() is None,(work/'server.log').read_text()
  try:a=Client();break
  except OSError:
   assert time.monotonic()<end;time.sleep(.05)
 a.reject('CREATE 1 0 2 1 0 0');a.reject('HELLO |');a.reject('HELLO |abcdefghijklm')
 a.hello('alpha');a.hello('Étoile')
 b=Client();b.reject('HELLO |Étoile');b.hello('observer');observer=b.create()
 pid=a.create();assert pid!=0 and pid!=observer;b.snapshot({pid,observer})
 a.say('before_repeated_hello','Étoile')
 for index,name in enumerate(['Étoile','renamed','']):
  welcome_count=sum(x.startswith('WELCOME ') for x in a.lines)
  error=a.reject('HELLO |'+name);assert 'already playing' in error,error
  a.send('PING '+str(100+index));a.wait(lambda x:x=='PONG '+str(100+index))
  assert sum(x.startswith('WELCOME ') for x in a.lines)==welcome_count,'Rejected HELLO sent WELCOME'
  a.say('after_hello_'+str(index),'Étoile')
  b.snapshot({pid,observer})
 a.reject('CREATE 1 0 2 1 0 0');a.say('after_duplicate_create','Étoile')
 c=Client();c.hello('renamed');third=c.create();assert third not in (0,pid,observer)
 c.snapshot({pid,observer,third})
 a.close();b.snapshot({observer,third})
 d=Client();d.hello('Étoile');replacement=d.create();assert replacement not in (0,observer,third)
 d.snapshot({observer,third,replacement})
 d.say('after_reconnect','Étoile')
 print('PASS rejected invalid/pre-create commands, UTF-8 identification, pre-create rename, online reservation, repeated HELLO preserves gameplay/profile/PID, duplicate CREATE, disconnect and reconnect',flush=True)
 print('ARTIFACTS',work,flush=True)
finally:
 for index,client in enumerate(clients):
  (work/('client-'+str(index)+'.txt')).write_text('\n'.join(client.lines)+'\n');client.close()
 if p.poll() is None:
  p.terminate()
  try:p.wait(timeout=3)
  except subprocess.TimeoutExpired:p.kill();p.wait()
 print('TRANSCRIPTS',work,flush=True)
