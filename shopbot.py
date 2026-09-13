#!/usr/bin/env python3
# focused repro: walk to the shop mat, BUY a potion with starting gold,
# report gold/pots before and after. python3 shopbot.py <port>
import socket, sys, time

s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), timeout=5)
s.settimeout(0.05)
buf = b""; me = {}; my_pid = None; snap_p = []

def send(l): s.sendall((l + "\n").encode())
def pump():
    global buf, my_pid
    try:
        d = s.recv(65536)
        if d: buf += d
    except socket.timeout: pass
    global snap_p
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        parts = line.decode(errors="replace").split(" |", 1)
        toks = parts[0].split()
        if not toks: continue
        tag, ns = toks[0], [int(t) for t in toks[1:] if t.isdigit()]
        if tag == "ME":
            me.update(dict(zip("pid hp mhp xp xpn gold lv pts str agi vit wea arm hel chm pots".split(), ns)))
            my_pid = ns[0]
        elif tag == "SNAP":
            np = ns[2]; i = 3; ps = []
            for _ in range(np): ps.append(ns[i:i+15]); i += 15
            snap_p = ps

send("HELLO |shopper"); time.sleep(0.4); pump()
send("CREATE 0 0 0 0 0 0"); time.sleep(0.4); pump()
# Walk north through the cleared spawn passage, then east across the village.
# Going east first can hit generated terrain at (9,7).
last = None
for _ in range(200):
    pump()
    mine = next((p for p in snap_p if p[0] == my_pid), None)
    if not mine: time.sleep(0.05); continue
    x, y = mine[1], mine[2]
    if (abs(x-9) + abs(y-4)) == 0: break
    d = 2 if y > 4 else 3 if y < 4 else (1 if x < 9 else 0)
    if d != last: send(f"MOVE {d}"); last = d
    time.sleep(0.05)
send("HALT"); time.sleep(0.3); pump()
mine = next((p for p in snap_p if p[0] == my_pid), None)
print(f"at: {mine[1]},{mine[2]}  before: gold={me.get('gold')} pots={me.get('pots')}")
send("BUY 0"); time.sleep(0.5); pump()
print(f"after BUY 0:  gold={me.get('gold')} pots={me.get('pots')}")
ok = me.get('pots') == 1 and me.get('gold') == 2
print("SERVER PATH:", "PASS" if ok else "FAIL")

s.close()
sys.exit(0 if ok else 1)
