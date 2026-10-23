# cmpm A B : compare deux matrices valeur par valeur (égalité exacte)
cmpm() {
  paste -d' ' <(tr -s ' \n' '\n' < "$1" | grep .) <(tr -s ' \n' '\n' < "$2" | grep .) \
    | awk '$1+0 != $2+0 {d++} END {print NR" valeurs, "d+0" différences"}'
}
