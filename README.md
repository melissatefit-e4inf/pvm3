# Élimination de Gauss parallèle avec PVM

## Contenu

| Fichier / dossier | Rôle |
|---|---|
| `gauss.c` | Version séquentielle (référence) |
| `gaussp.c` | Version parallèle PVM : chargement, calcul, sauvegarde distribués |
| `Makefile` | Compilation PVM, l'exécutable est déplacé dans `~/pvm3/bin/$PVM_ARCH` |
| `hello.c`, `tokenring-sibling.c` | Exercices PVM précédents |
| `matrices-test/` | Matrices fournies (`mN` = matrice N×N) et résultats de référence `*.triangule` |
| `matrices-test/erreurs/` | Matrices pour les cas d'erreur |
| `tests/` | Scripts de test, journaux, captures et rapport (voir plus bas) |

`m4`, `m16`, `m500`, `m1000` et les `.triangule` sont les fichiers fournis
(`/nfs/opt/pvm/pvm3/`). `m8` n'est pas fournie, c'est la nôtre.
`m5000` et `m10000` sont trop lourdes pour GitHub : les copier ou les lier depuis
`/nfs/opt/pvm/pvm3/` (elles sont ignorées par git).

## Compiler

```bash
cd ~/pvm3
make gaussp
make gauss
```

## Lancer

```bash
pvm
spawn -4 -> gaussp 16 /user/<login>/pvm3/matrices-test/m16
quit
```

- `-4` : nombre de tâches P (N doit être divisible par P)
- `16` : taille N de la matrice, doit correspondre au fichier
- chemin **absolu** obligatoire : les tâches PVM s'exécutent depuis `$HOME`
- la console n'affiche la sortie des tâches qu'après une saisie : appuyer sur Entrée
- ne jamais lancer deux `gaussp` en même temps (même groupe PVM `"gaussp"`)

Le résultat est écrit à côté de l'entrée : `matrices-test/m16.result`
(ignoré par git, regénéré à chaque exécution).

## Vérifier un résultat

```bash
cd ~/pvm3/matrices-test
./gauss 16 m16 && cp m16.result m16.seq.result      # référence séquentielle
# ... lancer gaussp, puis :
../tests/compare.py m16.seq.result m16.result 16    # écarts avec le séquentiel
../tests/quantif.py m16.result 16 m16.triangule     # forme triangulaire + écart à la référence
```

Comparaison valeur par valeur de deux matrices (`cmpm`) :

```bash
. ~/pvm3/tests/cmpm.sh
cmpm m16 m16.result
```

## Tests (23/10/2026)

Rapport : `tests/rapport_tests.pdf` (source `tests/rapport_tests.typ`, figures dans `tests/figures/`).
Les journaux (`tests/logs/`) reproduisent chaque commande et sa sortie exacte ;
les captures sont dans `tests/captures/`.

| Test | Script | Journaux / captures |
|---|---|---|
| Validation séquentiel / parallèle | `campagne_prof.sh validation` | `logs/validation.log` |
| Performances sur une machine | `campagne_prof.sh perf` | `logs/perf.log` |
| Séquentiel de référence | `sequentiel.sh` | `logs/sequentiel.log` |
| Speedup selon le nombre de machines | `machines.sh` | `logs/machines.log`, `captures/machines/` |
| XPVM, m4/m8/m16 avec P = 2 et 4 | `xpvm_tests.sh` | `captures/xpvm/` |
| Aller-retour chargement / sauvegarde | `load_save.sh` | `logs/load_save.log`, `captures/load_save/` |
| Distribution des lignes | `verif_visuelle.sh` | `captures/load_save/` |
| Temps de chargement | `chargement.sh` | `logs/chargement.log`, `captures/chargement/` |
| Temps de sauvegarde, matrices triangulaires | `sauvegarde_gauss.sh` | `captures/sauvegarde_gauss/` |
| Cas d'erreur | `erreurs_captures.sh` | `captures/erreurs/` |

Les tests qui demandent une variante de `gaussp.c` (sans calcul, avec affichage
ou chronométrage) la créent dans un fichier temporaire et la suppriment à la fin :
`gaussp.c` n'est jamais modifié. Les scripts utilisent des chemins absolus
(`/user/safarl/pvm3`) et `tests/pvmrun.py` pour piloter la console PVM.
`tests/ancien_matrices_perso/` contient la première campagne, faite sur nos
propres matrices.
