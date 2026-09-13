#!/usr/bin/env python3
# dev test bot: speaks the BendQuest wire protocol against a headless
# server, plays for a while, and reports what it saw. Exercises:
# HELLO/CREATE, movement, attacking, quests (talk), potions, shop,
# equip, chat, FAME. Run: python3 bot.py <port> <name> [secs]
import socket, sys, time
from collections import deque

port = int(sys.argv[1]); name = sys.argv[2]
secs = float(sys.argv[3]) if len(sys.argv) > 3 else 25
s = socket.create_connection(("127.0.0.1", port), timeout=5)
s.settimeout(0.05)
buf = b""
me = {}; snap_p = []; snap_m = []; evs = []; zone = None; grid = ""
welcome = None; my_pid = None
grid_width = 0; grid_height = 0

def send(line): s.sendall((line + "\n").encode())

def move_towards(x, y, reached):
    """Choose the first step of a shortest cardinal path on the server's map."""
    global last_move
    queue = deque([(x, y, None)])
    seen = {(x, y)}
    direction = None
    while queue:
        cx, cy, first = queue.popleft()
        if reached(cx, cy):
            direction = first
            break
        for d, (dx, dy) in enumerate(((-1, 0), (1, 0), (0, -1), (0, 1))):
            nx, ny = cx + dx, cy + dy
            if (nx, ny) in seen or not (0 <= nx < grid_width and 0 <= ny < grid_height):
                continue
            # Same six blocking tile codes as data.bend's tile_walkable.
            tile = int(grid[ny * grid_width + nx], 16)
            if tile in (2, 3, 5, 7, 8, 11):
                continue
            seen.add((nx, ny))
            queue.append((nx, ny, d if first is None else first))
    if direction != last_move:
        send("HALT" if direction is None else f"MOVE {direction}")
        last_move = direction


def parse(line):
    global welcome, zone, grid, me, snap_p, snap_m, my_pid, grid_width, grid_height
    parts = line.split(" |", 1)
    text = parts[1] if len(parts) > 1 else ""
    toks = parts[0].split()
    tag, ns = toks[0], [int(t) for t in toks[1:] if t.isdigit()]
    if tag == "WELCOME": welcome = (ns, text)
    elif tag == "ZONE":
        zone, grid_width, grid_height = ns[:3]
        grid = text
    elif tag == "ME":
        me.update(dict(zip("pid hp mhp xp xpn gold lv pts str agi vit wea arm hel chm pots mainq cull sq0 sq1 sq2 sqd sigils score spincd watk df crit phase".split(), ns)))
        my_pid = ns[0]
    elif tag == "SNAP":
        np = ns[2]; i = 3; ps = []
        for _ in range(np): ps.append(ns[i:i+15]); i += 15
        nm = ns[i]; i += 1; ms = []
        for _ in range(nm): ms.append(ns[i:i+7]); i += 7
        snap_p[:] = ps; snap_m[:] = ms
    elif tag == "EV": evs.append(text)

send(f"HELLO |{name}")
t0 = time.time(); created = False; talked = False; bought = 0; equipped = False
last_move = None
while time.time() - t0 < secs:
    try:
        data = s.recv(65536)
        if not data: print("!! disconnected"); break
        buf += data
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            parse(line.decode(errors="replace"))
    except socket.timeout:
        pass
    if welcome and not created:
        send("CREATE 1 0 2 1 0 0"); created = True; time.sleep(0.2); continue
    if not me or my_pid is None: continue
    mine = next((p for p in snap_p if p[0] == my_pid), None)
    if not mine: continue
    x, y, dead = mine[1], mine[2], mine[14]
    if dead: continue
    if not talked and me.get("mainq", 0) == 0:
        # walk to elder (6,4) then TALK
        tx, ty = 6, 4
        if abs(x - tx) + abs(y - ty) <= 2:
            send("HALT"); last_move = None
            send("TALK 0"); talked = True
        else:
            move_towards(x, y, lambda nx, ny: abs(nx - tx) + abs(ny - ty) <= 2)
        continue
    if me.get("gold", 0) >= 12 and bought < 1:
        # walk to shop (9,4), buy wooden sword, equip it
        tx, ty = 9, 4
        if abs(x - tx) <= 2 and abs(y - ty) <= 2:
            send("HALT"); last_move = None
            send("BUY 1"); bought += 1
        else:
            move_towards(x, y, lambda nx, ny: abs(nx - tx) <= 2 and abs(ny - ty) <= 2)
        continue
    if bought and not equipped:
        send("EQUIP 1"); equipped = True; continue
    if me.get("hp", 99) * 3 < me.get("mhp", 1) and me.get("pots", 0) > 0:
        send("QUAFF"); continue
    # hunt: nearest live mob
    if snap_m:
        m = min(snap_m, key=lambda m: max(abs(m[3]-x), abs(m[4]-y)))
        mx, my_ = m[3], m[4]
        if max(abs(mx-x), abs(my_-y)) <= 1:
            if last_move is not None: send("HALT"); last_move = None
            send("ATK")
            time.sleep(0.15)
        else:
            move_towards(x, y, lambda nx, ny: any(
                max(abs(mob[3] - nx), abs(mob[4] - ny)) <= 1 for mob in snap_m))
    time.sleep(0.06)

send(f"SAY hello from {name}!")
send("FAME")
time.sleep(0.5)
try:
    while True:
        data = s.recv(65536)
        if not data: break
        buf += data
except socket.timeout: pass
for line in buf.split(b"\n"):
    if line[:4] in (b"FAME", b"FRUN"): evs.append(line.decode())

print(f"== bot {name} report ==")
print(f"welcome: {welcome}")
print(f"zone: {zone}, grid_len: {len(grid)}")
print(f"me: {me}")
print(f"players_seen: {len(snap_p)}, mobs_seen: {len(snap_m)}")
print("events:")
for e in evs[-12:]: print("  ", e)
ok = (welcome is not None and len(grid) == 510 and me.get("lv", 0) >= 1
      and me.get("mainq", 0) >= 1 and (me.get("xp", 0) > 0 or me.get("score", 0) > 0 or me.get("kills", 0)))
print("RESULT:", "PASS" if ok else "PARTIAL")

s.close()
sys.exit(0 if ok else 1)
