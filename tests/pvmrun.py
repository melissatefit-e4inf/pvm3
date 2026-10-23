#!/usr/bin/env python3
"""Lance une commande dans la console PVM et rend la sortie brute.

Usage : pvmrun.py <timeout_s> "spawn -4 -> gaussp ..." [commande console ...]
La console reste ouverte jusqu'à « [n] finished » ou jusqu'au timeout.
"""
import subprocess, sys, time, select, os, re

timeout = float(sys.argv[1])
cmds = sys.argv[2:]
# Essais sautés pour raccourcir une campagne : une commande par ligne dans ce fichier
SAUT = "/user/safarl/pvm3/tests/essais_sautes.txt"
if os.path.exists(SAUT) and any(c.strip() in open(SAUT).read().splitlines() for c in cmds):
    print(f"# essai non lancé (sauté pour raccourcir la campagne) : {' ; '.join(cmds)}")
    sys.exit(0)
p = subprocess.Popen(["pvm"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT, text=True, bufsize=1)
fd = p.stdout.fileno()

def lire(attente):
    """Lit ce qui est disponible sur la sortie de la console (sans tampon Python)."""
    if select.select([fd], [], [], attente)[0]:
        return os.read(fd, 65536).decode(errors="replace")
    return None

for c in cmds:
    p.stdin.write(c + "\n"); p.stdin.flush()
out, t0 = [], time.time()
fin = False
while time.time() - t0 < timeout and not fin:
    data = lire(0.2)
    if data is None:
        # la console (readline) ne traite les messages des tâches qu'à la saisie d'une ligne
        p.stdin.write("\n"); p.stdin.flush()
    if data == "":
        break
    if data:
        out.append(data)
        fin = re.search(r"\[\d+\] finished", "".join(out)) is not None
if not fin:
    out.append(f"### TIMEOUT {timeout:.0f}s : job non terminé\n")
    p.stdin.write("ps -a\n"); p.stdin.flush()
    while (data := lire(1.0)):
        out.append(data)
p.stdin.write("quit\n"); p.stdin.flush()
while (data := lire(2.0)):
    out.append(data)
p.wait(timeout=10)
sys.stdout.write("".join(out))
sys.exit(0 if fin else 2)
