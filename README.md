# lisp
experimental lisp interpreter

## Grammar
```
NUMBER
    : [0-9]+
    ;

STRING
    : '"' ~'"'* '"'
    ;

SYMBOL
    : [a-zA-Z0-9_+-*/]+
    ;

program
    : expression* EOF
    ;

expression
    : atom | list
    ;

list
    : '(' expression* ')'
    ;

atom
    : NUMBER | STRING | SYMBOL
    ;
```
