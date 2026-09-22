%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}
%option noyywrap yylineno nodefault noinput nounput
ID [A-Za-z][A-Za-z0-9_]*
NUM ([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?
%%
"main" {return MAIN;}
"int" {return INT;}
"const" {return CONST;}
"if" {return IF;}
"else" {return ELSE;}
"while" {return WHILE;}
"printf" {return PRINTF;}
"return" {return RETURN;}
"==" return EQ;
{NUM} {char*e;long v=strtol(yytext,&e,10);if(*e)v=(long)strtod(yytext,0);yylval.number=v;return NUMBER;}
{ID} {yylval.id=strdup(yytext);return IDENTIFIER;}
[ \t\r\n]+ ;
"//"[^\n]* ;
. {return yytext[0];}
%%
