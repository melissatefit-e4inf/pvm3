#!/usr/bin/env python3
"""Compare deux fichiers .result ligne par ligne (référence / parallèle).

Usage : compare.py <reference> <resultat> <N>
Affiche : nb valeurs, nb différences > tol, écart max, max |a_ij| sous la diagonale (fichier 2).
"""
import sys, math

ref, res, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
tol = 0.011
na = nb = ndiff = 0
emax = sous = 0.0
finis = True
with open(ref) as fa, open(res) as fb:
    i = 0
    for la, lb in zip(fa, fb):
        va = [float(x) for x in la.split()]
        vb = [float(x) for x in lb.split()]
        na += len(va); nb += len(vb)
        finis = finis and all(math.isfinite(x) for x in va + vb)
        for x, y in zip(va, vb):
            d = abs(x - y)
            if d > emax: emax = d
            ndiff += d > tol
        if i > 0:
            sous = max(sous, max(abs(x) for x in vb[:i]))
        i += 1
    # lignes en trop dans l'un des fichiers
    na += sum(len(l.split()) for l in fa)
    nb += sum(len(l.split()) for l in fb)
ok = na == nb == n * n and ndiff == 0 and finis
print(f"valeurs={na}/{nb} attendu={n*n} diff>{tol}={ndiff} ecart_max={emax:.4f} "
      f"max_sous_diag={sous:.4f} finies={finis} -> {'OK' if ok else 'ECHEC'}")
