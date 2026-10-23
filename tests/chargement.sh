#!/bin/bash
# Temps de chargement de gaussp : 3 essais par configuration.
# Variante sans l'appel à gauss() (le chargement est chronométré avant, code identique à gaussp.c).
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; B=/user/safarl/pvm3/bin/LINUX64
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }
echo "### $(date '+%d/%m/%Y %H:%M:%S') — $(uptime)"
cd /user/safarl/pvm3
run "sed 's|^    gauss(tab, N, P, me, tids);|    /* gauss(tab, N, P, me, tids); */|' gaussp.c > /tmp/gaussp_ls.c"
run "grep -n 'gauss(tab' /tmp/gaussp_ls.c"
run "cc -I\$PVM_ROOT/include -I/usr/include/tirpc -o $B/gaussp_ls /tmp/gaussp_ls.c -L\$PVM_ROOT/lib/\$PVM_ARCH -lpvm3 -lgpvm3 -ltirpc -lm"
cd $M
echo "$PS pvm"; printf 'conf\nquit\n' | pvm 2>&1
printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q pvmgs || { printf 'spawn -pc5201l pvmgs\nquit\n' | pvm >/dev/null 2>&1; sleep 2; }
for c in "500 1 2 4" "1000 1 2 4 8" "5000 1 2 4 8"; do
  set -- $c; N=$1; shift
  echo; echo "########## m$N"
  for e in 1 2 3; do
    echo "# essai $e"
    for P in "$@"; do
      echo "$PS pvm"
      $T/pvmrun.py 600 "spawn -$P -> gaussp_ls $N $M/m$N" | grep -v '^pvm> $'
    done
  done
done
echo; run rm -f $B/gaussp_ls /tmp/gaussp_ls.c
echo "### fin $(date '+%H:%M:%S')"
