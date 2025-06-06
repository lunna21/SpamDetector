%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/spam_detector.h"

extern int yylex();
extern int yylineno;
extern char* yytext;
extern void begin_analysis(const char* text);
extern void end_analysis();

void yyerror(const char* s);

/* Variables globales */
int spam_score = 0;
pattern_t detected_patterns[MAX_PATTERNS];
int pattern_count = 0;

/* Estadísticas de análisis */
stats_t statistics = {0, 0, 0, 0.0};

/* Resultado del análisis actual */
analysis_result_t current_result;
%}

/* Definición de tipos para los tokens */
%union {
    char* text;
    int value;
}

/* Declaración de tokens */
%token START_ANALYSIS
%token END_ANALYSIS
%token SPAM_PATTERN
%token <text> WORD_TOKEN

/* Declaración de precedencias */
%left '+' '-'
%left '*' '/'

/* Punto de inicio de la gramática */
%start message

%%

/* Gramática para analizar mensajes */
message: 
        | message message_part
        ;

message_part: START_ANALYSIS content END_ANALYSIS
            ;

content: 
       | content SPAM_PATTERN 
         { 
             /* Cada patrón de spam detectado incrementa el contador */
             current_result.spam_found = 1;
         }
       | content WORD_TOKEN 
         { 
             /* Registrar palabras para posible análisis estadístico */
             free($2); 
         }
       | content '.' 
       | content ',' 
       | content ';'
       | content ':' 
       | content '!' 
       | content '?'
       | content '(' 
       | content ')'
       ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Error de análisis (línea %d): %s\n", yylineno, s);
}

/* Función principal para analizar un mensaje */
analysis_result_t analyze_message(const char* message) {
    /* Inicializar el resultado */
    current_result.spam_found = 0;
    current_result.confidence = 0;
    current_result.patterns = NULL;
    current_result.pattern_count = 0;
    
    /* Iniciar el análisis con el texto proporcionado */
    begin_analysis(message);
    
    /* Realizar el análisis */
    yyparse();
    
    /* Finalizar el análisis */
    end_analysis();
    
    /* Actualizar estadísticas */
    statistics.total_messages++;
    
    /* Calcular puntuación de confianza (limitada a 95%) */
    current_result.confidence = spam_score > 95 ? 95 : spam_score;
    
    /* Si se encontró spam, actualizar las estadísticas */
    if (current_result.confidence >= SPAM_THRESHOLD) {
        statistics.spam_messages++;
        current_result.spam_found = 1;
    } else {
        statistics.safe_messages++;
        current_result.spam_found = 0;
    }
    
    /* Actualizar el porcentaje de spam */
    statistics.spam_percentage = (double)statistics.spam_messages / statistics.total_messages * 100.0;
    
    /* Copiar los patrones detectados para el resultado */
    if (pattern_count > 0) {
        current_result.pattern_count = pattern_count;
        current_result.patterns = malloc(sizeof(pattern_t) * pattern_count);
        memcpy(current_result.patterns, detected_patterns, sizeof(pattern_t) * pattern_count);
    }
    
    return current_result;
}

/* Función para obtener las estadísticas actuales */
stats_t get_statistics() {
    return statistics;
}