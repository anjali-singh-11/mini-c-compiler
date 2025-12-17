%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

/* ---------- SYMBOL TABLE ---------- */
struct Symbol {
    char name[50];
    char type[10];
};

struct Symbol symtab[100];
int symcount = 0;

int lookup(char *name) {
    for (int i = 0; i < symcount; i++)
        if (strcmp(symtab[i].name, name) == 0)
            return i;
    return -1;
}

void insert(char *name, char *type) {
    if (lookup(name) != -1) {
        printf("Semantic Error ❌: %s redeclared\n", name);
        exit(1);
    }
    strcpy(symtab[symcount].name, name);
    strcpy(symtab[symcount].type, type);
    symcount++;
}

void display() {
    printf("\n------ SYMBOL TABLE ------\n");
    printf("Name\tType\n");
    for (int i = 0; i < symcount; i++) {
        printf("%s\t%s\n", symtab[i].name, symtab[i].type);
    }
}

/* ---------- THREE ADDRESS CODE ---------- */
struct TAC {
    char res[10], op1[10], op2[10], op[5];
};

struct TAC tac[100];
int tacCount = 0;
int tempCount = 0;

char* newtemp() {
    char *t = (char*)malloc(10);
    sprintf(t, "t%d", tempCount++);
    return t;
}

void emit(char *res, char *op1, char *op, char *op2) {
    strcpy(tac[tacCount].res, res);
    strcpy(tac[tacCount].op1, op1);
    strcpy(tac[tacCount].op, op);
    strcpy(tac[tacCount].op2, op2);
    tacCount++;
}

void displayTAC() {
    printf("\n---- THREE ADDRESS CODE ----\n");
    for (int i = 0; i < tacCount; i++) {
        if (strcmp(tac[i].op, "=") == 0)
            printf("%s = %s\n", tac[i].res, tac[i].op1);
        else
            printf("%s = %s %s %s\n",
                   tac[i].res, tac[i].op1,
                   tac[i].op, tac[i].op2);
    }
}

void generateTargetCode() {
    printf("\n---- TARGET CODE (Assembly-like) ----\n");

    for (int i = 0; i < tacCount; i++) {

        if (strcmp(tac[i].op, "=") == 0) {
            printf("MOV %s, %s\n", tac[i].res, tac[i].op1);
        }

        else if (strcmp(tac[i].op, "+") == 0) {
            printf("MOV R1, %s\n", tac[i].op1);
            printf("ADD R1, %s\n", tac[i].op2);
            printf("MOV %s, R1\n", tac[i].res);
        }

        else if (strcmp(tac[i].op, "-") == 0) {
            printf("MOV R1, %s\n", tac[i].op1);
            printf("SUB R1, %s\n", tac[i].op2);
            printf("MOV %s, R1\n", tac[i].res);
        }

        else if (strcmp(tac[i].op, "*") == 0) {
            printf("MOV R1, %s\n", tac[i].op1);
            printf("MUL R1, %s\n", tac[i].op2);
            printf("MOV %s, R1\n", tac[i].res);
        }

        else if (strcmp(tac[i].op, "/") == 0) {
            printf("MOV R1, %s\n", tac[i].op1);
            printf("DIV R1, %s\n", tac[i].op2);
            printf("MOV %s, R1\n", tac[i].res);
        }
    }
}

%}



/* ---------- UNION ---------- */
%union {
    int num;
    char* str;
}

/* ---------- TOKENS ---------- */
%token INT CHAR RETURN MAIN PRINTF SCANF
%token <num> NUMBER
%token <str> ID STRING
%token FORMAT

%token PLUS MINUS MUL DIV ASSIGN AMP
%token LBRACE RBRACE LPAREN RPAREN SEMI COMMA

/* ---------- NON-TERMINAL TYPES ---------- */
%type <str> expr term factor

/* ---------- PRECEDENCE ---------- */
%left PLUS MINUS
%left MUL DIV

%%
program:
    main_function
    ;

main_function:
    INT MAIN LPAREN RPAREN LBRACE statements RBRACE
    ;

statements:
    statements statement
    |
    ;

statement:
      declaration
    | assignment
    | printf_stmt
    | scanf_stmt
    | return_stmt
    ;

declaration:
      INT ID ASSIGN expr SEMI
      {
          insert($2, "int");
          emit($2, $4, "=", "");
      }
    | INT ID SEMI
      {
          insert($2, "int");
      }
    | CHAR ID SEMI
      {
          insert($2, "char");
      }
    ;

assignment:
    ID ASSIGN expr SEMI
    {
        if (lookup($1) == -1) {
            printf("Semantic Error ❌: %s not declared\n", $1);
            exit(1);
        }
        emit($1, $3, "=", "");
    }
    ;

expr:
      expr PLUS term
      {
          char *t = newtemp();
          emit(t, $1, "+", $3);
          $$ = t;
      }
    | expr MINUS term
      {
          char *t = newtemp();
          emit(t, $1, "-", $3);
          $$ = t;
      }
    | term
      {
          $$ = $1;
      }
    ;

term:
      term MUL factor
      {
          char *t = newtemp();
          emit(t, $1, "*", $3);
          $$ = t;
      }
    | term DIV factor
      {
          char *t = newtemp();
          emit(t, $1, "/", $3);
          $$ = t;
      }
    | factor
      {
          $$ = $1;
      }
    ;

factor:
      NUMBER
      {
          char buf[10];
          sprintf(buf, "%d", $1);
          $$ = strdup(buf);
      }
    | ID
      {
          if (lookup($1) == -1) {
              printf("Semantic Error ❌: %s not declared\n", $1);
              exit(1);
          }
          $$ = $1;
      }
    | LPAREN expr RPAREN
      {
          $$ = $2;
      }
    ;

printf_stmt:
    PRINTF LPAREN STRING RPAREN SEMI
    ;

scanf_stmt:
    SCANF LPAREN STRING COMMA AMP ID RPAREN SEMI
    ;

return_stmt:
    RETURN expr SEMI
    {
        emit("return", $2, "=", "");
    }
    ;
%%

void yyerror(const char *s) {
    printf("Syntax Error ❌: %s\n", s);
}

int main() {
    printf("Parsing started...\n");
    yyparse();
    printf("Parsing successful ✅\n");
    display();
    displayTAC();
    generateTargetCode();
    return 0;
}
