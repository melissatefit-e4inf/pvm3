#!/bin/bash
# Cas d'erreur : un dossier par cas dans ~/captures_erreurs/ (terminal.txt + terminal.png).
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; OUT=/user/safarl/captures_erreurs
PS='safarl@pc5201l:~/pvm3/matrices-test$'
export T M PS

session() {  # session P "arguments gaussp" fichier_resultat "arguments gauss"
  P=$1; A=$2; R=$3; S=$4
  # le serveur de groupes est tué par reset : on le relance avant le test (évite une course au démarrage)
  printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q pvmgs || { printf 'spawn -pc5201l pvmgs\nquit\n' | pvm >/dev/null 2>&1; sleep 2; }
  [ -n "$R" ] && { echo "$PS rm -f $R"; rm -f $R; }
  echo "$PS pvm"
  $T/pvmrun.py 15 "spawn -$P -> gaussp $A" | grep -v '^pvm> $' | sed 's/^### TIMEOUT 15s.*/### (aucun « finished » après 15 s : tâches bloquées)/'
  echo "$PS pvm"
  printf 'ps -a\nreset\nquit\n' | pvm 2>&1
  # reset est asynchrone sur les hôtes distants : on attend la disparition des tâches
  for i in $(seq 1 15); do printf 'ps -a\nquit\n' | pvm 2>&1 | grep -q ' gaussp' || break; sleep 1; done
  echo "$PS pvm"
  printf 'ps -a\nquit\n' | pvm 2>&1
  if [ -n "$R" ]; then echo "$PS ls -l $R"; ls -l $R 2>&1; fi
  if [ -n "$R" ] && [ -s "$R" ]; then echo "$PS cat $R"; cat $R; fi
  echo "$PS ./gauss $S        # référence séquentielle"
  timeout 10 ./gauss $S; echo "(code retour $?)"
}
export -f session

mkdir -p $M/lecture-seule && cp $M/m4 $M/lecture-seule/ && chmod 555 $M/lecture-seule
i=0
while IFS='|' read -r nom P A R S; do
  i=$((i+1)); D=$OUT/$(printf %02d $i)_$nom; mkdir -p $D
  FIN=/tmp/cap_err.done; rm -f $FIN
  xterm -title "ERR_$nom" -geometry 100x50+40+20 -fa 'DejaVu Sans Mono' -fs 9 -bg white -fg black \
        -e bash -c "cd $M; session '$P' '$A' '$R' '$S' 2>&1 | tee $D/terminal.txt; touch $FIN; sleep 600" &
  XP=$!
  until [ -e $FIN ]; do sleep 0.5; done; sleep 1
  import -window "$(xwininfo -name "ERR_$nom" | awk '/Window id/{print $4}')" $D/terminal.png
  kill $XP; rm -f $FIN
  echo "$nom : fait"
done <<LISTE
fichier_inexistant|4|4 $M/m4-absent|m4-absent.result|4 m4-absent
fichier_incomplet|2|4 $M/erreurs/m4-tronquee|erreurs/m4-tronquee.result|4 erreurs/m4-tronquee
coefficient_non_numerique|2|4 $M/erreurs/m4-non-numerique|erreurs/m4-non-numerique.result|4 erreurs/m4-non-numerique
pivot_nul_depart|2|4 $M/erreurs/m4-pivot-nul|erreurs/m4-pivot-nul.result|4 erreurs/m4-pivot-nul
pivot_nul_calcul|2|4 $M/erreurs/m4-pivot-nul-calcul|erreurs/m4-pivot-nul-calcul.result|4 erreurs/m4-pivot-nul-calcul
N_non_divisible_par_P|4|6 $M/erreurs/m6|erreurs/m6.result|6 erreurs/m6
N_nul|2|0 $M/m4|m4.result|0 m4
N_negatif|2|-4 $M/m4|m4.result|-4 m4
arguments_manquants|2|||
sortie_non_inscriptible|2|4 $M/lecture-seule/m4|lecture-seule/m4.result|4 lecture-seule/m4
LISTE
chmod u+w $M/lecture-seule; rm -rf $M/lecture-seule
