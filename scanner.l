/* definitions */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tokendef.h"

 /* integers to track line and column numbers */
int scancol = 1;
int yycol = 1;
int scanlineno = 1;

 /* char pointer to pass error messages to driver.c */
char *yyerror;

 /* TODO: functions to update line and column numbers */
void updateCol();
void countLines();

 /* TODO: function to process a string literal */
int processString();

/* yylval for returning string (and possibly other) values to driver */
#ifndef YYSTYPE
typedef union {
    char *str;
    int ival;
} YYSTYPE;
#endif
extern YYSTYPE yylval;

/* --- String and comment handling: track start position for error messages (line:col).
 *     Buffer holds string content while in STRING state; string_had_error skips
 *     returning a string token after a bad escape so the rest of the line parses. --- 
 */
static int string_start_line, string_start_col;
static int comment_start_line, comment_start_col;
#define STRING_BUF_SIZE 4096
static char string_buf[STRING_BUF_SIZE];
static int string_buf_len;
static int string_had_error;

%}

%x STRING
%x COMMENT

newline         \n
whitespace      [ \t\r]+
integer         0|[1-9][0-9]*
integerlead0    0[0-9]+
character       \'.\'

 /* String can contain any characters between the double quotes */
 /* other than a newline or unescaped doublequotes */

string       \"([^"\\\n]|\\.)*\"

 /* If the end quote is not found in the same line the string is unterminated */
untermstring \"([^"\\\n]|\\.)*\n

comment         /\*([^*]|\*+[^*/])*\*/
multlncomment   /\*([^*]|\*+[^*/])*\*/
untermcomment   /\*[^*]*

identifier     [a-zA-Z][a-zA-Z0-9]*
illidentifier  [0-9]+[a-zA-Z][a-zA-Z0-9]*

%%

 /* rules */

 /* Keywords */
 /* 2/15: added keyword defintions for reserved words*/

"if"		{updateCol(); return KWD_IF;}
"else"	 	{updateCol(); return KWD_ELSE;}
"while" 	{updateCol(); return KWD_WHILE;}
"int" 		{updateCol(); return KWD_INT;}
"string"	{updateCol(); return KWD_STRING;}
"char"		{updateCol(); return KWD_CHAR;}
"return"	{updateCol(); return KWD_RETURN;}
"void"		{updateCol(); return KWD_VOID;}


 /* Operators */
 /* TODO: Support all operators in mC */
"<="	{updateCol(); return OPER_LTE;}
">=" 	{updateCol(); return OPER_GTE;}
"=="	{updateCol(); return OPER_EQ;}
"!="	{updateCol(); return OPER_NEQ;}
"++"	{updateCol(); return OPER_INC;}
"--"	{updateCol(); return OPER_DEC;}
"&&"	{updateCol(); return OPER_AND;}
"%"	{updateCol(); return OPER_MOD;}
"||"	{updateCol(); return OPER_OR;}
"<"	{updateCol(); return OPER_LT;}
">"	{updateCol(); return OPER_GT;}
"="	{updateCol(); return OPER_ASGN;}
"@"	{updateCol(); return OPER_AT;}
"+"	{updateCol(); return OPER_ADD;}
"-"	{updateCol(); return OPER_SUB;}
"*"	{updateCol(); return OPER_MUL;}
"/"	{updateCol(); return OPER_DIV;}
"!"	{updateCol(); return OPER_NOT;}
"["	{updateCol(); return LSQ_BRKT;}
"]"	{updateCol(); return RSQ_BRKT;}
"{"	{updateCol(); return LCRLY_BRKT;}
"}"	{updateCol(); return RCRLY_BRKT;}
"("	{updateCol(); return LPAREN;}
")"	{updateCol(); return RPAREN;}
","	{updateCol(); return COMMA;}
";"	{updateCol(); return SEMICLN;}

 /* Identifiers */
{identifier}    {updateCol(); return ID;}

{illidentifier} {updateCol(); yyerror = "Illegal token"; return ERROR;}

 /* Constants */
{integerlead0}	{updateCol(); yyerror = "Illegal token"; return ERROR;}
{integer}       {updateCol(); yylval.ival = atoi(yytext); return INTCONST;}
{character}     {updateCol(); return CHARCONST;}

 /* String handling: STRING state; start (line,col); escapes \n \t \" \\; bad escape or newline or EOF = ERROR at correct line:col */
\"              {
                    string_start_line = scanlineno;
                    string_start_col = scancol;
                    updateCol();
                    string_buf_len = 0;
                    string_buf[0] = '\0';
                    string_had_error = 0;
                    BEGIN(STRING);
                }

<STRING>\"      {
                    updateCol();
                    if (string_had_error) {
                        string_had_error = 0;
                        BEGIN(INITIAL);
                        return yylex();
                    }
                    string_buf[string_buf_len] = '\0';
                    yylineno = string_start_line;
                    yycol = string_start_col;
                    BEGIN(INITIAL);
                    return processString();
                }

<STRING>\\n     {
                    if (string_buf_len < STRING_BUF_SIZE - 1)
                        string_buf[string_buf_len++] = '\n';
                    updateCol();
                }

<STRING>\\t     {
                    if (string_buf_len < STRING_BUF_SIZE - 1)
                        string_buf[string_buf_len++] = '\t';
                    updateCol();
                }

<STRING>\\\"    {
                    if (string_buf_len < STRING_BUF_SIZE - 1)
                        string_buf[string_buf_len++] = '"';
                    updateCol();
                }

<STRING>\\\\    {
                    if (string_buf_len < STRING_BUF_SIZE - 1)
                        string_buf[string_buf_len++] = '\\';
                    updateCol();
                }

<STRING>\\.     {
                    yyerror = "Unrecognized escape character in String";
                    string_had_error = 1;
                    yylineno = scanlineno;
                    yycol = scancol;
                    scancol += yyleng;
                    return ERROR;
                }

<STRING>\n      {
                    yyerror = "String spans multiple lines";
                    yylineno = string_start_line;
                    yycol = string_start_col;
                    countLines();
                    BEGIN(INITIAL);
                    return ERROR;
                }

<STRING><<EOF>> {
                    yyerror = "Unterminated string constant";
                    yylineno = string_start_line;
                    yycol = string_start_col;
                    BEGIN(INITIAL);
                    return ERROR;
                }

<STRING>[^"\\\n]+ {
                    int i;
                    for (i = 0; i < yyleng && string_buf_len < STRING_BUF_SIZE - 1; i++)
                        string_buf[string_buf_len++] = yytext[i];
                    updateCol();
                }

 /* Comments */
 /* Comment handling: COMMENT state; start pos recorded; EOF = Unterminated comment at that pos */
"/*"            {
                    comment_start_line = scanlineno;
                    comment_start_col = scancol;
                    updateCol();
                    BEGIN(COMMENT);
                }

<COMMENT>"*/"   {
                    updateCol();
                    BEGIN(INITIAL);
                }

<COMMENT>\n     {
                    countLines();
                }

<COMMENT>.      {
                    updateCol();
                }

<COMMENT><<EOF>> {
                    yyerror = "Unterminated comment";
                    yylineno = comment_start_line;
                    yycol = comment_start_col;
                    BEGIN(INITIAL);
                    return ERROR;
                }

 /* Other */
{newline}       {countLines();}
{whitespace}    {scancol += yyleng;}
.               {updateCol(); yyerror = "Illegal token"; return ILLEGAL_TOK;}

%%

/* user routines */

/* TODO:
Implement this function to keep track of column numbers
*/
void updateCol(void) {
    /* Set yycol and yylineno for the token we are about to return; advance scancol past this token. */
    yycol = scancol;
    yylineno = scanlineno;
    scancol += yyleng;
}

/* TODO:
Implement this function to keep track of line numbers
*/
void countLines(void) {
    scanlineno++;
    yycol = 1;
    scancol = 1;
}


/* TODO:
Implement this function to
check for illegal escape sequences in string literals
and
convert valid escape sequences into escaped characters
(string[0] == '\\' and string[1] == 'n', then string[0] should be '\n')
*/
int processString(void) {
    /* Buffer already holds string content (no quotes; escapes already converted in STRING rules).
     * Copy to yylval.str and return STRCONST so driver can print <STRING, "content"> : (line:col). */
    yylval.str = strdup(string_buf);
    if (yylval.str == NULL) {
        yyerror = "Out of memory";
        return ERROR;
    }
    return STRCONST;
}
