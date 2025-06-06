#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "spam_detector.h"

/* Constantes */
#define MAX_MESSAGE_SIZE 4096
#define VERSION "1.0.0"

/* Prototipos de funciones auxiliares */
void print_header();
void print_menu();
void print_stats();
void analyze_and_print_result();
void clear_screen();
char* read_multiline_input();

/* Función principal */
int main(int argc, char* argv[]) {
    int option = 0;
    char* message = NULL;
    
    print_header();
    
    /* Si se proporciona un archivo como argumento, analizar su contenido */
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (file == NULL) {
            fprintf(stderr, "Error: No se pudo abrir el archivo %s\n", argv[1]);
            return 1;
        }
        
        /* Leer el contenido del archivo */
        fseek(file, 0, SEEK_END);
        long filesize = ftell(file);
        fseek(file, 0, SEEK_SET);
        
        message = (char*)malloc(filesize + 1);
        if (message == NULL) {
            fprintf(stderr, "Error: No se pudo asignar memoria para el contenido del archivo\n");
            fclose(file);
            return 1;
        }
        
        fread(message, 1, filesize, file);
        message[filesize] = '\0';
        fclose(file);
        
        /* Analizar el mensaje */
        analysis_result_t result = analyze_message(message);
        
        /* Mostrar resultado */
        printf("\n========================================\n");
        printf("🔍  RESULTADO DEL ANÁLISIS  🔍\n");
        printf("========================================\n");
        
        if (result.spam_found) {
            printf("⚠️  ¡SPAM DETECTADO!\n");
            printf("Confianza: %d%%\n", result.confidence);
            
            if (result.pattern_count > 0) {
                printf("\nPatrones detectados:\n");
                for (int i = 0; i < result.pattern_count; i++) {
                    printf("- %s: \"%s\" (línea %d)\n", 
                           result.patterns[i].name, 
                           result.patterns[i].match,
                           result.patterns[i].line);
                }
            }
        } else {
            printf("✅  Este mensaje parece seguro y no contiene spam.\n");
        }
        
        /* Liberar memoria */
        free(message);
        free_analysis_result(&result);
        
        return 0;
    }
    
    /* Modo interactivo */
    while (1) {
        print_menu();
        scanf("%d", &option);
        getchar(); /* Consumir el salto de línea */
        
        switch (option) {
            case 1:
                analyze_and_print_result();
                break;
                
            case 2:
                print_stats();
                break;
                
            case 3:
                printf("\n¡Gracias por usar el Detector de Spam Avanzado!\n\n");
                return 0;
                
            default:
                printf("\nOpción inválida. Por favor intente de nuevo.\n");
                break;
        }
    }
    
    return 0;
}

/* Función para imprimir el encabezado */
void print_header() {
    clear_screen();
    printf("========================================\n");
    printf("🛡️  DETECTOR DE SPAM AVANZADO v%s  🛡️\n", VERSION);
    printf("========================================\n");
    printf("Basado en análisis léxico y sintáctico formal\n");
    printf("Implementado con Flex y Bison\n\n");
}

/* Función para imprimir el menú */
void print_menu() {
    printf("\n\n========================================\n");
    printf("🛡️  MENÚ PRINCIPAL  🛡️\n");
    printf("========================================\n\n");
    printf("1. Analizar un mensaje\n");
    printf("2. Ver estadísticas\n");
    printf("3. Salir\n");
    printf("\nSeleccione una opción: ");
}

/* Función para imprimir estadísticas */
void print_stats() {
    stats_t stats = get_statistics();
    
    clear_screen();
    printf("\n========================================\n");
    printf("📊  ESTADÍSTICAS  📊\n");
    printf("========================================\n");
    printf("Mensajes analizados: %d\n", stats.total_messages);
    printf("Spam detectado: %d\n", stats.spam_messages);
    printf("Mensajes seguros: %d\n", stats.safe_messages);
    
    if (stats.total_messages > 0) {
        printf("Porcentaje de spam: %.2f%%\n", stats.spam_percentage);
    }
    
    printf("\nPresione Enter para continuar...");
    getchar();
    clear_screen();
}

/* Función para analizar un mensaje y mostrar el resultado */
void analyze_and_print_result() {
    clear_screen();
    printf("\n========================================\n");
    printf("📝  ANÁLISIS DE MENSAJE  📝\n");
    printf("========================================\n");
    printf("Ingrese el mensaje a analizar:\n");
    printf("(Finalice con una línea que solo contenga '.')\n\n");
    
    char* message = read_multiline_input();
    
    if (message == NULL || strlen(message) == 0) {
        printf("⚠️ Mensaje vacío o error de lectura.\n");
        printf("\nPresione Enter para continuar...");
        getchar();
        clear_screen();
        return;
    }
    
    /* Analizar el mensaje */
    analysis_result_t result = analyze_message(message);
    
    /* Mostrar resultado */
    clear_screen();
    printf("\n========================================\n");
    printf("🔍  RESULTADO DEL ANÁLISIS  🔍\n");
    printf("========================================\n");
    
    if (result.spam_found) {
        printf("⚠️  ¡SPAM DETECTADO!\n");
        printf("Confianza: %d%%\n", result.confidence);
        
        if (result.pattern_count > 0) {
            printf("\nPatrones detectados:\n");
            for (int i = 0; i < result.pattern_count; i++) {
                printf("- %s: \"%s\" (línea %d)\n", 
                       result.patterns[i].name, 
                       result.patterns[i].match,
                       result.patterns[i].line);
            }
        }
    } else {
        printf("✅  Este mensaje parece seguro y no contiene spam.\n");
    }
    
    /* Liberar memoria */
    free(message);
    free_analysis_result(&result);
    
    printf("\nPresione Enter para continuar...");
    getchar();
    clear_screen();
}

/* Función para leer entrada multilínea */
char* read_multiline_input() {
    char* buffer = malloc(MAX_MESSAGE_SIZE);
    if (!buffer) return NULL;
    
    char line[1024];
    buffer[0] = '\0';
    int total_len = 0;
    
    while (fgets(line, sizeof(line), stdin) && strcmp(line, ".\n") != 0) {
        int line_len = strlen(line);
        
        /* Verificar si hay espacio suficiente */
        if (total_len + line_len >= MAX_MESSAGE_SIZE - 1) {
            break;
        }
        
        /* Añadir la línea al buffer */
        strcat(buffer, line);
        total_len += line_len;
    }
    
    return buffer;
}

/* Función para limpiar la pantalla */
void clear_screen() {
#ifdef _WIN32
    system("cls");
#else
    system("clear");
#endif
}

/* Función para liberar recursos de un resultado de análisis */
void free_analysis_result(analysis_result_t* result) {
    if (result && result->patterns) {
        free(result->patterns);
        result->patterns = NULL;
        result->pattern_count = 0;
    }
}

/* Función para guardar las estadísticas en el archivo */
void save_statistics() {
    stats_t stats = get_statistics();
    FILE* file = fopen("stats", "w");
    if (file) {
        fprintf(file, "%d,%d,%d,%.2f", 
            stats.total_messages,
            stats.spam_messages, 
            stats.safe_messages,
            stats.spam_percentage);
        fclose(file);
    }
}