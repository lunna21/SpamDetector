#ifndef SPAM_DETECTOR_H
#define SPAM_DETECTOR_H

/* Constantes para la detección de spam */
#define MAX_PATTERNS 20
#define MAX_PATTERN_NAME 50
#define MAX_PATTERN_MATCH 100
#define PATTERN_WEIGHT 25
#define SPAM_THRESHOLD 25

/* Estructura para almacenar patrones detectados */
typedef struct {
    char name[MAX_PATTERN_NAME];
    char match[MAX_PATTERN_MATCH];
    int line;
} pattern_t;

/* Estructura para almacenar estadísticas */
typedef struct {
    int total_messages;
    int spam_messages;
    int safe_messages;
    double spam_percentage;
} stats_t;

/* Estructura para el resultado del análisis */
typedef struct {
    int spam_found;
    int confidence;
    pattern_t* patterns;
    int pattern_count;
} analysis_result_t;

/* Prototipos de funciones */
void add_pattern(const char* name, const char* match);
analysis_result_t analyze_message(const char* message);
stats_t get_statistics();
void free_analysis_result(analysis_result_t* result);

#endif /* SPAM_DETECTOR_H */