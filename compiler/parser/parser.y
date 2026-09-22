%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int yylex(void); extern int yylineno; extern FILE *yyin; void yyerror(const char*);
typedef struct {int a,c,p;} Sym; typedef struct {int op,a,b,c;} Ins; typedef struct {char *n; int label;} Func;
enum {ADD=1,MUL,SOU,DIV,COP,AFC,JMP,JMF,INF,SUP,EQU,PRI,ADR,LDP,STP,CALL,RET};
static Sym syms[512]; static Func funcs[64]; static int nf,entry_jump,main_start; static char *names[512]; static int ns,na,nt=128,err,loop_start; static Ins code[8192]; static int nc; static const char *out="program";
static void bad(const char *s){fprintf(stderr,"Erreur ligne %d: %s\n",yylineno,s);err++;}
static int function_find(const char*n){for(int i=0;i<nf;i++)if(!strcmp(funcs[i].n,n))return i;return -1;}
static int find(const char*n){for(int i=0;i<ns;i++)if(!strcmp(names[i],n))return i;return -1;}
static int decl(const char*n,int c){if(find(n)>=0){bad("identificateur déjà déclaré");return -1;}if(na>=128){bad("mémoire des données pleine");return -1;}names[ns]=strdup(n);syms[ns]=(Sym){na++,c,0};return ns++;}
static int function_decl(const char*n){if(function_find(n)>=0){bad("fonction déjà déclarée");return -1;}funcs[nf]=(Func){strdup(n),nc};return nf++;}
static int pointer_decl(const char*n){if(find(n)>=0){bad("identificateur déjà déclaré");return -1;}if(na>=128){bad("mémoire des données pleine");return -1;}names[ns]=strdup(n);syms[ns]=(Sym){na++,0,1};return ns++;}
static int addr(const char*n){int i=find(n);if(i<0){bad("identificateur inconnu");return 0;}return syms[i].a;}
static int emit(int o,int a,int b,int c){code[nc]=(Ins){o,a,b,c};return nc++;}
static int bin(int o,int x,int y){if(nt>=256){bad("mémoire temporaire pleine");return 0;}int a=nt++;emit(o,a,x,y);return a;}
static void writeout(){char a[512],b[512];snprintf(a,512,"%s.asm",out);snprintf(b,512,"%s.obj",out);FILE*x=fopen(a,"w"),*y=fopen(b,"w");const char*n[]={"?","ADD","MUL","SOU","DIV","COP","AFC","JMP","JMF","INF","SUP","EQU","PRI","ADR","LDP","STP","CALL","RET"};for(int i=0;i<nc;i++){Ins z=code[i];fprintf(x,"%04d: %s %d %d %d\n",i,n[z.op],z.a,z.b,z.c);if(z.op==JMP||z.op==PRI)fprintf(y,"%d %d\n",z.op,z.a);else if(z.op==AFC||z.op==COP||z.op==CALL)fprintf(y,"%d %d %d\n",z.op,z.a,z.b);else if(z.op==RET)fprintf(y,"%d %d\n",z.op,z.a);else if(z.op==JMF)fprintf(y,"%d %d %d\n",z.op,z.a,z.b);else fprintf(y,"%d %d %d %d\n",z.op,z.a,z.b,z.c);}fclose(x);fclose(y);}
%}
%union {long number;char *id;int val;int mark;}
%token MAIN INT CONST IF ELSE WHILE PRINTF RETURN
%token <id> IDENTIFIER
%token <number> NUMBER
%token EQ
%precedence LOWER_THAN_ELSE
%precedence ELSE
%left '+' '-'
%left '*' '/'
%nonassoc '<' '>' EQ
%type <val> expression primary unary
%type <mark> ifhead whilehead elsejump
%start program
%%
program: {entry_jump=emit(JMP,-1,0,0);} functions MAIN '(' ')' '{' {main_start=nc;code[entry_jump].a=main_start;} declarations statements '}' {if(!err)writeout();};
functions: %empty|functions function;
function: INT IDENTIFIER '(' ')' {function_decl($2);free($2);} '{' declarations statements RETURN expression ';' '}' {emit(RET,$10,0,0);};
declarations: %empty|declarations declaration ';';
declaration: INT decls|INT pointer_decls|CONST consts;
pointer_decls: pointer_decl|pointer_decls ',' pointer_decl;
pointer_decl: '*' IDENTIFIER {pointer_decl($2);free($2);}| '*' IDENTIFIER '=' expression {int i=pointer_decl($2);if(i>=0)emit(COP,syms[i].a,$4,0);free($2);};
decls: decl|decls ',' decl;
decl: IDENTIFIER {decl($1,0);free($1);}|IDENTIFIER '=' expression {int i=decl($1,0);if(i>=0)emit(COP,syms[i].a,$3,0);free($1);};
consts: con|consts ',' con;
con: IDENTIFIER '=' expression {int i=decl($1,1);if(i>=0)emit(COP,syms[i].a,$3,0);free($1);};
statements: %empty|statements statement;
statement: ';'
| '*' IDENTIFIER '=' expression ';' {int i=find($2);if(i<0)bad("pointeur inconnu");else emit(STP,syms[i].a,$4,0);free($2);}
| IDENTIFIER '=' expression ';' {int i=find($1);if(i<0)bad("identificateur inconnu");else if(syms[i].c)bad("affectation d'une constante");else emit(COP,syms[i].a,$3,0);free($1);}
| PRINTF '(' expression ')' ';' {emit(PRI,$3,0,0);}
| '{' statements '}'
| ifhead statement %prec LOWER_THAN_ELSE {code[$1].b=nc;}
| ifhead statement elsejump statement {code[$1].b=$3;code[$3].a=nc;}
| whilehead statement {emit(JMP,loop_start,0,0);code[$1].b=nc;};
ifhead: IF '(' expression ')' {$$=emit(JMF,$3,-1,0);};
elsejump: ELSE {$$=emit(JMP,-1,0,0);};
whilehead: WHILE '(' {loop_start=nc;} expression ')' {int j=emit(JMF,$4,-1,0);$$=j;};
expression: unary {$$=$1;}|expression '+' expression {$$=bin(ADD,$1,$3);}|expression '-' expression {$$=bin(SOU,$1,$3);}|expression '*' expression {$$=bin(MUL,$1,$3);}|expression '/' expression {$$=bin(DIV,$1,$3);}|expression '<' expression {$$=bin(INF,$1,$3);}|expression '>' expression {$$=bin(SUP,$1,$3);}|expression EQ expression {$$=bin(EQU,$1,$3);}| '(' expression ')' {$$=$2;};
unary: primary {$$=$1;}| '&' IDENTIFIER {int t=nt++;emit(ADR,t,addr($2),0);$$=t;free($2);}| '*' IDENTIFIER {int t=nt++;emit(LDP,t,addr($2),0);$$=t;free($2);};
primary: IDENTIFIER '(' ')' {int f=function_find($1);int t=nt++;if(f<0)bad("fonction inconnue");else emit(CALL,t,funcs[f].label,0);free($1);$$=t;}| NUMBER {if(nt>=256){bad("mémoire temporaire pleine");}int a=nt++;emit(AFC,a,$1,0);$$=a;}|IDENTIFIER {$$=addr($1);free($1);};
%%
void yyerror(const char*s){bad(s);}
int main(int ac,char**av){if(ac>3)return 1;if(ac>1){yyin=fopen(av[1],"r");if(!yyin){perror(av[1]);return 1;}}if(ac>2)out=av[2];int r=yyparse();if(r||err)return 1;printf("Compilation réussie\n");return 0;}