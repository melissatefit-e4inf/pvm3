#!/bin/bash
# A) Temps de sauvegarde (variantes temporaires chronométrant matrix_save, sans calcul) + affichage du résultat.
# B) Test de Gauss : vrai gaussp, affichage de la matrice triangulaire, quantification.
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; B=/user/safarl/pvm3/bin/LINUX64
OUT=/user/safarl/captures_sauvegarde_gauss; mkdir -p $OUT
PS='safarl@pc5201l:~/pvm3/matrices-test$'
run() { echo "$PS $*"; eval "$@"; }
. /user/safarl/pvm3/tests/cmpm.sh
CC="cc -I$PVM_ROOT/include -I/usr/include/tirpc"; LD="-L$PVM_ROOT/lib/$PVM_ARCH -lpvm3 -lgpvm3 -ltirpc -lm"
printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q pvmgs || { printf 'spawn -pc5201l pvmgs\nquit\n' | pvm >/dev/null 2>&1; sleep 2; }

# ---------- variantes temporaires ----------
cd /user/safarl/pvm3
sed -e 's|^    gauss(tab, N, P, me, tids);|    /* gauss(tab, N, P, me, tids); */|' \
    -e 's|^    matrix_save(nom_resultat, tab, N, P, me, tids);|    gettimeofday(\&tv1, NULL);\n    matrix_save(nom_resultat, tab, N, P, me, tids);\n    gettimeofday(\&tv2, NULL);\n    if (me == 0) printf("Saving time: %f sec.\\n", ((tv2.tv_sec - tv1.tv_sec) * 1000000 + tv2.tv_usec - tv1.tv_usec) / 1000000.0);|' \
    gaussp.c > /tmp/gaussp_save.c
sed -e 's|^      gauss ( tab, N );|      /* gauss ( tab, N ); */|' \
    -e 's|^  matrix_save ( nom, tab, N );|  gettimeofday( \&tv1, (struct timezone*)0 );\n  matrix_save ( nom, tab, N );\n  gettimeofday( \&tv2, (struct timezone*)0 );\n  duree = (tv2.tv_sec - tv1.tv_sec) * 1000000 + tv2.tv_usec - tv1.tv_usec;\n  printf ("saving time: %10.8f sec.\\n", duree/1000000.0 );|' \
    gauss.c > /tmp/gauss_save.c
$CC -o $B/gaussp_save /tmp/gaussp_save.c $LD && cc -o $M/gauss_save /tmp/gauss_save.c -lm || exit 1

{
echo "### Temps de sauvegarde — $(date '+%d/%m/%Y %H:%M:%S') — $(uptime)"
echo "# variantes : gaussp.c et gauss.c sans l'appel à gauss, avec chronométrage de matrix_save"
run "grep -n -A3 'gettimeofday(&tv1, NULL);' /tmp/gaussp_save.c | grep -A3 save"
run "grep -n -B1 -A1 'matrix_save ( nom' /tmp/gauss_save.c"
cd $M
for c in "500 1 2 4" "1000 1 2 4 8" "5000 1 2 4 8"; do
  set -- $c; N=$1; shift
  echo; echo "########## m$N"
  for e in 1 2 3; do
    echo "# essai $e"
    run ./gauss_save $N m$N
    for P in "$@"; do echo "$PS pvm"; $T/pvmrun.py 600 "spawn -$P -> gaussp_save $N $M/m$N" | grep -v '^pvm> $'; done
  done
  run cmpm m$N m$N.result
done
} > $T/logs/sauvegarde.log 2>&1 < /dev/null
cd $M; . $T/cmpm.sh

# capture : sauvegarde de m16 avec P=4, matrice résultat affichée
cat > /tmp/cmdA <<EOC
grep -n -A3 'gettimeofday(&tv1, NULL);' /tmp/gaussp_save.c | grep -A3 save
rm -f m16.result
../tests/pvmrun.py 60 "spawn -4 -> gaussp_save 16 \$PWD/m16" | grep -v '^pvm> \$'
echo "===== matrice d'origine : m16"; cat m16
echo "===== matrice sauvegardée : m16.result"; cat m16.result
cmpm m16 m16.result
EOC
$T/capture_session.sh $OUT/sauvegarde_m16_P4.png /tmp/cmdA 150 85

# ---------- B) test de Gauss ----------
{
echo "### Test de Gauss — $(date '+%d/%m/%Y %H:%M:%S')"
for c in "4 2" "8 4" "16 4" "500 4" "1000 4" "5000 4"; do
  set -- $c; N=$1; P=$2
  echo; echo "########## m$N, P=$P"
  run rm -f m$N.result
  echo "$PS pvm"; $T/pvmrun.py 600 "spawn -$P -> gaussp $N $M/m$N" | grep -v '^pvm> $'
  run ../tests/quantif.py m$N.result $N m$N.seq.result
  [ -e m$N.triangule ] && run ../tests/quantif.py m$N.result $N m$N.triangule
done
} > $T/logs/gauss_resultats.log 2>&1 < /dev/null

for c in "4 2" "8 4" "16 4"; do
  set -- $c; N=$1; P=$2
  { echo "rm -f m$N.result"
    echo "../tests/pvmrun.py 60 \"spawn -$P -> gaussp $N \$PWD/m$N\" | grep -v '^pvm> \$'"
    echo "echo \"===== matrice d'origine : m$N\"; cat m$N"
    echo "echo \"===== matrice résultat (triangulaire) : m$N.result\"; cat m$N.result"
    echo "../tests/quantif.py m$N.result $N m$N.seq.result"
    [ -e $M/m$N.triangule ] && echo "../tests/quantif.py m$N.result $N m$N.triangule"; } > /tmp/cmdB
  $T/capture_session.sh $OUT/gauss_m${N}_P$P.png /tmp/cmdB 150 85
done
echo "grep -E '^#####|spawn -|Loading|Computation|valeurs=' tests/logs/gauss_resultats.log" > /tmp/cmdC
$T/capture_log.sh $OUT/gauss_quantification_toutes_tailles.png /tmp/cmdC
echo "grep -E '^#####|^# essai|gauss_save [0-9]|spawn -|[Ss]aving time|différences' tests/logs/sauvegarde.log" > /tmp/cmdD
$T/capture_log.sh $OUT/sauvegarde_toutes_mesures.png /tmp/cmdD

rm -f $B/gaussp_save $M/gauss_save /tmp/gaussp_save.c /tmp/gauss_save.c /tmp/cmdA /tmp/cmdB /tmp/cmdC /tmp/cmdD
cp $T/logs/sauvegarde.log $T/logs/gauss_resultats.log $OUT/
