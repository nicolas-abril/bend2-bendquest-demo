#!/usr/bin/env python3
# dev tool: fix "NotBound ... defined later in the file" by moving the
# named def above its first textual user, repeatedly, until the checker
# stops complaining about ordering.
import re, subprocess, sys

path = sys.argv[1]
for attempt in range(60):
    out = subprocess.run(
        ["bun", "../../bend-ts/bend.ts", path],
        capture_output=True, text=True).stdout + subprocess.run(
        ["bun", "../../bend-ts/bend.ts", path],
        capture_output=True, text=True).stderr
    m = re.search(r"NotBound:\n- name : (\w+)\n- hint : defined later", out)
    if not m:
        print(out[:1200] if out.strip() else "CLEAN")
        break
    name = m.group(1)
    src = open(path).read()
    # find the def block for `name`
    dm = re.search(rf"(?:^|\n)((?:#[^\n]*\n)*def {name}\(.*?)(?=\n(?:#[^\n]*\n)*def |\n(?:#[^\n]*\n)*type |\Z)", src, re.S)
    if not dm:
        print(f"cannot find def {name}"); print(out[:800]); break
    block = dm.group(1)
    src2 = src.replace(block, "\n", 1)
    use = re.search(rf"[^\w]{name}[ (<]", src2)
    if not use:
        print(f"no use found for {name}"); break
    upto = src2[:use.start()]
    anchor = max(upto.rfind("\ndef "), upto.rfind("\ntype "))
    if anchor < 0:
        print(f"no anchor for {name}"); break
    src3 = src2[:anchor+1] + block.strip("\n") + "\n\n" + src2[anchor+1:]
    open(path, "w").write(src3)
    print(f"moved {name} up (pass {attempt})")
