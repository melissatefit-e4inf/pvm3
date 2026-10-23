#!/bin/bash
# Pour chaque test (m4, m8, m16 ; P = 2, 4) :
#  1. exécution dans un terminal (séquentiel, parallèle, comparaisons) -> terminal.txt + terminal.png
#  2. même lancement tracé dans XPVM -> xpvm_vue_complete.png, xpvm_space_time.png, xpvm_task_output.png
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
T=/user/safarl/pvm3/tests; M=/user/safarl/pvm3/matrices-test; OUT=/user/safarl/captures_xpvm
win() { xwininfo -root -tree | awk '/"xpvm": \("xpvm" "Toplevel"\)/{print $1; exit}'; }
PS='safarl@pc5201l:~/pvm3/matrices-test$'

session() {  # session N P : commandes du test, au format terminal
  N=$1; P=$2; F=m$N
  echo "$PS ./gauss $N $F"; ./gauss $N $F
  echo "$PS cp $F.result $F.seq.result"; cp $F.result $F.seq.result
  if [ -e $F.triangule ]; then
    echo "$PS ../tests/compare.py $F.triangule $F.seq.result $N"; ../tests/compare.py $F.triangule $F.seq.result $N
  fi
  echo "$PS rm -f $F.result"; rm -f $F.result
  echo "$PS pvm"
  $T/pvmrun.py 30 "spawn -$P -> gaussp $N $M/$F" | grep -v '^pvm> $'
  echo "$PS ../tests/compare.py $F.seq.result $F.result $N"; ../tests/compare.py $F.seq.result $F.result $N
}
export -f session; export T M PS

for N in ${NS:-4 8 16}; do for P in ${PL:-2 4}; do
  D=$OUT/m${N}_P$P; mkdir -p $D; cd $M
  # 1. terminal visible + transcript
  FIN=/tmp/cap_term.done; rm -f $FIN
  xterm -title "TEST_m${N}_P$P" -geometry 100x40+40+40 -fa 'DejaVu Sans Mono' -fs 10 -bg white -fg black \
        -e bash -c "cd $M; session $N $P 2>&1 | tee $D/terminal.txt; touch $FIN; sleep 600" &
  XP=$!
  until [ -e $FIN ]; do sleep 0.5; done; sleep 1
  import -window "$(xwininfo -name "TEST_m${N}_P$P" | awk '/Window id/{print $4}')" $D/terminal.png
  kill $XP; rm -f $FIN
  # 2. XPVM : une instance neuve par test (trace vierge, pas de boîte de dialogue)
  TR=/tmp/xpvm.trace.$USER; rm -f $TR
  (cd $M; setsid xpvm > /tmp/xpvm-$USER.out 2>&1 &)
  until echo 'puts [winfo interps]; exit' | wish 2>/dev/null | grep -qw xpvm; do sleep 1; done; sleep 3
  wish $T/xpvm_run.tcl "gaussp $N $M/m$N" $P
  sleep 6
  import -window $(win) $D/xpvm_vue_complete.png
  wish $T/xpvm_zoom.tcl > /dev/null; sleep 2
  import -window $(win) $D/xpvm_space_time.png
  TO=$(wish $T/xpvm_output.tcl)
  import -window $TO $D/xpvm_task_output.png
  cp $TR $D/xpvm.trace
  echo 'catch {send xpvm {fileHandle quit {} {} {}}}; exit' | wish; sleep 2; pkill -x xpvm
  echo "m$N P=$P : $(tail -1 $D/terminal.txt)"
done; done
