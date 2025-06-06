%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "spam_detector.h"
#include "spam_parser.tab.h"

/* Referencias a variables globales definidas en spam_parser.y */
extern int spam_score;
extern pattern_t detected_patterns[MAX_PATTERNS];
extern int pattern_count;
%}

%option noyywrap
%option case-insensitive
%option yylineno

/* Estados para el análisis contextual */
%x ANALYZING_TEXT

/* Definición de patrones mediante expresiones regulares formales */
WHITESPACE      [ \t\r\n]+
WORD            [a-zA-Z0-9']+
PUNCTUATION     [.,;:!?()-]

/* Patrones de spam formalizados */
HELP_PATTERN    (please[ ]+help|assist[ ]+me|help[ ]+me[ ]+please|urgent[ ]+help)
MONEY_PATTERN   [0-9]+[ ]*((hundred|thousand|million|billion)[ ]+)?(dollar|dollars)
FREE_MONEY      (^|[ ])fr[e3][e3][ ]*m[o0]n[e3]y([ ]|$|!)
STOCK_ALERT     (^|[ ])[s5][t7][o0][c]{1}k[ ]+[a@4][l1][e3]r[t7]([ ]|$|!)
DEAR_FRIEND     (^|[ ])d[e3][a@4]r[ ]+fr[i1][e3]nd([ ]|$|!)
URGENT_ACTION   (urgent.{0,20}action|act[ ]+now|limited[ ]+time|expires[ ]+soon)
WIN_PRIZE       (you.{0,10}won|winner|congratulations.{0,20}prize|claim.{0,10}reward)
CLICK_HERE      (click[ ]+here|click[ ]+now|visit.{0,10}link|download[ ]+now)

%%
<INITIAL>{
    \/\*              { BEGIN(ANALYZING_TEXT); return START_ANALYSIS; }
    {WHITESPACE}      { /* Ignorar espacios en blanco */ }
    .                 { /* Ignorar otros caracteres en estado inicial */ }
}

<ANALYZING_TEXT>{
    \*\/              { BEGIN(INITIAL); return END_ANALYSIS; }
    
    {HELP_PATTERN}    { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Solicitud de ayuda", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {MONEY_PATTERN}   { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Menciones de dinero", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {FREE_MONEY}      { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Dinero gratis", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {STOCK_ALERT}     { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Alerta de acciones", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {DEAR_FRIEND}     { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Saludo sospechoso", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {URGENT_ACTION}   { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Urgencia sospechosa", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {WIN_PRIZE}       { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Premio o ganador", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {CLICK_HERE}      { 
                        spam_score += PATTERN_WEIGHT;
                        if (pattern_count < MAX_PATTERNS) {
                            add_pattern("Llamada a la acción", yytext);
                        }
                        return SPAM_PATTERN; 
                      }

    {WORD}            { 
                        yylval.text = strdup(yytext);
                        return WORD_TOKEN; 
                      }

    {PUNCTUATION}     { return yytext[0]; }
    {WHITESPACE}      { /* Ignorar espacios en blanco */ }

    .                 { /* Capturar cualquier otro carácter */ }
}

%%

/* Función para agregar un patrón detectado con su contexto */
void add_pattern(const char* name, const char* match) {
    strncpy(detected_patterns[pattern_count].name, name, MAX_PATTERN_NAME);
    strncpy(detected_patterns[pattern_count].match, match, MAX_PATTERN_MATCH);
    detected_patterns[pattern_count].line = yylineno;
    pattern_count++;
}

/* Función para iniciar el análisis con un buffer de entrada */
void begin_analysis(const char* text) {
    spam_score = 0;
    pattern_count = 0;
    
    /* Envolver el texto con los delimitadores necesarios */
    char* wrapped_text = malloc(strlen(text) + 5); // +5 para "/" + "/" + null
    if (wrapped_text) {
        sprintf(wrapped_text, "/%s/", text);
        YY_BUFFER_STATE buffer = yy_scan_string(wrapped_text);
        free(wrapped_text);
        BEGIN(INITIAL); // Comienza en INITIAL para detectar /* correctamente
    } else {
        // Manejo del error si malloc falla
        fprintf(stderr, "Error: No se pudo asignar memoria para el análisis\n");
    }
}

/* Función para finalizar el análisis */
void end_analysis() {
    BEGIN(INITIAL);
    yylex_destroy();
}