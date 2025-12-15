%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%
"#include".*            ;   /* ignore includes */

"int"                   return INT;
"char"                  return CHAR;
"return"                return RETURN;
"main"                  return MAIN;
"printf"                return PRINTF;
"scanf"                 return SCANF;

"+"                     return PLUS;
"-"                     return MINUS;
"*"                     return MUL;
"/"                     return DIV;
"="                     return ASSIGN;
"&"                     return AMP;

"{"                     return LBRACE;
"}"                     return RBRACE;
"("                     return LPAREN;
")"                     return RPAREN;
";"                     return SEMI;
","                     return COMMA;

"%d"                    return FORMAT;
\"[^\"]*\"              { yylval.str = strdup(yytext); return STRING; }

[0-9]+                  { yylval.num = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]*  { yylval.str = strdup(yytext); return ID; }

"//".*                  ;   /* ignore comments */
[ \t\n]+                ;   /* ignore whitespace */

.                       { printf("Unknown character: %s\n", yytext); }
%%

int yywrap() { return 1; }
