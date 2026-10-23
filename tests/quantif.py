#!/usr/bin/env python3
"""Quantifie une matrice résultat de Gauss : forme triangulaire, pivots, écart à une référence.
Usage : quantif.py <resultat> <N> [reference]"""
import sys
res, n = sys.argv[1], int(sys.argv[2]); ref = sys.argv[3] if len(sys.argv) > 3 else None
nv = sous = zeros = 0; maxsous = 0.0; pivmin = float("inf"); ecart = 0.0; ndiff = 0
fr = open(ref) if ref else None
for i, l in enumerate(open(res)):
    v = [float(x) for x in l.split()]; nv += len(v)
    for x in v[:i]:
        sous += 1; zeros += (x == 0.0); maxsous = max(maxsous, abs(x))
    pivmin = min(pivmin, abs(v[i]))
    if fr:
        r = [float(x) for x in fr.readline().split()]
        for a, b in zip(v, r):
            d = abs(a - b); ecart = max(ecart, d); ndiff += d > 0.011
print(f"valeurs={nv}/{n*n} | sous la diagonale : {zeros}/{sous} nulles, max |a_ij|={maxsous:.2f} "
      f"| plus petit pivot |a_kk|={pivmin:.2f}" + (f" | vs {ref.split('/')[-1]} : {ndiff} écarts > 0.011, écart max={ecart:.2f}" if ref else ""))
