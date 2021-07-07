// Based on https://github.com/python/cpython/blob/3.9/Grammar/Grammar, available under the Python Software Foundation License v2.
// Broad changes & additions made to actions in order to ensure compatibility with PEG.js

{
  var indentLevel = 0;
  var singleIndentLen = 1;
}

// ========== Grammar ===========

file_input = prog:(NEWLINE / stmt / comment)* ENDMARKER { return { 
    type: "Program", 
    body: prog
        .filter(x=>x!==null)
        .map(x=>x==="\n"?{type:"BlankLine"}:x) 
  } 
}
eval_input = testlist NEWLINE* ENDMARKER

decorator = AT e:namedexpr_test NEWLINE { return { type: "Decorator", expr: e }; }
decorators = d:decorator+ { return {type: "Decorators", decorators: d }; }
decorated = d:decorators s:(funcdef / async_funcdef / classdef) { 
	return { type: "DecoratedCompoundStatement", decorators: d, stmt: s };
}

async_funcdef = ASYNC f:funcdef { return { type: "AsyncFunctionDefinition", funcdef: f }; }
funcdef = DEF n:NAME p:parameters (LAMBDA_ARROW t:test)? COLON tC:TYPE_COMMENT? b:suite {
    if(typeof t === "undefined") var t = "";
    return {
        type: "FunctionDefinition",
        parameters: p,
        typeType: t || tC,
        body: b,
        name: n
    }
}

parameters = OPEN_PAREN params:typedargslist? CLOSE_PAREN { 
  if(typeof params === "undefined") var params = [];
  if(params === null) params = [];
  return { 
    type: "Parameters", 
    params: params.filter(x=>x)
  }; 
}

arguments = head:argument tail:(COMMA TYPE_COMMENT? argument)* { 
    if(typeof tail === "undefined") {
        var tail = [];
    }
    return { type: "Arguments", arguments: [head].concat(tail.map(x=>x[2])) };
}
kwargs = DOUBLESTAR a:tfpdef COMMA? TYPE_COMMENT? { return { type: "KwArg", arg: a } }
args = STAR a:tfpdef? { return { type: "StarArg", arg: a }; }
kwonly_kwargs = (COMMA TYPE_COMMENT? argument)* (TYPE_COMMENT / (COMMA TYPE_COMMENT? kwargs?)?)
args_kwonly_kwargs = args kwonly_kwargs / kwargs
poskeyword_args_kwonly_kwargs = arguments ( TYPE_COMMENT / (COMMA TYPE_COMMENT? args_kwonly_kwargs?)?)
typedargslist_no_posonly  = a:(poskeyword_args_kwonly_kwargs / args_kwonly_kwargs) { return a; }
typedarglist = arguments COMMA TYPE_COMMENT? SLASH (COMMA (TYPE_COMMENT? typedargslist_no_posonly)?)?
/ typedargslist_no_posonly
typedargslist = t:typedarglist { return t; }
     
tfpdef = n:NAME t:(COLON test)? {
    if(t && t.length > 0) return { type: "TypedArgument", typeType: t[1], name: n };
    else return n;
}

vararglist_no_posonly = poskeyword_args_kwonly_kwargs / args_kwonly_kwargs
varargslist = a:arguments COMMA SLASH v:(COMMA vararglist_no_posonly)?  { 
            return {
                type: "VarArgsList",
                args: a,
                varargs: v && v[1]
            }
        }
	/ v:vararglist_no_posonly { return v; }

stmt = s:(simple_stmt / compound_stmt) com:comment? { if(com) return { type: "CommentedStatement", comment:com, statement: s }; else return s; }
simple_stmt = head:small_stmt tail:(SEMICOLON small_stmt)* (SEMICOLON)? { 
	if(tail && tail.length) return { type: "StatementList", list: [head].concat(tail.map(x=>x[1])) }; 
    else return head 
}
small_stmt = s:(del_stmt / pass_stmt / flow_stmt /
             import_stmt / global_stmt / nonlocal_stmt / assert_stmt / exec_stmt / print_stmt / expr_stmt) { return s; }

expr_stmt = expr:testlist_star_expr asgn:(annassign / augassign (yield_expr/testlist) /
                     asgn:( ass:(EQUALS y:(yield_expr/testlist_star_expr) { return y; })+ t:TYPE_COMMENT? { if(t) return { type:"TypedAssignment", type: t, assignment: ass }; else return ass;  })? ) {
                     if(asgn)
                     return {
                         type: "AssignmentExpressionStatement",
                         expr: expr,
                         asgn: asgn[0]
                     }
                     else return {
                         type: "ExpressionStatement",
                         expr: expr
                     }
                     }
annassign = COLON test (EQUALS (yield_expr/testlist_star_expr))?
testlist_star_expr = head:(test/star_expr) tail:(COMMA (test/star_expr))* COMMA? {
    if(tail && tail.length > 0) return {
        type: "TestList",
        list: [head].concat(tail.map(x=>x[1]))
    };
	else return head;
}
augassign = o:(PLUSEQUAL / MINEQUAL / STAREQUAL / ATEQUAL / SLASHEQUAL / PERCENTEQUAL / AMPEREQUAL / VBAREQUAL / CIRCUMFLEXEQUAL /
            LEFTSHIFTEQUAL / RIGHTSHIFTEQUAL / DOUBLESTAREQUAL / DOUBLESLASHEQUAL) { return o;  }
            
// For normal and annotated assignments, additional restrictions enforced by the interpreter
del_stmt = DEL e:exprlist { return { type: "DelStatement", exprlist: e } }
pass_stmt = PASS { return { type: "PassStatement" } }
flow_stmt = s:(break_stmt / continue_stmt / return_stmt / raise_stmt / yield_stmt) { return s; }
break_stmt = BREAK { return { type: "BreakStatement" } }
continue_stmt = CONTINUE { return { type: "ContinueStatement" } }
exec_stmt = EXEC expr:STRING ctx:(IN testlist_star_expr)? { return { type: "ExecStatement", value: expr, ctx: ctx?ctx[1]:ctx } }
return_stmt = RETURN expr:testlist_star_expr? { return { type:"ReturnStatement", value: expr }; }
print_stmt = PRINT expr:testlist_star_expr { return { type:"PrintStatement", value: expr }; }
yield_stmt = y:yield_expr { return { type: "YieldStatement", yielded: y } }
raise_stmt = RAISE v:(test (FROM test)?)? { return { type: "RaiseStatement", err: v&&v[0], context: v&&v[1]&&v[1][1] } }

import_stmt = t:(import_name / import_from) { return t; }
import_name = IMPORT i:dotted_as_names { return {type: "ImportNameStatement", imports: i}; }
// note below: the (DOT / ELLIPSIS) is necessary because ELLIPSIS is tokenized as ELLIPSIS
import_from = FROM ellips:(ELLIPSIS / DOT / DOUBLEDOT)* name:dotted_name? IMPORT
    from:(import_as_names / STAR / OPEN_PAREN import_as_names CLOSE_PAREN) { 
    if(from.constructor == Array && from.length == 3) from = from[1];
    return {
        type: "ImportFromStatement", 
        name: name,
        imprt: from,
        ellips: ellips.join("")
    } }
import_as_name = head:NAME tail:(AS NAME)? { if(!tail) return head; else { return { type:"DottedName", head: head, tail: tail.map(x=>x[1]) } }  }
dotted_as_name = head:dotted_name as:(AS NAME)? { if(!as || !as[0]) return head; else return { type: "AsName", target: head, as: as} }
import_as_names = head:import_as_name tail:(COMMA import_as_name)* COMMA? { return [head].concat(tail.map(x=>x[1]));  }
dotted_as_names = head:dotted_as_name tail:(COMMA dotted_as_name)* { return [head].concat(tail.map(x=>x[1]));  }
dotted_name = head:NAME tail:(DOT NAME)* { if(tail.length == 0) return head; else { return { type:"DottedName", head: head, tail: tail.map(x=>x[1]) } } }

global_stmt = GLOBAL head:NAME tail:(COMMA NAME)* { return { type: "GlobalStatement", names: [head].concat(tail.map(x=>x[1])) }; }
nonlocal_stmt = NONLOCAL head:NAME tail:(COMMA NAME)* { return { type: "NonlocalStatement", names: [head].concat(tail.map(x=>x[1])) }; }
assert_stmt = ASSERT t:test a:(COMMA test)? { return { type: "AssertStatement", test: t, alt: a&&a[1] }; }

compound_stmt = s:(if_stmt / while_stmt / for_stmt / try_stmt / with_stmt / funcdef / classdef / decorated / async_stmt) { return s; }
async_stmt = ASYNC s:(funcdef / with_stmt / for_stmt) { return { type: "AsyncStatement", stmt: s }; }
if_stmt = IF t:namedexpr_test COLON b:suite l:elif_block* e:(ELSE COLON suite)? {
    return {
        type: "IfStatement",
        body: b,
        test: t,
        elifBlocks: l,
        elseBlock: e  && e[2]
    };
}
elif_block = ELIF t:namedexpr_test COLON b:suite {
    return {
    	type: "ElifStatement",
        test: t,
        body: b
    };
}
while_stmt = WHILE t:namedexpr_test COLON b:suite e:(ELSE COLON suite)? {
	return {
    	type: "WhileStatement",
        test: t,
        body: b,
        elseBlock: e&&e[2]
    };
}
for_stmt = FOR v:exprlist IN l:testlist COLON TYPE_COMMENT? b:suite e:(ELSE COLON suite)? {
	return {
    	type: "ForStatement",
        vars: v,
        inList: l,
        body: b,
        elseBlock: e&&e[2]
    };
}
try_stmt = TRY COLON s:suite
           e:(x:(except_clause COLON suite)+
            l:(ELSE COLON suite)?
            f:(FINALLY COLON suite)? 
            { return { type: "CatchBlock", finallyBlock: f&&f[2], elseBlock: l&&l[2], exceptBlocks: x.map(x=>x[2])  }}
            /
           FINALLY COLON f:suite { return { type: "CatchBlock", finallyBlock: f };} ) {
               return {
               	type: "TryStatement",
                body: s,
                catchBlock: e
               }
           }

with_stmt = WITH w:(with_item_list / with_item) COLON s:suite {
		return {type: "WithStatement", body: s, withItem: w};
	}
with_item_list = OPEN_PAREN head:with_item tail:(COMMA with_item )+ CLOSE_PAREN { return { type: "WithItemList", list: [head].concat(tail.map(x=>x[1])) } }
with_item = v:test a:(AS expr)? { 
		if(a && a.length > 0) return { type: "WithAsItem", value: v, as: a[1] } 
        else return { type: "WithItem", value: v };
    }
except_clause = EXCEPT head:except_clause_param? tail:(COMMA except_clause_param?)* {
    return {
        type: "ExceptClause",
        params: head?[head].concat(tail.map(x=>x[1])):[]
    }
}
except_clause_param = t:test a:(AS NAME)? {
    return {
        type:"ExceptClauseParam",
        param: t,
        as: a&&a[1]
    }
}
suite = simp:simple_stmt / NEWLINE INDENT body:(SAMEDENT st:(NEWLINE/stmt NEWLINE?) )+ DEDENT {
    if(body[0] == "") body = body[1];

    if(typeof simp !== "undefined") return simp;
    else return {
        type: "Suite",
        body: body.map(function(x) {
            if(x[1] == "\n") return {type:"BlankLine"};
            else return x[1][0];
        })
    }
}

namedexpr_test = t:test n:(COLONEQUAL test)? { 
    if(n && n.length > 0) return {type: "NamedExpression", expr: t, value: n[1]}
    else return t;
  }
test = or:or_test conditional:(IF __ or_test ELSE test)? {
	if(typeof conditional !== "undefined" && conditional != null)
      return { 
      	type: "ConditionalExpression", 
        condition: conditional[2],
        value: or,
        alternate: conditional[5] 
      };
  
  return or
}
  / lambdef:lambdef
{
      return {
        type: "LambdaExpression",
        lambda: lambdef
      };
}
test_nocond = or_test / lambdef_nocond
lambdef = LAMBDA varargslist? COLON test
lambdef_nocond = LAMBDA varargslist? COLON test_nocond
or_test = head:and_test tail:(OR and_test)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "BooleanComparison",
        left: head,
        operator: "or",
        right: tail.map(x=>x[1])
    }
}
and_test = head:not_test tail:(AND not_test)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "BooleanComparison",
        left: head,
        operator: "and",
        right: tail.map(x=>x[1])
    }
}
not_test = NOT head:not_test {
return {
    type: "UnaryOperator",
    operator: "not ",
    value: head
}
} / c:comparison { return c } 

comparison = head:expr tail:(comp_op expr)* {
    if(tail == null || tail.length == 0) return head;
    else return {
    	type: "Comparison",
        left: head,
        right: tail.map(x=> ({
          operator: x[0],
          right: x[1]
        }))
      };
}
// <> isn't actually a valid comparison operator in Python. It's here for the
// sake of a __future__ import described in PEP 401 (which really works :-)
comp_op = l:(DOUBLE_EQUALS/GREATEREQUAL/LESSEQUAL/NOTEQUAL_EXCEL/LESS/GREATER/NOTEQUAL/IN/NOT IN/IS/IS NOT) {
    return l;
}
star_expr = STAR expr:expr { return { type: "StarExpression", expr: expr }; }
expr = head:xor_expr tail:(VBAR xor_expr)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: "|"}, value: x[1]}))
    }
}
xor_expr = head:and_expr tail:(CIRCUMFLEX and_expr)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: left,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: "^"}, value: x[1]}))
    }
}
and_expr = head:shift_expr tail:(AMPER shift_expr)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: "&"}, value: x[1]}))
    }
}
shift_expr = head:arith_expr tail:(( LEFTSHIFT / RIGHTSHIFT) arith_expr)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: x[0]}, value: x[1]}))
    }
}
arith_expr = head:term tail:((PLUS/MINUS) term)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: x[0]}, value: x[1]}))
    }
}
term = head:factor tail:((STAR/AT/SLASH/PERCENT/DOUBLESLASH) factor)* {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: tail.map(x=>({ type: "OperatorExpressionTail", operator: {type: "Operator", value: x[0]}, value: x[1]}))
    }
}
factor = op:(PLUS/MINUS/TILDE) head:factor {
    return {
        type: "UnaryOperator",
        left: head,
        value: op
    }
} / p:power { return p; }
power = head:atom_expr tail:(DOUBLESTAR factor)? {
    if(tail == null || tail.length == 0) return head;
    else return {
        type: "OperatorExpression",
        left: head,
        right: [{ type: "OperatorExpressionTail", operator: {type: "Operator", value: tail[0]}, value: tail[1]}]
    }
}
atom_expr = a:AWAIT? l:atom t:trailer* {
     var ty = a ? "AsyncValue" : "Value";
     if(t && t.length > 0) return { type: ty,value: l[0]||l, trailers: t};
     else return {type: ty, value: l[0]||l};
}
atom = l:(OPEN_PAREN v:(yield_expr/testlist_comp)? CLOSE_PAREN { return { type: "ParenWrappedValue", value: v }; } /
       OPEN_SQUARE_BRACKET v:testlist_comp? CLOSE_SQUARE_BRACKET { return { type: "ListLiteral", value: v }; } /
       OPEN_CURLY_BRACKET v:dictorsetmaker? CLOSE_CURLY_BRACKET { return { type: "DictionaryOrSetLiteral", value: v }; } /
       NAME / NUMBER / STRING+ / ELLIPSIS / NONE_LITERAL / TRUE /FALSE) {
           return l;
       }
testlist_comp = head:(namedexpr_test/star_expr) tail:( comp_for / v:(COMMA f:(namedexpr_test/star_expr) { return f; })* COMMA? { return v }) { 
    return {
        type: "ListComp",
        list: [head].concat(tail)
    }
}

trailer = OPEN_PAREN a:arglist? CLOSE_PAREN { return { type: "FunctionCallerParams", args: a }; } /
	OPEN_SQUARE_BRACKET s:subscriptlist CLOSE_SQUARE_BRACKET { return { type: "SubscriptParams", subscripts: s }; }
    / DOT n:NAME { return { type: "DotProperty", property: n } }
subscriptlist = head:subscript tail:(COMMA subscript)* COMMA? {
  return {
    type: "SubscriptList",
    list: [head].concat(x=>x[1])
  };
}
subscript = test / l:test? COLON r:test? s:sliceop? { return { type: "Subscript", left: l, right: r, slice: s } }
sliceop = COLON e:test? { return { type: "SliceOp", expr: e} }
exprlist = head:(expr/star_expr) tail:(COMMA (expr/star_expr))* COMMA? { return { 
        type: "ExprList",
        list: [head].concat(tail.map(x=>x[1]))
    } }
testlist = head:test tail:(COMMA test)* COMMA? {
    return { 
        type: "TestList",
        list: [head].concat(tail.map(x=>x[1]))
    }
}
dictorsetmaker = ( ((test COLON test / DOUBLESTAR expr)
                   (comp_for / (COMMA (test COLON test / DOUBLESTAR expr))* COMMA?)) /
                  ((test / star_expr)
                   (comp_for / (COMMA (test / star_expr))* COMMA?)) )

classdef = CLASS n:NAME p:(OPEN_PAREN arglist? CLOSE_PAREN)? COLON b:suite {
    return {
      type: "ClassDefinition",
      name: n,
      params: p && p[1],
      body: b
    }
}

arglist = head:argument tail:(COMMA argument)*  COMMA? {
    return {
        type: "Arglist",
        args: [head].concat(tail.map(x=>x[1]))
    };
}

argument = a:(left:test op:COLONEQUAL right:test { return { type: "ExpressionAssignmentDefaultValueArg", argument: left, defaultVal: right }; } /
		    left:test compFor:comp_for? { 
				if(compFor) return { type: "ForInArgument", arg: left, compFor: compFor };
                else return { type: "Argument", arg: left}; } /
            left:test op:EQUALS right:test { return { type: "DefaultValueArg", argument: left, defaultVal: right }; } /
            op:DOUBLESTAR left:tfpdef { return {type: "KwVarArg", argument: left}; } /
            op:STAR left:tfpdef { return {type: "VarArg", argument: left}; } /
            STAR { return { type: "PositionOnlyArgsMarkerArg" }; }) t:(COLON test)? d:(EQUALS test)? {
               var result = a;
               if(d && d.length > 0) return { type: "DefaultArgument", default: d[1], arg: result }; 
               if(t && t.length > 0) return { type: "TypedArgument", type: t[1], arg: result };
               
               return result;
              } 
            

comp_iter = t:comp_for { return t; } / t:comp_if { return t; }
sync_comp_for = FOR exprlist IN or_test comp_iter?
comp_for = ASYNC? sync_comp_for
comp_if = IF __ test_nocond comp_iter?

yield_expr = YIELD yield_arg?
yield_arg = FROM test / testlist_star_expr

comment = c:COMMENT { return { type: "Comment", comment: c}; }

// typelist is a modified typedargslist (see above)
typelist = (test (COMMA test)* (COMMA
       (STAR test? (COMMA test)* (COMMA DOUBLESTAR test)? / DOUBLESTAR test)?)?
     /  STAR test? (COMMA test)* (COMMA DOUBLESTAR test)? / DOUBLESTAR test)
     
     
// =========== Token ============


SAMEDENT = (i:tabs &{
      return i.length == 0 || i.length / singleIndentLen === indentLevel;
    }) { return ""; }

INDENT
= &(t:tabs &{
      if(indentLevel == 0 && t.length > 0) singleIndentLen = t.length

      var newIndent = t.length / singleIndentLen;
      var oldIndent = indentLevel;
      
      if(newIndent > oldIndent) indentLevel++; 
      return newIndent > oldIndent;
    } { return ""; })

DEDENT
= &(t:tabs &{
      var newIndent = t.length / singleIndentLen;
      var oldIndent = indentLevel;

      if(newIndent <= oldIndent) indentLevel--; 
      return newIndent <= oldIndent;
    } { return ""; })
    
tabs
  = t:tab* { return t; }

tab
  = t:("\t" / "  ") { return t; }

STRING
  = l:(DOUBLE_QUOTE doubleqstringitem* DOUBLE_QUOTE !DOUBLE_QUOTE / SINGLE_QUOTE singleqstringitem* SINGLE_QUOTE) {
      var val = l[0] + l[1].join("") + l[2];
      return {
          type: "StringLiteral",
          value: val
      };
  } / m:MULTILINE_STRING { return {type: "MultilineStringLiteral", value: m }; }

doubleqstringitem
  = l:(doubleqstringchar / escapeseq) {
      return l;
  }

singleqstringitem
  = l:(singleqstringchar / escapeseq) {
      return l;
  }

doubleqstringchar = l:[^\\"] {
    return l;
}

singleqstringchar = l:[^\\'] {
    return l;
}

escapeseq
  = l:("\\" [\\'"abfnrtv]) { 
      if(typeof l.join == "function") return l.join("");
      else return l;
    }

MULTILINE_STRING = DOUBLE_QUOTE DOUBLE_QUOTE DOUBLE_QUOTE 
	com:MULTILINE_STRING_CHARACTER+
	DOUBLE_QUOTE DOUBLE_QUOTE DOUBLE_QUOTE 
    { return com.join(""); }
    
MULTILINE_STRING_BORDER = DOUBLE_QUOTE DOUBLE_QUOTE DOUBLE_QUOTE 

MULTILINE_STRING_CHARACTER = !MULTILINE_STRING_BORDER c:. { return c; }

NUMBER
  = l:('-'? ('0o' / '0x')? (DOT [0-9]+ / [0-9]+ DOT [0-9]+ / [0-9]+)) {
      function j(arr) {
          if(arr === null) return "";
          if(!arr.join) return arr||"";
          else return arr.map(x=>j(x)).join("");
      }
      return {
          type: "NumericLiteral",
          value: j(l)
      }
  }

NEWLINE
  = com:comment? ('\r\n' / '\n' / '\r') { if(com) return com; else return "\n"; }

COMMENT = '#' com:[^\n]+ { return com.join(""); }

__
  = [ ]+

_
  = [ ]*

EOF
  = !.
  
ENDMARKER = EOF


TYPE_COMMENT = COMMENT

AWAIT = "await"

EOL
  = "\r\n" / "\n" / "\r"
  AT = _ '@' _ { return '@' }
ASYNC = _ "async" _ { return "async" }
DEF = "def" __ { return "def" }
LAMBDA_ARROW = _ "->" _ { return "->" }
COLON = _ ":" _ { return ":" }
OPEN_PAREN = _ "(" _ { return "(" }
CLOSE_PAREN = _ ")" _ { return ")" }
EQUALS = _ "=" _ { return "=" }
COMMA = _ "," _ { return "," }
SLASH = _ "/" _ { return "/" }
STAR = _ "*" _ { return "*" }
DOUBLESTAR = _ "**" _ { return "**" }
SEMICOLON = _ ";" _ { return ";" }
PLUSEQUAL = _ "+=" _ { return "+=" }
MINEQUAL = _ "-=" _ { return "-=" }
STAREQUAL = _ "*=" _ { return "*=" }
ATEQUAL = _ "@=" _ { return "@=" }
SLASHEQUAL = _ "/=" _ { return "/=" }
PERCENTEQUAL = _ "%=" _ { return "%=" }
AMPEREQUAL = _ "&=" _ { return "&=" }
VBAREQUAL = _ "|=" _ { return "|=" }
CIRCUMFLEXEQUAL = _ "^=" _ { return "^=" }
LEFTSHIFTEQUAL = _ "<<=" _ { return "<<=" }
RIGHTSHIFTEQUAL = _ ">>=" _ { return ">>=" }
DOUBLESTAREQUAL = _ "**=" _ { return "**=" }
DOUBLESLASHEQUAL = _ "//=" _ { return "//=" }
EXEC = _ "exec" _ { return "exec"; }
DEL = _ "del" _ { return "del" }
PASS =  _ "pass" _ { return "pass" }
BREAK = _ "break" _ { return "break" }
CONTINUE = "continue" { return "continue" }
RETURN = _ "return" _ { return "return" }
RAISE = _ "raise" _ { return "raise" }
FROM = _ "from" _ { return "from" }
IMPORT = _ "import" _ { return "import" }
DOT = _ "." _ { return "." }
DOUBLEDOT = _ '..' _ { return ".." }
ELLIPSIS = _ "..." _ { return "..." }
AS = _ "as" _ { return "as" }
GLOBAL = _ "global" _ { return "global" }
NONLOCAL = _ "nonlocal" _ { return "nonlocal" }
ASSERT = _ "assert" _ { return "assert" }
IF = _ "if" _ { return "if" }
ELIF = _ "elif" _ { return "elif" }
ELSE = _ "else" _ { return "else" }
WHILE = "while" _ { return "while" }
PRINT = "print" _ { return "print" }
FOR = "for" _ { return "for" }
IN = _ "in" _ { return "in" }
TRY = "try" _ { return "try" }
FINALLY = "finally" _ { return "finally" }
WITH = "with" _ { return "with" }
EXCEPT = "except" { return "except" }
COLONEQUAL = ":=" { return ":=" }
LAMBDA = "lambda" { return "lambda" }
OR = _ "or" _ { return "or" }
AND = _ "and" _ { return "and" }
NOT = _ "not" _ { return "not" }
LESS = _ "<" _ { return "<" }
GREATER = _ ">" _ { return ">" }
DOUBLE_EQUALS = _ "==" _ { return "==" }
GREATEREQUAL = _ ">=" _ { return ">=" }
LESSEQUAL = _ "<=" _ { return "<=" }
NOTEQUAL_EXCEL = _ "<>" _ { return "<>" }
NOTEQUAL = _ "!=" _ { return "!=" }
IS = _ "is" _ { return "is" }
VBAR = _ "|" _ { return "|" }
CIRCUMFLEX = _ "^" _ { return "^" }
AMPER = _ "&" _ { return "&" }
LEFTSHIFT = _ "<<" _ { return "<<" }
RIGHTSHIFT = _ ">>" _ { return ">>" }
PLUS = _ "+" _ { return "+" }
MINUS = _ "-" _ { return "-" }
PERCENT = _ "%" _ { return "%" }
DOUBLESLASH = _ "//" _ { return "//" }
TILDE = _ "~" _ { return "~" }
OPEN_SQUARE_BRACKET = _ "[" _ { return "[" }
CLOSE_SQUARE_BRACKET = _ "]" _ { return "]" }
OPEN_CURLY_BRACKET = _ "{" _ { return "{}".substring(0,1); }
CLOSE_CURLY_BRACKET = _ "}" _ { return "{}".substring(1,2); }
NONE_LITERAL = _ "None" _ { return "None" }
TRUE = _ "True" _ { return {type: "BooleanLiteral", value: "True"}; }
FALSE = _ "False" _ { return {type: "BooleanLiteral", value: "False"}; }
CLASS = _ "class" _ { return "class" }
YIELD = _ "yield" _ { return "yield" }
RARROW = _ "->" _ { return "->" }
DOUBLE_QUOTE = _ '"' _ { return '"'; }
SINGLE_QUOTE = _ "'" _ { return "'"; }

NAME
  = _ head:[a-zA-Z_] tail:[a-zA-Z0-9_]* _
    &{
    var name = head + tail.join("");
    var reserved = ["and","as","assert","break","class","continue","def","del","elif",
    				"else","except","finally","for","from","global","if","import","in","is",
                    "lambda","None","nonlocal","not","or","pass","raise","return","try","while",
                    "with","yield","False","True"];
    if(reserved.indexOf(name) == -1) return true;
    else return false;
    }
    { return {
    	type: "Identifier",
        value: head + tail.join("")
      }; 
    }