#!/bin/bash
# Mesures du séquentiel gauss sur pc5201l, au format terminal (invite, commande, sortie).
M=/user/safarl/pvm3/matrices-test; cd $M
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }
echo "### $(date '+%d/%m/%Y %H:%M:%S') — $(uptime)"
for c in "500 5" "1000 5" "5000 3" "10000 1"; do
  set -- $c
  echo; echo "########## N=$1 — $2 essai(s)"
  for e in $(seq 1 $2); do echo "# essai $e"; run ./gauss $1 m$1; done
  run cp m$1.result m$1.seq.result
  [ -e m$1.triangule ] && run ../tests/compare.py m$1.triangule m$1.seq.result $1
done
echo "### fin $(date '+%H:%M:%S')"
