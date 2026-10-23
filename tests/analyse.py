#!/usr/bin/env python3
"""Relit logs/perf.log et produit les mesures brutes, les médianes, S(P) et E(P)."""
import re, statistics, csv, sys, os
from collections import defaultdict

log = sys.argv[1] if len(sys.argv) > 1 else "logs/perf.log"
rep = os.path.dirname(log)
mes = defaultdict(list)          # (N, version) -> [(chargement, calcul)]
cur, chg = None, None
for l in open(log):
    if m := re.search(r"\$ \./gauss (\d+) ", l):
        cur = (int(m[1]), "seq")
    elif m := re.search(r"pvm> spawn -(\d+) -> \S+ (\d+) ", l):
        cur = (int(m[2]), f"P={m[1]}")
    elif m := re.search(r"[Ll]oading time:\s+([\d.]+)", l):
        chg = float(m[1])
    elif m := re.search(r"[Cc]omputation time:\s+([\d.]+)", l):
        mes[cur].append((chg, float(m[1])))

def cle(v): return 0 if v == "seq" else int(v[2:])
with open(os.path.join(rep, "mesures_brutes.csv"), "w", newline="") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["N", "version", "essai", "chargement_s", "calcul_s"])
    for (n, v) in sorted(mes, key=lambda k: (k[0], cle(k[1]))):
        for i, (c, t) in enumerate(mes[(n, v)], 1):
            w.writerow([n, v, i, c, t])
with open(os.path.join(rep, "synthese.csv"), "w", newline="") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["N", "version", "nb_essais", "chargement_median_s", "calcul_median_s",
                "calcul_min_s", "calcul_max_s", "acceleration", "efficacite_pct"])
    for n in sorted({k[0] for k in mes}):
        tseq = statistics.median(t for _, t in mes[(n, "seq")]) if (n, "seq") in mes else None
        for v in sorted({k[1] for k in mes if k[0] == n}, key=cle):
            ts = [t for _, t in mes[(n, v)]]
            tm = statistics.median(ts)
            s = tseq / tm if tseq else None
            p = 1 if v == "seq" else cle(v)
            row = [n, v, len(ts), f"{statistics.median(c for c, _ in mes[(n, v)]):.4f}",
                   f"{tm:.4f}", f"{min(ts):.4f}", f"{max(ts):.4f}",
                   "" if v == "seq" or s is None else f"{s:.2f}", "" if v == "seq" or s is None else f"{100*s/p:.0f}"]
            w.writerow(row)
            print(";".join(map(str, row)))
