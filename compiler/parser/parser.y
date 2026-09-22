%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int yylex(void); extern int yylineno; extern FILE *yyin; void yyerror(const char*);
typedef struct {int a,c;} Sym; typedef struct {int op,a,b,c;} Ins;
enum {ADD=1,MUL,SOU,DIV,COP,AFC,JMP,JMF,INF,SUP,EQU,PRI};
static Sym syms[512]; static char *names[512]; static int ns,na,nt=1000,err,loop_start; static Ins code[8192]; static int nc; static const char *out="program";
static void bad(const char *s){fprintf(stderr,"Erreur ligne %d: %s\n",yylineno,s);err++;}
static int find(const char*n){for(int i=0;i<ns;i++)if(!strcmp(names[i],n))return i;return -1;}
static int decl(const char*n,int c){if(find(n)>=0){bad("identificateur déjà déclaré");return -1;}names[ns]=strdup(n);syms[ns]=(Sym){na++,c};return ns++;}
static int addr(const char*n){int i=find(n);if(i<0){bad("identificateur inconnu");return 0;}return syms[i].a;}
static int emit(int o,int a,int b,int c){code[nc]=(Ins){o,a,b,c};return nc++;}
static int bin(int o,int x,int y){int a=nt++;emit(o,a,x,y);return a;}
static void writeout(){char a[512],b[512];snprintf(a,512,"%s.asm",out);snprintf(b,512,"%s.obj",out);FILE*x=fopen(a,"w"),*y=fopen(b,"w");const char*n[]={"?","ADD","MUL","SOU","DIV","COP","AFC","JMP","JMF","INF","SUP","EQU","PRI"};for(int i=0;i<nc;i++){Ins z=code[i];fprintf(x,"%04d: %s %d %d %d\n",i,n[z.op],z.a,z.b,z.c);if(z.op==JMP||z.op==PRI)fprintf(y,"%d %d\n",z.op,z.a);else if(z.op==AFC||z.op==COP)fprintf(y,"%d %d %d\n",z.op,z.a,z.b);else if(z.op==JMF)fprintf(y,"%d %d %d\n",z.op,z.a,z.b);else fprintf(y,"%d %d %d %d\n",z.op,z.a,z.b,z.c);}fclose(x);fclose(y);}
%}
%union {long number;char *id;int val;int mark;}
%token MAIN INT CONST IF ELSE WHILE PRINTF
%token <id> IDENTIFIER
%token <number> NUMBER
%token EQ
%left '+' '-'
%left '*' '/'
%nonassoc '<' '>' EQ
%type <val> expression primary
%type <mark> ifhead whilehead elsejump
%start program
%%
program: MAIN '(' ')' '{' declarations statements '}' {if(!err)writeout();};
declarations: %empty|declarations declaration ';';
declaration: INT decls|CONST consts;
decls: decl|decls ',' decl;
decl: IDENTIFIER {decl($1,0);free($1);}|IDENTIFIER '=' expression {int i=decl($1,0);if(i>=0)emit(COP,syms[i].a,$3,0);free($1);};
consts: con|consts ',' con;
con: IDENTIFIER '=' expression {int i=decl($1,1);if(i>=0)emit(COP,syms[i].a,$3,0);free($1);};
statements: %empty|statements statement;
statement: ';'
| IDENTIFIER '=' expression ';' {int i=find($1);if(i<0)bad("identificateur inconnu");else if(syms[i].c)bad("affectation d'une constante");else emit(COP,syms[i].a,$3,0);free($1);}
| PRINTF '(' expression ')' ';' {emit(PRI,$3,0,0);}
| '{' statements '}'
| ifhead statement {code[$1].b=nc;}
| ifhead statement elsejump statement {code[$1].b=$3;code[$3].a=nc;}
| whilehead statement {emit(JMP,loop_start,0,0);code[$1].b=nc;};
ifhead: IF '(' expression ')' {$$=emit(JMF,$3,-1,0);};
elsejump: ELSE {$$=emit(JMP,-1,0,0);};
whilehead: WHILE '(' {loop_start=nc;} expression ')' {int j=emit(JMF,$4,-1,0);$$=j;};
expression: primary {$$=$1;}|expression '+' expression {$$=bin(ADD,$1,$3);}|expression '-' expression {$$=bin(SOU,$1,$3);}|expression '*' expression {$$=bin(MUL,$1,$3);}|expression '/' expression {$$=bin(DIV,$1,$3);}|expression '<' expression {$$=bin(INF,$1,$3);}|expression '>' expression {$$=bin(SUP,$1,$3);}|expression EQ expression {$$=bin(EQU,$1,$3);}| '(' expression ')' {$$=$2;};
primary: NUMBER {int a=nt++;emit(AFC,a,$1,0);$$=a;}|IDENTIFIER {$$=addr($1);free($1);};
%%
void yyerror(const char*s){bad(s);}
int main(int ac,char**av){if(ac>3)return 1;if(ac>1){yyin=fopen(av[1],"r");if(!yyin){perror(av[1]);return 1;}}if(ac>2)out=av[2];int r=yyparse();if(r||err)return 1;printf("Compilation réussie\n");return 0;}