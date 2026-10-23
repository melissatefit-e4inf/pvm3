#!/bin/bash
# Speedup / efficacité en fonction du nombre de machines (4, 2, 1).
# Série A : 1 tâche par machine (P = H) ; série B : 5 tâches par machine (P = 5H).
# Journal au format terminal : invite, commande exacte, sortie brute.
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; cd $M
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }
console() { echo "$PS pvm"; printf "$1quit\n" | pvm 2>&1; }
pvmgs_ok() { printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q pvmgs || { printf 'spawn -pc5201l pvmgs\nquit\n' | pvm >/dev/null 2>&1; sleep 2; }; }
spawn() {  # spawn P N
  pvmgs_ok
  echo "$PS pvm"
  $T/pvmrun.py 3600 "spawn -$1 -> gaussp $2 $M/m$2" | grep -v '^pvm> $'
}

# attendre la fin du séquentiel
while pgrep -f sequentiel.sh > /dev/null; do sleep 10; done

retirer() {  # retirer hôte... : enlève des hôtes de la machine virtuelle
  for h in "$@"; do console "delete $h\n"; done
}

serie() {  # serie H
  H=$1
  echo; echo "################## $H machine(s) — $(date '+%H:%M:%S') ##################"
  console "conf\n"
  for c in "500 3" "1000 3" "5000 1" "10000 1"; do
    set -- $c; N=$1; R=$2
    echo; echo "########## H=$H N=$N"
    for e in $(seq 1 $R); do
      echo "# essai $e"
      for P in $H $((5*H)); do
        if [ $N = 10000 ] && [ $P = 1 ]; then echo "# P=1 sur 1 machine pour N=10000 non relancé (équivalent au séquentiel)"; continue; fi
        spawn $P $N
      done
    done
    run ../tests/compare.py m$N.seq.result m$N.result $N
  done
}

echo "### début $(date '+%d/%m/%Y %H:%M:%S')"
retirer pc5201e
serie 4
retirer pc5201b pc5201c
serie 2
retirer pc5201a
serie 1
console "conf\n"
echo "### fin $(date '+%H:%M:%S')"
