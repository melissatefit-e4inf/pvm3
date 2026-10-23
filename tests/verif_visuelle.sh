#!/bin/bash
# 1) Aller-retour chargement/sauvegarde avec affichage des matrices d'origine et résultat.
# 2) Distribution : chaque tâche affiche les lignes reçues (matrice où la ligne i ne contient que i).
# Variantes temporaires de gaussp.c (gaussp.c n'est pas modifié), supprimées à la fin.
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; B=/user/safarl/pvm3/bin/LINUX64; OUT=/user/safarl/captures_load_save
TM=$T/tmp_mat; mkdir -p $TM $OUT
CC="cc -I$PVM_ROOT/include -I/usr/include/tirpc"; LD="-L$PVM_ROOT/lib/$PVM_ARCH -lpvm3 -lgpvm3 -ltirpc -lm"

# variante aller-retour : appel à gauss() commenté
sed 's|^    gauss(tab, N, P, me, tids);|    /* gauss(tab, N, P, me, tids); */|' /user/safarl/pvm3/gaussp.c > $TM/gaussp_ls.c
# variante distribution : idem + chaque tâche affiche ses lignes après le chargement
sed '/^    matrix_load(argv\[2\], tab, N, P, me, tids);/a\
    { int l_, j_, ok_; for (l_ = 0; l_ < N / P; l_++) { ok_ = 1;\
        for (j_ = 1; j_ < N; j_++) if (tab[l_ * N + j_] != tab[l_ * N]) ok_ = 0;\
        printf("tache %d : ligne locale %d -> ligne %g de la matrice (attendu %d)%s\\n",\
               me, l_, tab[l_ * N], l_ * P + me, ok_ ? "" : " LIGNE MELANGEE"); } }' $TM/gaussp_ls.c > $TM/gaussp_dist.c
$CC -o $B/gaussp_ls $TM/gaussp_ls.c $LD && $CC -o $B/gaussp_dist $TM/gaussp_dist.c $LD || exit 1

# matrices de distribution : la ligne i ne contient que la valeur i
for n in 8 16; do awk -v n=$n 'BEGIN{for(i=0;i<n;i++){for(j=0;j<n;j++) printf "%8.2f ", i; print ""}}' > $TM/m$n-lignes; done

# --- 1) aller-retour avec affichage des matrices ---
for c in "4 2" "8 4" "16 8"; do
  set -- $c; N=$1; P=$2
  cat > $TM/cmd <<EOC
grep -n 'gauss(tab' ../tests/tmp_mat/gaussp_ls.c
rm -f m$N.result
../tests/pvmrun.py 60 "spawn -$P -> gaussp_ls $N \$PWD/m$N" | grep -v '^pvm> \$'
echo "===== matrice d'origine : m$N"; cat m$N
echo "===== matrice résultat : m$N.result"; cat m$N.result
cmpm m$N m$N.result
EOC
  $T/capture_session.sh $OUT/aller_retour_m${N}_P$P.png $TM/cmd 150 85
done

# --- 2) distribution des lignes ---
for c in "8 4" "16 8" "16 4"; do
  set -- $c; N=$1; P=$2
  cat > $TM/cmd <<EOC
cat ../tests/tmp_mat/m$N-lignes
../tests/pvmrun.py 60 "spawn -$P -> gaussp_dist $N /user/safarl/pvm3/tests/tmp_mat/m$N-lignes" | grep -v '^pvm> \$' | tee /tmp/dist.txt
grep -o 'tache .*' /tmp/dist.txt | sort -k2,2n -k6,6n
grep -o 'tache .*' /tmp/dist.txt | awk '{n++; v=\$9; a=\$14; sub(/\)/,"",a); if (v!=a || /MELANGEE/) e++} END {print n" lignes vérifiées, "e+0" erreurs de distribution"}'
cmpm ../tests/tmp_mat/m$N-lignes ../tests/tmp_mat/m$N-lignes.result
EOC
  $T/capture_session.sh $OUT/distribution_m${N}_P$P.png $TM/cmd 150 92
done

rm -rf $TM $B/gaussp_ls $B/gaussp_dist /tmp/dist.txt
