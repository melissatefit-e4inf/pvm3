# Élimination de Gauss parallèle avec PVM

## Contenu

| Fichier / dossier | Rôle |
|---|---|
| `gauss.c` | Version séquentielle (référence) |
| `gaussp.c` | Version parallèle PVM : chargement, calcul, sauvegarde distribués |
| `Makefile` | Compilation PVM, l'exécutable est déplacé dans `~/pvm3/bin/$PVM_ARCH` |
| `matrices-test/` | Matrices de test (`mN` = matrice N×N) |
| `exercices/` | Exercices PVM précédents (`hello`, `tokenring-sibling`) |

## Compiler

```bash
cd ~/pvm3
make gaussp
```

Pour un exercice :

```bash
cd ~/pvm3/exercices
make -f ../Makefile hello
```

## Lancer

```bash
pvm
spawn -4 -> gaussp 16 /home/<login>/pvm3/matrices-test/m16
quit
```

- `-4` : nombre de tâches P (N doit être divisible par P)
- `16` : taille N de la matrice, doit correspondre au fichier
- chemin **absolu** obligatoire : les tâches PVM s'exécutent depuis `$HOME`

Le résultat est écrit à côté de l'entrée : `matrices-test/m16.result`
(ignoré par git, regénéré à chaque exécution).

## Vérifier load/save

Tant que l'appel à `gauss` est commenté, le résultat doit être identique à l'entrée :

```bash
cd ~/pvm3/matrices-test
paste -d' ' <(tr -s ' \n' '\n' < m16 | grep .) <(tr -s ' \n' '\n' < m16.result | grep .) \
  | awk '$1+0 != $2+0 {d++} END {print NR" valeurs, "d+0" différences"}'
```
