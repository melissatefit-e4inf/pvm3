#include <stdio.h>
#include <stdlib.h>
#include "pvm3.h"

#include <sys/time.h>
#include <time.h>

#include <errno.h>



#define GRPNAME "gaussp"
#define TAG_LOAD 10
#define TAG_SAVE 11




void matrix_load(char *nom, double *tab,int N, int P, int me, int tids[])
{
    FILE *f;
    int i, j, l;
    int proprietaire;
    int rows = N / P;
    double *ligne;

    if (me == 0) {
        f = fopen(nom, "r");

        if (f == NULL) {
            perror("matrix_load : fopen");
            pvm_exit();
            exit(EXIT_FAILURE);
        }

        ligne = malloc(N * sizeof(double));

        for (i = 0; i < N; i++) {

            /* Lire une ligne */
            for (j = 0; j < N; j++) {
                fscanf(f, "%lf", &ligne[j]);
            }

            proprietaire = i % P;

            if (proprietaire == 0) {

                /* Garder notre ligne */
                l = i / P;

                for (j = 0; j < N; j++) {
                    tab[l * N + j] = ligne[j];
                }

            } else {

                /* Envoyer la ligne a son propriétaire */
                pvm_initsend(PvmDataDefault);
                pvm_pkdouble(ligne, N, 1);
                pvm_send(tids[proprietaire], TAG_LOAD);
            }
        }

        fclose(f);
        free(ligne);

    } else {

        /* Recevoir N/P lignes depuis P0 */
        for (l = 0; l < rows; l++) {
            pvm_recv(tids[0], TAG_LOAD);
            pvm_upkdouble(&tab[l * N], N, 1);
        }
    }
}
  	
  	
  	


void matrix_save(char *nom, double *tab,
                 int N, int P, int me, int tids[])
{
    FILE *f;
    double *ligne;
    int i, j, l, proprietaire;

    if (me == 0) {
        f = fopen(nom, "w");
        if (f == NULL) {
            perror("matrix_save : fopen");
            pvm_exit();
            exit(EXIT_FAILURE);
        }

        ligne = malloc(N * sizeof(double));

        for (i = 0; i < N; i++) {
            proprietaire = i % P;

            if (proprietaire == 0) {
                l = i / P;
                for (j = 0; j < N; j++) {
                    ligne[j] = tab[l * N + j];
                }
            } else {
                pvm_recv(tids[proprietaire], TAG_SAVE);
                pvm_upkdouble(ligne, N, 1);
            }

            for (j = 0; j < N; j++) {
                fprintf(f, "%8.2f ", ligne[j]);
            }
            fprintf(f, "\n");
        }

        fclose(f);
        free(ligne);

    } else {
        for (l = 0; l < N / P; l++) {
            pvm_initsend(PvmDataDefault);
            pvm_pkdouble(&tab[l * N], N, 1);
            pvm_send(tids[0], TAG_SAVE);
        }
    }
}



void dowork(int me, int tids[], int P, int argc, char **argv)
{
    int N;
    double *tab;
    char nom_resultat[1024];
    struct timeval tv1, tv2;
    double duree;

    N = atoi(argv[1]);
    tab = malloc((N / P) * N * sizeof(double));

    /* Chargement */
    gettimeofday(&tv1, NULL);

    matrix_load(argv[2], tab, N, P, me, tids);

    pvm_barrier(GRPNAME, P);
    gettimeofday(&tv2, NULL);

    duree = (tv2.tv_sec - tv1.tv_sec) * 1000000
          + tv2.tv_usec - tv1.tv_usec;

    if (me == 0)
        printf("Loading time: %f sec.\n", duree / 1000000.0);

    /* Calcul de Gauss */
    gettimeofday(&tv1, NULL);

    /* gauss(tab, N, P, me, tids); */

    pvm_barrier(GRPNAME, P);
    gettimeofday(&tv2, NULL);

    duree = (tv2.tv_sec - tv1.tv_sec) * 1000000
          + tv2.tv_usec - tv1.tv_usec;

    if (me == 0)
        printf("Computation time: %f sec.\n", duree / 1000000.0);

    /* Sauvegarde */
    snprintf(nom_resultat, sizeof(nom_resultat),
             "%s.result", argv[2]);

    matrix_save(nom_resultat, tab, N, P, me, tids);

    free(tab);
}



int main(int argc, char **argv)
{
    int P, me, i;
    int *tids;

    pvm_mytid();

    P = pvm_siblings(&tids);
    me = pvm_joingroup(GRPNAME);

    pvm_barrier(GRPNAME, P);
    pvm_freezegroup(GRPNAME, P);

    for (i = 0; i < P; i++) {
        tids[i] = pvm_gettid(GRPNAME, i);
    }

    dowork(me, tids, P, argc, argv);

    pvm_barrier(GRPNAME, P);
    pvm_lvgroup(GRPNAME);
    free(tids);
    pvm_exit();

    return 0;
}

