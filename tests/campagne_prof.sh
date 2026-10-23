#!/bin/bash
# Campagne complète sur les matrices du prof (matrices-test/).
# Chaque journal reproduit la session terminal : invite, commande exacte, sortie brute.
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests
M=/user/safarl/pvm3/matrices-test
cd $M
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }
spawn() {  # spawn P N matrice [timeout]
  echo "$PS pvm"
  $T/pvmrun.py ${4:-900} "spawn -$1 -> gaussp $2 $M/$3" | grep -v '^pvm> $'
}

# ---------- 1. Validation ----------
validation() {
  echo "### $(date '+%d/%m/%Y %H:%M:%S') — $(uptime)"
  for cas in "4 m4 1 2 4" "16 m16 1 2 4 8" "500 m500 2 4 10" "1000 m1000 4 8"; do
    set -- $cas; N=$1; F=$2; shift 2
    echo; echo "########## $F (N=$N) ##########"
    run ./gauss $N $F
    run cp $F.result $F.seq.result
    [ -e $F.triangule ] && run ../tests/compare.py $F.triangule $F.seq.result $N
    for P in "$@"; do
      run rm -f $F.result
      spawn $P $N $F
      run ../tests/compare.py $F.seq.result $F.result $N
    done
  done
}

# ---------- 2. Performances ----------
mesure() {  # mesure N repetitions P...
  N=$1; R=$2; shift 2
  echo; echo "########## N=$N — $(date '+%H:%M:%S') — $(uptime)"
  for e in $(seq 1 $R); do
    echo "# essai $e"
    [ "$N" != 10000 ] && run ./gauss $N m$N
    for P in "$@"; do
      (( N % P )) && continue
      spawn $P $N m$N 3600
    done
  done
}
perf() {
  mesure 500 5 1 2 4 10 20
  mesure 1000 5 1 2 4 8 10 20
  mesure 5000 1 4 10 20
  run ../tests/compare.py m5000.seq.result m5000.result 5000
  mesure 10000 1 4 10 20
  run ../tests/compare.py m10000.seq.result m10000.result 10000
}

case $1 in
  validation) validation > $T/logs/validation.log 2>&1 ;;
  perf)       perf       > $T/logs/perf.log 2>&1 ;;
esac
# Reprise de l'essai N=10000, P=20 (interrompu par un lancement manuel simultané)
if [ "$1" = reprise10000 ]; then
  { spawn 20 10000 m10000 3600; run ../tests/compare.py m10000.seq.result m10000.result 10000; } >> $T/logs/perf.log 2>&1
fi
