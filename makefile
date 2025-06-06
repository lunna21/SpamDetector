# Makefile para el Detector de Spam

CC = gcc
CFLAGS = -Wall -Wextra -g -Isrc
LDFLAGS = -lfl -lm

# Directorios
SRC_DIR = src
BIN_DIR = .

# Archivos fuente y destino
LEXER_SRC = $(SRC_DIR)/spam_lexer.l
PARSER_SRC = $(SRC_DIR)/spam_parser.y
MAIN_SRC = $(SRC_DIR)/main.c

# Archivos generados
LEXER_C = lex.yy.c
PARSER_C = spam_parser.tab.c
PARSER_H = spam_parser.tab.h

# Ejecutable
TARGET = spam_detector

all: $(TARGET)

$(TARGET): $(LEXER_C) $(PARSER_C) $(PARSER_H) $(MAIN_SRC)
	$(CC) $(CFLAGS) -o $(BIN_DIR)/$@ $(LEXER_C) $(PARSER_C) $(MAIN_SRC) $(LDFLAGS)

$(LEXER_C): $(LEXER_SRC) $(PARSER_H)
	flex -o $@ $<

$(PARSER_C) $(PARSER_H): $(PARSER_SRC)
	bison -d -o $(PARSER_C) $<

clean:
	rm -f $(BIN_DIR)/$(TARGET) $(LEXER_C) $(PARSER_C) $(PARSER_H) *.o

.PHONY: all clean