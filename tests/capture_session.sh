#!/bin/bash
# capture_session.sh <fichier.png> <fichier_commandes> [colonnes lignes]
# Exécute chaque ligne du fichier dans un vrai xterm (écran virtuel Xvfb), en l'affichant derrière l'invite,
# puis capture la fenêtre.
OUT=$1; CMD=$2; COLS=${3:-150}; ROWS=${4:-70}
DPY=:99; FIN=/tmp/cap_sess.done; rm -f $FIN
Xvfb $DPY -screen 0 1600x1400x24 >/dev/null 2>&1 & XV=$!
sleep 1
cat > /tmp/cap_sess_run.sh <<EOS
. /nfs/opt/pvm/pvm/bashrc.pvmpi 2>/dev/null
cd /user/safarl/pvm3/matrices-test
. /user/safarl/pvm3/tests/cmpm.sh
while IFS= read -r l; do
  echo "safarl@pc5201l:~/pvm3/matrices-test\$ \$l"
  eval "\$l"
done < $CMD
touch $FIN
sleep 600
EOS
DISPLAY=$DPY xterm -title CAPSESS -geometry ${COLS}x${ROWS}+0+0 -fa 'DejaVu Sans Mono' -fs 8 -bg white -fg black \
      -e bash /tmp/cap_sess_run.sh & XP=$!
for i in $(seq 1 240); do [ -e $FIN ] && break; sleep 0.5; done; sleep 1
W=$(DISPLAY=$DPY xwininfo -name CAPSESS | awk '/Window id/{print $4; exit}')
import -display $DPY -window "$W" "$OUT" && echo "capture : $OUT"
kill $XP $XV; rm -f $FIN /tmp/cap_sess_run.sh
