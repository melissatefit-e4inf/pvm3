#!/bin/bash
# Test aller-retour chargement / sauvegarde : gaussp SANS l'appel à gauss() doit réécrire
# exactement la matrice d'entrée. Répété pour plusieurs P. Journal au format terminal.
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; B=/user/safarl/pvm3/bin/LINUX64
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }

# cmpm A B : compare deux matrices valeur par valeur (égalité exacte)
cmpm() {
  paste -d' ' <(tr -s ' \n' '\n' < "$1" | grep .) <(tr -s ' \n' '\n' < "$2" | grep .) \
    | awk '$1+0 != $2+0 {d++} END {print NR" valeurs, "d+0" différences"}'
}

echo "### $(date '+%d/%m/%Y %H:%M:%S')"
echo "# Variante de test : gaussp.c avec l'appel à gauss() commenté"
cd /user/safarl/pvm3
run "sed 's|^    gauss(tab, N, P, me, tids);|    /* gauss(tab, N, P, me, tids); */|' gaussp.c > /tmp/gaussp_ls.c"
run "grep -n 'gauss(tab' /tmp/gaussp_ls.c"
run "cc -I\$PVM_ROOT/include -I/usr/include/tirpc -o $B/gaussp_ls /tmp/gaussp_ls.c -L\$PVM_ROOT/lib/\$PVM_ARCH -lpvm3 -lgpvm3 -ltirpc -lm"
cd $M
echo "$PS pvm"; printf 'conf\nquit\n' | pvm 2>&1
printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q pvmgs || { printf 'spawn -pc5201l pvmgs\nquit\n' | pvm >/dev/null 2>&1; sleep 2; }

for c in "4 1 2 4" "8 1 2 4 8" "16 1 2 4 8 16" "500 1 2 4 5 10 20" "1000 1 2 4 8 10 20"; do
  set -- $c; N=$1; shift
  echo; echo "########## m$N"
  for P in "$@"; do
    run rm -f m$N.result
    echo "$PS pvm"
    $T/pvmrun.py 120 "spawn -$P -> gaussp_ls $N $M/m$N" | grep -v '^pvm> $'
    run cmpm m$N m$N.result
  done
done
echo; run rm -f $B/gaussp_ls /tmp/gaussp_ls.c
echo "### fin $(date '+%H:%M:%S')"
