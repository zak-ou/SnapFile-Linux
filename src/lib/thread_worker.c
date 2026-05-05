#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/wait.h>

/**
 * thread_worker.c (Version Corrigée)
 * 
 * Utilise pthread pour le parallélisme.
 * Pour chaque fichier, il crée un processus fils qui exécute 
 * la fonction bash exportée 'process_file' via execlp.
 */

#define MAX_THREADS 4
#define MAX_FICHIERS 5

typedef struct {
    char fichiers[MAX_FICHIERS][1024];
    int count;
} Lot;

void *traiter_lot(void *arg) {
    Lot *lot = (Lot *)arg;

    for (int i = 0; i < lot->count; i++) {
        pid_t pid = fork();
        if (pid == 0) {
            // Enfant : Appel direct à bash pour trouver la fonction exportée
            // On utilise execlp pour éviter de passer par /bin/sh (dash)
            execlp("bash", "bash", "-c", "process_file \"$1\"", "bash_worker", lot->fichiers[i], NULL);
            perror("execlp failed");
            exit(1);
        } else if (pid > 0) {
            // On attend que le traitement du fichier soit fini avant de passer au suivant dans CE thread
            waitpid(pid, NULL, 0);
        }
    }

    free(lot);
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file_list>\n", argv[0]);
        return 1;
    }

    FILE *liste = fopen(argv[1], "r");
    if (!liste) {
        perror("fopen");
        return 1;
    }

    pthread_t threads[MAX_THREADS];
    int thread_count = 0;
    char ligne[1024];
    Lot *lot = malloc(sizeof(Lot));
    lot->count = 0;

    while (fgets(ligne, sizeof(ligne), liste) != NULL) {
        ligne[strcspn(ligne, "\r\n")] = 0;
        if (strlen(ligne) == 0) continue;

        strcpy(lot->fichiers[lot->count], ligne);
        lot->count++;

        if (lot->count == MAX_FICHIERS) {
            pthread_create(&threads[thread_count], NULL, traiter_lot, lot);
            thread_count++;

            if (thread_count == MAX_THREADS) {
                for (int i = 0; i < MAX_THREADS; i++) {
                    pthread_join(threads[i], NULL);
                }
                thread_count = 0;
            }
            lot = malloc(sizeof(Lot));
            lot->count = 0;
        }
    }

    if (lot->count > 0) {
        pthread_create(&threads[thread_count], NULL, traiter_lot, lot);
        thread_count++;
    }

    for (int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    fclose(liste);
    return 0;
}
