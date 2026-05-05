#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#define BATCH_SIZE 5

/**
 * fork_worker.c
 * 
 * Ce programme lit une liste de fichiers depuis un fichier texte
 * et crée des processus fils via fork() pour traiter les fichiers
 * par lots de 5. Chaque fils appelle la fonction bash 'process_file'.
 */

void execute_batch(char *files[], int count) {
    pid_t pid = fork();
    if (pid == 0) {
        // Processus fils
        // On construit les arguments pour appeler bash -c "process_file \"$@\""
        // args[0] = bash
        // args[1] = -c
        // args[2] = process_file "$@"
        // args[3] = bash (nom du script pour $@)
        // args[4...8] = fichiers
        
        char *args[BATCH_SIZE + 5];
        args[0] = "bash";
        args[1] = "-c";
        args[2] = "process_file \"$@\"";
        args[3] = "bash_worker"; 
        
        for (int i = 0; i < count; i++) {
            args[i + 4] = files[i];
        }
        args[count + 4] = NULL;
        
        execvp("bash", args);
        perror("execvp failed");
        exit(1);
    } else if (pid < 0) {
        perror("fork failed");
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file_list>\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        perror("fopen failed");
        return 1;
    }

    char *batch[BATCH_SIZE];
    char line[4096];
    int count = 0;

    while (fgets(line, sizeof(line), fp)) {
        // Nettoyer le saut de ligne
        line[strcspn(line, "\r\n")] = 0;
        if (strlen(line) == 0) continue;

        batch[count] = strdup(line);
        count++;

        if (count == BATCH_SIZE) {
            execute_batch(batch, count);
            for (int i = 0; i < count; i++) {
                free(batch[i]);
            }
            count = 0;
        }
    }

    // Traiter le dernier lot s'il n'est pas vide
    if (count > 0) {
        execute_batch(batch, count);
        for (int i = 0; i < count; i++) {
            free(batch[i]);
        }
    }

    fclose(fp);

    // Attendre la fin de tous les processus fils
    int status;
    while (wait(&status) > 0);

    return 0;
}
