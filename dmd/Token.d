module dmd.Token;
/++ This file has a number of basic definitions and initializations +/
/++ including the following:  +/
/+
    enum TOK
    enum PREC
    struct Token
    struct Keyword
    enum keywords
    tochars[TOKMAX]
    PREC[TOKMAX] precedence;
+/

import dmd.Identifier;

import std.conv;
import std.array; // appender
import std.encoding; // codePoints, useful for utf strings
import std.format; //  formattedWrite (appender, "what %s", s);

//static PREC[TOKMAX] precedence;

// I need to get it to recognize TOKMAX as a legit identifier
// Maybe if I put it down here....
// static string[TOKMAX] tochars;

/+ This enum will NOT be detected below +/
/+ Therefore it is reproduced in module dmd.TokenBUG; +/
/+ where it seems to work +/
alias int TOK;
enum 
{
   TOKreserved,

   // Other
   TOKlparen,	TOKrparen,
   TOKlbracket,	TOKrbracket,
   TOKlcurly,	TOKrcurly,
   TOKcolon,	TOKneg,
   TOKsemicolon,	TOKdotdotdot,
   TOKeof,		TOKcast,
   TOKnull,	TOKassert,
   TOKtrue,	TOKfalse,
   TOKarray,	TOKcall,
   TOKaddress,
   TOKtype,	TOKthrow,
   TOKnew,		TOKdelete,
   TOKstar,	TOKsymoff,
   TOKvar,		TOKdotvar,
   TOKdotti,	TOKdotexp,
   TOKdottype,	TOKslice,
   TOKarraylength,	TOKversion,
   TOKmodule,	TOKdollar,
   TOKtemplate,	TOKdottd,
   TOKdeclaration,	TOKtypeof,
   TOKpragma,	TOKdsymbol,
   TOKtypeid,	TOKuadd,
   TOKremove,
   TOKnewanonclass, TOKcomment,
   TOKarrayliteral, TOKassocarrayliteral,
   TOKstructliteral,

   // Operators
   TOKlt,		TOKgt,
   TOKle,		TOKge,
   TOKequal,	TOKnotequal,
   TOKidentity,	TOKnotidentity,
   TOKindex,	TOKis,
   TOKtobool,

   // 60
   // NCEG floating point compares
   // !<>=     <>    <>=    !>     !>=   !<     !<=   !<>
   TOKunord, TOKlg, TOKleg, TOKule, TOKul, TOKuge, TOKug, TOKue,

   TOKshl,		TOKshr,
   TOKshlass,	TOKshrass,
   TOKushr,	TOKushrass,
   TOKcat,		TOKcatass,	// ~ ~=
   TOKadd,		TOKmin,		TOKaddass,	TOKminass,
   TOKmul,		TOKdiv,		TOKmod,
   TOKmulass,	TOKdivass,	TOKmodass,
   TOKand,		TOKor,		TOKxor,
   TOKandass,	TOKorass,	TOKxorass,
   TOKassign,	TOKnot,		TOKtilde,
   TOKplusplus,	TOKminusminus,	TOKconstruct,	TOKblit,
   TOKdot,		TOKarrow,	TOKcomma,
   TOKquestion,	TOKandand,	TOKoror,
   // 104
   // Numeric literals
   TOKint32v, TOKuns32v,
   TOKint64v, TOKuns64v,
   TOKfloat32v, TOKfloat64v, TOKfloat80v,
   TOKimaginary32v, TOKimaginary64v, TOKimaginary80v,

   // Char constants
   TOKcharv, TOKwcharv, TOKdcharv,

   // Leaf operators
   TOKidentifier,	TOKstring,
   TOKthis,	TOKsuper,
   TOKhalt,	TOKtuple,
   TOKerror,

   // Basic types
   TOKvoid,
   TOKint8, TOKuns8,
   TOKint16, TOKuns16,
   TOKint32, TOKuns32,
   TOKint64, TOKuns64,
   TOKfloat32, TOKfloat64, TOKfloat80,
   TOKimaginary32, TOKimaginary64, TOKimaginary80,
   TOKcomplex32, TOKcomplex64, TOKcomplex80,
   TOKchar, TOKwchar, TOKdchar, TOKbit, TOKbool,
   TOKcent, TOKucent,

   // Aggregates
   TOKstruct, TOKclass, TOKinterface, TOKunion, TOKenum, TOKimport,
   TOKtypedef, TOKalias, TOKoverride, TOKdelegate, TOKfunction,
   TOKmixin,

   TOKalign, TOKextern, TOKprivate, TOKprotected, TOKpublic, TOKexport,
   TOKstatic, /*virtual,*/ TOKfinal, TOKconst, TOKabstract, TOKvolatile,
   TOKdebug, TOKdeprecated, TOKin, TOKout, TOKinout, TOKwild = TOKinout,
   TOKlazy, TOKauto, TOKpackage, TOKmanifest, TOKimmutable,

   // Statements
   TOKif, TOKelse, TOKwhile, TOKfor, TOKdo, TOKswitch,
   TOKcase, TOKdefault, TOKbreak, TOKcontinue, TOKwith,
   TOKsynchronized, TOKreturn, TOKgoto, TOKtry, TOKcatch, TOKfinally,
   TOKasm, TOKforeach, TOKforeach_reverse,
   TOKscope,
   TOKon_scope_exit, TOKon_scope_failure, TOKon_scope_success,

   // Contracts
   TOKbody, TOKinvariant,

   // Testing
   TOKunittest,

   // Added after 1.0
   TOKref,
   TOKmacro,

   TOKtraits,
   TOKoverloadset,
   TOKpure,
   TOKnothrow,
   TOKtls,
   TOKgshared,
   TOKline,
   TOKfile,
   TOKshared,
   TOKat,
   TOKpow,
   TOKpowass,
   TOKMAX
}

struct Keyword { string name; TOK value; }
enum Keyword[] keywords =
[
//    {	"",		TOK	},

{	"this",		TOKthis		},
{	"super",	TOKsuper	},
{	"assert",	TOKassert	},
{	"null",		TOKnull		},
{	"true",		TOKtrue		},
{	"false",	TOKfalse	},
{	"cast",		TOKcast		},
{	"new",		TOKnew		},
{	"delete",	TOKdelete	},
{	"throw",	TOKthrow	},
{	"module",	TOKmodule	},
{	"pragma",	TOKpragma	},
{	"typeof",	TOKtypeof	},
{	"typeid",	TOKtypeid	},

{	"template",	TOKtemplate	},

{	"void",		TOKvoid		},
{	"byte",		TOKint8		},
{	"ubyte",	TOKuns8		},
{	"short",	TOKint16	},
{	"ushort",	TOKuns16	},
{	"int",		TOKint32	},
{	"uint",		TOKuns32	},
{	"long",		TOKint64	},
{	"ulong",	TOKuns64	},
{	"cent",		TOKcent,	},
{	"ucent",	TOKucent,	},
{	"float",	TOKfloat32	},
{	"double",	TOKfloat64	},
{	"real",		TOKfloat80	},

{	"bool",		TOKbool		},
{	"char",		TOKchar		},
{	"wchar",	TOKwchar	},
{	"dchar",	TOKdchar	},

{	"ifloat",	TOKimaginary32	},
{	"idouble",	TOKimaginary64	},
{	"ireal",	TOKimaginary80	},

{	"cfloat",	TOKcomplex32	},
{	"cdouble",	TOKcomplex64	},
{	"creal",	TOKcomplex80	},

{	"delegate",	TOKdelegate	},
{	"function",	TOKfunction	},

{	"is",		TOKis		},
{	"if",		TOKif		},
{	"else",		TOKelse		},
{	"while",	TOKwhile	},
{	"for",		TOKfor		},
{	"do",		TOKdo		},
{	"switch",	TOKswitch	},
{	"case",		TOKcase		},
{	"default",	TOKdefault	},
{	"break",	TOKbreak	},
{	"continue",	TOKcontinue	},
{	"synchronized",	TOKsynchronized	},
{	"return",	TOKreturn	},
{	"goto",		TOKgoto		},
{	"try",		TOKtry		},
{	"catch",	TOKcatch	},
{	"finally",	TOKfinally	},
{	"with",		TOKwith		},
{	"asm",		TOKasm		},
{	"foreach",	TOKforeach	},
{	"foreach_reverse",	TOKforeach_reverse	},
{	"scope",	TOKscope	},

{	"struct",	TOKstruct	},
{	"class",	TOKclass	},
{	"interface",	TOKinterface	},
{	"union",	TOKunion	},
{	"enum",		TOKenum		},
{	"import",	TOKimport	},
{	"mixin",	TOKmixin	},
{	"static",	TOKstatic	},
{	"final",	TOKfinal	},
{	"const",	TOKconst	},
{	"typedef",	TOKtypedef	},
{	"alias",	TOKalias	},
{	"override",	TOKoverride	},
{	"abstract",	TOKabstract	},
{	"volatile",	TOKvolatile	},
{	"debug",	TOKdebug	},
{	"deprecated",	TOKdeprecated	},
{	"in",		TOKin		},
{	"out",		TOKout		},
{	"inout",	TOKinout	},
{	"lazy",		TOKlazy		},
{	"auto",		TOKauto		},

{	"align",	TOKalign	},
{	"extern",	TOKextern	},
{	"private",	TOKprivate	},
{	"package",	TOKpackage	},
{	"protected",	TOKprotected	},
{	"public",	TOKpublic	},
{	"export",	TOKexport	},

{	"body",		TOKbody		},
{	"invariant",	TOKinvariant	},
{	"unittest",	TOKunittest	},
{	"version",	TOKversion	},
    //{	"manifest",	TOKmanifest	},

    // Added after 1.0
{	"ref",		TOKref		},
{	"macro",	TOKmacro	},
{	"pure",		TOKpure		},
{	"nothrow",	TOKnothrow	},
{	"__thread",	TOKtls		},
{	"__gshared",	TOKgshared	},
{	"__traits",	TOKtraits	},
{	"__overloadset", TOKoverloadset	},
{	"__FILE__",	TOKfile		},
{	"__LINE__",	TOKline		},
{	"shared",	TOKshared	},
{	"immutable",	TOKimmutable	},
    ];


void initTochars()
{
    with ( Token )
    {
        foreach ( k; keywords )
            tochars[k.value] = k.name;

        tochars[TOKlt]		= "<";
        tochars[TOKgt]		= ">";
        tochars[TOKle]		= "<=";
        tochars[TOKge]		= ">=";
        tochars[TOKequal]		= "==";
        tochars[TOKnotequal]		= "!=";
        tochars[TOKnotidentity]	= "!is";
        tochars[TOKtobool]		= "!!";

        tochars[TOKunord]		= "!<>=";
        tochars[TOKue]		= "!<>";
        tochars[TOKlg]		= "<>";
        tochars[TOKleg]		= "<>=";
        tochars[TOKule]		= "!>";
        tochars[TOKul]		= "!>=";
        tochars[TOKuge]		= "!<";
        tochars[TOKug]		= "!<=";

        tochars[TOKnot]		= "!";
        tochars[TOKtobool]		= "!!";
        tochars[TOKshl]		= "<<";
        tochars[TOKshr]		= ">>";
        tochars[TOKushr]		= ">>>";
        tochars[TOKadd]		= "+";
        tochars[TOKmin]		= "-";
        tochars[TOKmul]		= "*";
        tochars[TOKdiv]		= "/";
        tochars[TOKmod]		= "%";
        tochars[TOKslice]		= "..";
        tochars[TOKdotdotdot]	= "...";
        tochars[TOKand]		= "&";
        tochars[TOKandand]		= "&&";
        tochars[TOKor]		= "|";
        tochars[TOKoror]		= "||";
        tochars[TOKarray]		= "[]";
        tochars[TOKindex]		= "[i]";
        tochars[TOKaddress]		= "&";
        tochars[TOKstar]		= "*";
        tochars[TOKtilde]		= "~";
        tochars[TOKdollar]		= "$";
        tochars[TOKcast]		= "cast";
        tochars[TOKplusplus]		= "++";
        tochars[TOKminusminus]	= "--";
        tochars[TOKtype]		= "type";
        tochars[TOKquestion]		= "?";
        tochars[TOKneg]		= "-";
        tochars[TOKuadd]		= "+";
        tochars[TOKvar]		= "var";
        tochars[TOKaddass]		= "+=";
        tochars[TOKminass]		= "-=";
        tochars[TOKmulass]		= "*=";
        tochars[TOKdivass]		= "/=";
        tochars[TOKmodass]		= "%=";
        tochars[TOKshlass]		= "<<=";
        tochars[TOKshrass]		= ">>=";
        tochars[TOKushrass]		= ">>>=";
        tochars[TOKandass]		= "&=";
        tochars[TOKorass]		= "|=";
        tochars[TOKcatass]		= "~=";
        tochars[TOKcat]		= "~";
        tochars[TOKcall]		= "call";
        tochars[TOKidentity]		= "is";
        tochars[TOKnotidentity]	= "!is";

        tochars[TOKorass]		= "|=";
        tochars[TOKidentifier]	= "identifier";
        tochars[TOKat]		= "@";
        tochars[TOKpow]		= "^^";
        tochars[TOKpowass]		= "^^=";

        // For debugging
        tochars[TOKerror]		= "error";
        tochars[TOKdotexp]		= "dotexp";
        tochars[TOKdotti]		= "dotti";
        tochars[TOKdotvar]		= "dotvar";
        tochars[TOKdottype]		= "dottype";
        tochars[TOKsymoff]		= "symoff";
        tochars[TOKarraylength]	= "arraylength";
        tochars[TOKarrayliteral]	= "arrayliteral";
        tochars[TOKassocarrayliteral] = "assocarrayliteral";
        tochars[TOKstructliteral]	= "structliteral";
        tochars[TOKstring]		= "string";
        tochars[TOKdsymbol]		= "symbol";
        tochars[TOKtuple]		= "tuple";
        tochars[TOKdeclaration]	= "declaration";
        tochars[TOKdottd]		= "dottd";
        tochars[TOKon_scope_exit]	= "scope(exit)";
        tochars[TOKon_scope_success]	= "scope(success)";
        tochars[TOKon_scope_failure]	= "scope(failure)";
    }
}

alias int PREC;
static PREC[TOKMAX] precedence;
// Operator precedence - greater values are higher precedence
enum 
{
    PREC_zero,
    PREC_expr,
    PREC_assign,
    PREC_cond,
    PREC_oror,
    PREC_andand,
    PREC_or,
    PREC_xor,
    PREC_and,
    PREC_equal,
    PREC_rel,
    PREC_shift,
    PREC_add,
    PREC_mul,
    PREC_pow,
    PREC_unary,
    PREC_primary,
}


/**********************************
 * Set operator precedence for each operator.
 */
bool initPrecedence()
{
    precedence[TOKdotvar] = PREC_primary;
    precedence[TOKimport] = PREC_primary;
    precedence[TOKidentifier] = PREC_primary;
    precedence[TOKthis] = PREC_primary;
    precedence[TOKsuper] = PREC_primary;
    precedence[TOKint64] = PREC_primary;
    precedence[TOKfloat64] = PREC_primary;
    precedence[TOKnull] = PREC_primary;
    precedence[TOKstring] = PREC_primary;
    precedence[TOKarrayliteral] = PREC_primary;
    precedence[TOKtypeid] = PREC_primary;
    precedence[TOKis] = PREC_primary;
    precedence[TOKassert] = PREC_primary;
    precedence[TOKfunction] = PREC_primary;
    precedence[TOKvar] = PREC_primary;
    precedence[TOKdefault] = PREC_primary;


    // post
    precedence[TOKdotti] = PREC_primary;
    precedence[TOKdot] = PREC_primary;
    //  precedence[TOKarrow] = PREC_primary;
    precedence[TOKplusplus] = PREC_primary;
    precedence[TOKminusminus] = PREC_primary;
    precedence[TOKcall] = PREC_primary;
    precedence[TOKslice] = PREC_primary;
    precedence[TOKarray] = PREC_primary;

    precedence[TOKaddress] = PREC_unary;
    precedence[TOKstar] = PREC_unary;
    precedence[TOKneg] = PREC_unary;
    precedence[TOKuadd] = PREC_unary;
    precedence[TOKnot] = PREC_unary;
    precedence[TOKtobool] = PREC_add;
    precedence[TOKtilde] = PREC_unary;
    precedence[TOKdelete] = PREC_unary;
    precedence[TOKnew] = PREC_unary;
    precedence[TOKcast] = PREC_unary;

    precedence[TOKpow] = PREC_pow;

    precedence[TOKmul] = PREC_mul;
    precedence[TOKdiv] = PREC_mul;
    precedence[TOKmod] = PREC_mul;
    precedence[TOKpow]     = PREC_mul;

    precedence[TOKadd] = PREC_add;
    precedence[TOKmin] = PREC_add;
    precedence[TOKcat] = PREC_add;

    precedence[TOKshl] = PREC_shift;
    precedence[TOKshr] = PREC_shift;
    precedence[TOKushr] = PREC_shift;

    precedence[TOKlt] = PREC_rel;
    precedence[TOKle] = PREC_rel;
    precedence[TOKgt] = PREC_rel;
    precedence[TOKge] = PREC_rel;
    precedence[TOKunord] = PREC_rel;
    precedence[TOKlg] = PREC_rel;
    precedence[TOKleg] = PREC_rel;
    precedence[TOKule] = PREC_rel;
    precedence[TOKul] = PREC_rel;
    precedence[TOKuge] = PREC_rel;
    precedence[TOKug] = PREC_rel;
    precedence[TOKue] = PREC_rel;
    precedence[TOKin] = PREC_rel;

    /* Note that we changed precedence, so that < and != have the same
     * precedence. This change is in the parser, too.
     */
    precedence[TOKequal] = PREC_rel;
    precedence[TOKnotequal] = PREC_rel;
    precedence[TOKidentity] = PREC_rel;
    precedence[TOKnotidentity] = PREC_rel;

    precedence[TOKand] = PREC_and;

    precedence[TOKxor] = PREC_xor;

    precedence[TOKor] = PREC_or;

    precedence[TOKandand] = PREC_andand;

    precedence[TOKoror] = PREC_oror;

    precedence[TOKquestion] = PREC_cond;

    precedence[TOKassign] = PREC_assign;
    precedence[TOKconstruct] = PREC_assign;
    precedence[TOKblit] = PREC_assign;
    precedence[TOKaddass] = PREC_assign;
    precedence[TOKminass] = PREC_assign;
    precedence[TOKcatass] = PREC_assign;
    precedence[TOKmulass] = PREC_assign;
    precedence[TOKdivass] = PREC_assign;
    precedence[TOKmodass] = PREC_assign;
    precedence[TOKpowass]   = PREC_assign;
    precedence[TOKshlass] = PREC_assign;
    precedence[TOKshrass] = PREC_assign;
    precedence[TOKushrass] = PREC_assign;
    precedence[TOKandass] = PREC_assign;
    precedence[TOKorass] = PREC_assign;
    precedence[TOKxorass] = PREC_assign;

    precedence[TOKcomma] = PREC_expr;
    
    return true;
}

struct Token
{
    /+ BUG it doesn't recognize the enum member TOKMAX defined above +/
    /+ so I put it in the following module instead: +/
    import dmd.TokenBUG;
    static string[TOKMAX] tochars;
    
    Token* next;
    char* pointer;		// pointer to first character of this token within buffer
   
    // This was enum TOK, but it's just int now
    TOK value; // A proper value looks like: TOKxxxxxxx
                
    string blockComment; // doc comment string prior to this token
    string lineComment;	 // doc comment for previous token
    
    /// No good. We can't overload the new operator, so we have to
    /// make another function...
    // right now the function is in Lexer:
    //ref Token newToken() 

    union
    {
        // Integers
        int 	int32value;
        uint	uns32value;
        long	int64value;
        ulong	uns64value;

        version (IN_GCC) {} 
        else { real float80value; }

        struct
        {
            string ustring;	// UTF8 string
            //uint len; // used to be the length of ustring
            char postfix;	// 'c', 'w', 'd'
        }

        Identifier ident;
    }

    version (IN_GCC) 
    {
        real float80value; // can't use this in a union!
    }

    bool isKeyword()
    {
        foreach ( k ; keywords)
        {
            if ( value == k.value)
                return true;
        }
        return false;
    }

    void print()
    {
        assert(false);
    }

    string toChars()
    {
        string s;

        //char buffer[3 + 3 * value.sizeof + 1];

        switch (value)
        {
            case TOKint32v:
                s = (to!string( int32value ));
                break;

            case TOKuns32v:
            case TOKcharv:
            case TOKwcharv:
            case TOKdcharv:
                s = (to!string( uns32value ));
                break;

            case TOKint64v:
                s = (to!string( int64value ));
                break;

            case TOKuns64v:
                s = (to!string( uns64value ));
                break;

            case TOKfloat32v:
                s = (to!string(  float80value ));
                //sprintf(buffer.ptr,"%Lgf", float80value);
                break;

            case TOKfloat64v:
                s = (to!string( float80value  ));
                //sprintf(buffer.ptr,"%Lg", float80value);
                break;

            case TOKfloat80v:
                s = (to!string( float80value ));
                //sprintf(buffer.ptr,"%LgL", float80value);
                break;

            case TOKimaginary32v:
                s = (to!string( float80value )  ~"i");
                //sprintf(buffer.ptr,"%Lgfi", float80value);
                break;

            case TOKimaginary64v:
                s = (to!string(  float80value ) ~"i" );
                //sprintf(buffer.ptr,"%Lgi", float80value);
                break;

            case TOKimaginary80v:
                s = (to!string( float80value ) ~ "i");
                //sprintf(buffer.ptr,"%LgLi", float80value);
                break;

            case TOKstring:
            {   
                auto buf = appender!(string)();
                buf.reserve( ustring.length ); // close enough?

                buf.put('"');
                foreach( c; codePoints(cast(string)ustring) )
                //for (size_t i = 0; i < ustring.length; )
                {	
                    switch (c)
                    {
                        case 0:
                            break;

                        case '"':
                        case '\\':
                            buf.put('\\');
                        default:
                            if (std.ascii.isPrintable(c))
                                buf.put(c);
                            else 
                            {
                                buf.put('\\');
                                if (c <= 0x7F) buf.put("x");
                                else if (c <= 0xFFFF) buf.put("u");
                                else buf.put("U");

                                foreach( cu; codeUnits!(char)(c) )
                                    formattedWrite( buf, "%x", cu );
                            }
                            continue;
                    }
                    break;
                }
                buf.put('"');
                if (postfix)
                    buf.put( postfix );
                s = buf.data;
            }
                break;

            case TOKidentifier:
            case TOKenum:
            case TOKstruct:
            case TOKimport:
            case TOKwchar: case TOKdchar:
            case TOKbit: case TOKbool: case TOKchar:
            case TOKint8: case TOKuns8:
            case TOKint16: case TOKuns16:
            case TOKint32: case TOKuns32:
            case TOKint64: case TOKuns64:
            case TOKfloat32: case TOKfloat64: case TOKfloat80:
            case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:
            case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:
            case TOKvoid:
                s = ident.toChars();
                break;

            default:
                s = toChars(value);
                break;
        }
        return s;
    }

    static string toChars(TOK value)
    {
        string s = tochars[value];
        if (!s)
            s = "TOK" ~ to!string(value);
        return s;
    }
}
