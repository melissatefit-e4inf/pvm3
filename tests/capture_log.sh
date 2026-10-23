#!/bin/bash
# capture_log.sh <fichier.png> <fichier_commande> : exécute la commande (contenu du fichier) dans un vrai xterm
# sur un écran virtuel Xvfb, puis capture la fenêtre. (Sous Wayland, la capture du bureau réel n'est pas fiable.)
OUT=$1; CMD=$2
DPY=:99
FIN=/tmp/cap_log.done; rm -f $FIN
Xvfb $DPY -screen 0 1000x1100x24 >/dev/null 2>&1 &
XV=$!
sleep 1
DISPLAY=$DPY xterm -title "CAPLOG" -geometry 120x66+0+0 -fa 'DejaVu Sans Mono' -fs 8 -bg white -fg black \
      -e bash -c "cd /user/safarl/pvm3; echo \"safarl@pc5201l:~/pvm3\$ \$(cat $CMD)\"; bash $CMD; touch $FIN; sleep 600" &
XP=$!
for i in $(seq 1 60); do [ -e $FIN ] && break; sleep 0.5; done; sleep 1
W=$(DISPLAY=$DPY xwininfo -name CAPLOG | awk '/Window id/{print $4; exit}')
import -display $DPY -window "$W" "$OUT" && echo "capture : $OUT"
kill $XP $XV; rm -f $FIN
