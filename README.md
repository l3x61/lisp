# lisp
experimental lisp interpreter

## Grammar
```
NUMBER
    : // whatever std.fmt.parseFloat() accepts
    ;

STRING
    : '"' ~'"'* '"'
    ;

SYMBOL
    : [a-zA-Z0-9._+-*/=]+
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
