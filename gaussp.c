#include <stdio.h>
#include <stdlib.h>
#include "pvm3.h"

#include <sys/time.h>
#include <time.h>

#include <errno.h>
#include <math.h>



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

void gauss(double *tab, int N, int P, int me, int tids[]) {
  int i,j,k,x;
  double pivot;
  double *ligne_pivot;
  ligne_pivot = malloc(N * sizeof(double));

  for (k=0; k<N-1; k++){ /* mise a 0 de la col. k */
    /* printf (". "); */
    

    if (me == k % P)
    {
      if ( fabs(*(tab + k + (k/P)*N)) <= 1.0e-11 ){
      printf ("ATTENTION: pivot %d presque nul: %g\n", k, *(tab+k+(k/P)*N) );
      exit (-1);
      }

      pvm_initsend(PvmDataDefault);
      pvm_pkdouble(&tab[(k/P)*N], N, 1);// k*P + me car la 3 ieme ligne du processus 2 sur 4 c'est en realité la ligne 3*4+2 de la matrice
      for (x=0; x<P; x++)
      {
        if(x!=me) 
        {
          pvm_send(tids[x], TAG_SAVE);
        }
        else
        {
          for (j=0; j<N; j++){
            ligne_pivot[j] = tab[(k/P)*N+j];
          }
        }
      }
    }
    else
    {
      pvm_recv(tids[k%P], TAG_SAVE);
      pvm_upkdouble(ligne_pivot, N, 1);
    }


    //le cas ou on fait l'opperation sur les lignes du meme bloc (appartient à chaqune à un procesus different) dans ce cas la il faut regarder si dans la matrice complete est que la ligne est endessous ou audessu 
    if(me > k%P)
    {
      pivot = - *(tab + k + (k/P)*N) / *(ligne_pivot + k);

        for ( j=k; j<N; j++ ){
          *(tab + j + (k/P)*N) = *(tab + j + (k/P)*N) + pivot * *(ligne_pivot + j);
        }
    }

    for (i=k/P+1; i<N/P; i++ ){ /* update lines (k+1) to (n-1) */
      
      pivot = - *(tab + k + i*N) / *(ligne_pivot + k);
      
      for ( j=k; j<N; j++ ){ /* update elts (k) - (N-1) of line i */
        *(tab + j + i*N) = *(tab +j +i*N) + pivot * *(ligne_pivot + j);
      }
      /* *(tab+k+i*N) = 0.0; */
    }
    printf ("\n");
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

    gauss(tab, N, P, me, tids);

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

