// D import file generated from './dmd/Token.d'
module dmd.Token;
import dmd.Identifier;
import std.conv;
import std.array;
import std.encoding;
import std.format;
alias int TOK;
enum 
{
TOKreserved,
TOKlparen,
TOKrparen,
TOKlbracket,
TOKrbracket,
TOKlcurly,
TOKrcurly,
TOKcolon,
TOKneg,
TOKsemicolon,
TOKdotdotdot,
TOKeof,
TOKcast,
TOKnull,
TOKassert,
TOKtrue,
TOKfalse,
TOKarray,
TOKcall,
TOKaddress,
TOKtype,
TOKthrow,
TOKnew,
TOKdelete,
TOKstar,
TOKsymoff,
TOKvar,
TOKdotvar,
TOKdotti,
TOKdotexp,
TOKdottype,
TOKslice,
TOKarraylength,
TOKversion,
TOKmodule,
TOKdollar,
TOKtemplate,
TOKdottd,
TOKdeclaration,
TOKtypeof,
TOKpragma,
TOKdsymbol,
TOKtypeid,
TOKuadd,
TOKremove,
TOKnewanonclass,
TOKcomment,
TOKarrayliteral,
TOKassocarrayliteral,
TOKstructliteral,
TOKlt,
TOKgt,
TOKle,
TOKge,
TOKequal,
TOKnotequal,
TOKidentity,
TOKnotidentity,
TOKindex,
TOKis,
TOKtobool,
TOKunord,
TOKlg,
TOKleg,
TOKule,
TOKul,
TOKuge,
TOKug,
TOKue,
TOKshl,
TOKshr,
TOKshlass,
TOKshrass,
TOKushr,
TOKushrass,
TOKcat,
TOKcatass,
TOKadd,
TOKmin,
TOKaddass,
TOKminass,
TOKmul,
TOKdiv,
TOKmod,
TOKmulass,
TOKdivass,
TOKmodass,
TOKand,
TOKor,
TOKxor,
TOKandass,
TOKorass,
TOKxorass,
TOKassign,
TOKnot,
TOKtilde,
TOKplusplus,
TOKminusminus,
TOKconstruct,
TOKblit,
TOKdot,
TOKarrow,
TOKcomma,
TOKquestion,
TOKandand,
TOKoror,
TOKint32v,
TOKuns32v,
TOKint64v,
TOKuns64v,
TOKfloat32v,
TOKfloat64v,
TOKfloat80v,
TOKimaginary32v,
TOKimaginary64v,
TOKimaginary80v,
TOKcharv,
TOKwcharv,
TOKdcharv,
TOKidentifier,
TOKstring,
TOKthis,
TOKsuper,
TOKhalt,
TOKtuple,
TOKerror,
TOKvoid,
TOKint8,
TOKuns8,
TOKint16,
TOKuns16,
TOKint32,
TOKuns32,
TOKint64,
TOKuns64,
TOKfloat32,
TOKfloat64,
TOKfloat80,
TOKimaginary32,
TOKimaginary64,
TOKimaginary80,
TOKcomplex32,
TOKcomplex64,
TOKcomplex80,
TOKchar,
TOKwchar,
TOKdchar,
TOKbit,
TOKbool,
TOKcent,
TOKucent,
TOKstruct,
TOKclass,
TOKinterface,
TOKunion,
TOKenum,
TOKimport,
TOKtypedef,
TOKalias,
TOKoverride,
TOKdelegate,
TOKfunction,
TOKmixin,
TOKalign,
TOKextern,
TOKprivate,
TOKprotected,
TOKpublic,
TOKexport,
TOKstatic,
TOKfinal,
TOKconst,
TOKabstract,
TOKvolatile,
TOKdebug,
TOKdeprecated,
TOKin,
TOKout,
TOKinout,
TOKwild = TOKinout,
TOKlazy,
TOKauto,
TOKpackage,
TOKmanifest,
TOKimmutable,
TOKif,
TOKelse,
TOKwhile,
TOKfor,
TOKdo,
TOKswitch,
TOKcase,
TOKdefault,
TOKbreak,
TOKcontinue,
TOKwith,
TOKsynchronized,
TOKreturn,
TOKgoto,
TOKtry,
TOKcatch,
TOKfinally,
TOKasm,
TOKforeach,
TOKforeach_reverse,
TOKscope,
TOKon_scope_exit,
TOKon_scope_failure,
TOKon_scope_success,
TOKbody,
TOKinvariant,
TOKunittest,
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
TOKMAX,
}
struct Keyword
{
    string name;
    TOK value;
}
enum Keyword[] keywords = [{"this",TOKthis},{"super",TOKsuper},{"assert",TOKassert},{"null",TOKnull},{"true",TOKtrue},{"false",TOKfalse},{"cast",TOKcast},{"new",TOKnew},{"delete",TOKdelete},{"throw",TOKthrow},{"module",TOKmodule},{"pragma",TOKpragma},{"typeof",TOKtypeof},{"typeid",TOKtypeid},{"template",TOKtemplate},{"void",TOKvoid},{"byte",TOKint8},{"ubyte",TOKuns8},{"short",TOKint16},{"ushort",TOKuns16},{"int",TOKint32},{"uint",TOKuns32},{"long",TOKint64},{"ulong",TOKuns64},{"cent",TOKcent},{"ucent",TOKucent},{"float",TOKfloat32},{"double",TOKfloat64},{"real",TOKfloat80},{"bool",TOKbool},{"char",TOKchar},{"wchar",TOKwchar},{"dchar",TOKdchar},{"ifloat",TOKimaginary32},{"idouble",TOKimaginary64},{"ireal",TOKimaginary80},{"cfloat",TOKcomplex32},{"cdouble",TOKcomplex64},{"creal",TOKcomplex80},{"delegate",TOKdelegate},{"function",TOKfunction},{"is",TOKis},{"if",TOKif},{"else",TOKelse},{"while",TOKwhile},{"for",TOKfor},{"do",TOKdo},{"switch",TOKswitch},{"case",TOKcase},{"default",TOKdefault},{"break",TOKbreak},{"continue",TOKcontinue},{"synchronized",TOKsynchronized},{"return",TOKreturn},{"goto",TOKgoto},{"try",TOKtry},{"catch",TOKcatch},{"finally",TOKfinally},{"with",TOKwith},{"asm",TOKasm},{"foreach",TOKforeach},{"foreach_reverse",TOKforeach_reverse},{"scope",TOKscope},{"struct",TOKstruct},{"class",TOKclass},{"interface",TOKinterface},{"union",TOKunion},{"enum",TOKenum},{"import",TOKimport},{"mixin",TOKmixin},{"static",TOKstatic},{"final",TOKfinal},{"const",TOKconst},{"typedef",TOKtypedef},{"alias",TOKalias},{"override",TOKoverride},{"abstract",TOKabstract},{"volatile",TOKvolatile},{"debug",TOKdebug},{"deprecated",TOKdeprecated},{"in",TOKin},{"out",TOKout},{"inout",TOKinout},{"lazy",TOKlazy},{"auto",TOKauto},{"align",TOKalign},{"extern",TOKextern},{"private",TOKprivate},{"package",TOKpackage},{"protected",TOKprotected},{"public",TOKpublic},{"export",TOKexport},{"body",TOKbody},{"invariant",TOKinvariant},{"unittest",TOKunittest},{"version",TOKversion},{"ref",TOKref},{"macro",TOKmacro},{"pure",TOKpure},{"nothrow",TOKnothrow},{"__thread",TOKtls},{"__gshared",TOKgshared},{"__traits",TOKtraits},{"__overloadset",TOKoverloadset},{"__FILE__",TOKfile},{"__LINE__",TOKline},{"shared",TOKshared},{"immutable",TOKimmutable}];
void initTochars();
alias int PREC;
static PREC[TOKMAX] precedence;

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
bool initPrecedence();
struct Token
{
    import dmd.TokenBUG;
    static string[TOKMAX] tochars;

    Token* next;
    char* pointer;
    TOK value;
    string blockComment;
    string lineComment;
    union
{
int int32value;
uint uns32value;
long int64value;
ulong uns64value;
real float80value;
struct
{
string ustring;
char postfix;
}
Identifier ident;
}
    bool isKeyword();
    void print()
{
assert(false);
}
    string toChars();
    static string toChars(TOK value)
{
string s = tochars[value];
if (!s)
s = "TOK" ~ to!(string)(value);
return s;
}

}
