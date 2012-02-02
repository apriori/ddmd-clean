module dmd.Identifier;
/++ Here we have initializers for: +/
/+
    static struct Id;
+/
//TODO get rid of generateId()

import dmd.Global;
import dmd.Token;
import dmd.Lexer;

import std.array;
import std.conv;
import std.format;

static Identifier[string] stringtable; 

static this()
{
    dmd.Token.initTochars();
    dmd.Token.initPrecedence();
    initKeywords();
    Id.initIdentifiers();
}
// Test one to make sure
unittest { assert ( precedence[TOKge] == PREC_rel ); }
unittest { assert ( Token.tochars[TOKge] == ">=" ); }

private void initKeywords()
{
    foreach ( k; dmd.Token.keywords )
    {  
        stringtable[k.name] = new Identifier( k.name, k.value );
    }
}

/+++++++++++++++++ The main struct for Id.anything; ++++++++++++++++++++/
struct Id
{
    /++ This mixin code generates a list of Identifier definitions, i.e.: +++/
    /+ 
    static Identifier Object_;
    static Identifier max;
    ...
    +/
    mixin( generateIdents() );
    
    static void initIdentifiers()
    {
        /++ Initialize the Identifiers i.e.: +/
        /+
        Object_ = idPool("Object");
        max = idPool("max");
        ...
        +/
        mixin( generateNames() );
    }
}

/+ And the Identifier/name pairs: +/
private enum string[2][] IDS = 
[
    [ "IUnknown", null ],
    [ "Object_", "Object" ],
    // caused a strange repeat declaration error...?
    //  [ "object", null ], 
    [ "max", null ],
    [ "min", null ],
    [ "This", "this" ],
    [ "ctor", "__ctor" ],
    [ "dtor", "__dtor" ],
    [ "cpctor", "__cpctor" ],
    [ "_postblit", "__postblit" ],
    [ "classInvariant", "__invariant" ],
    [ "unitTest", "__unitTest" ],
    [ "require", "__require" ],
    [ "ensure", "__ensure" ],
    [ "init_", "init" ],
    [ "size", null ],
    [ "__sizeof", "sizeof" ],
    [ "alignof_", "alignof" ],
    [ "mangleof_", "mangleof" ],
    [ "stringof_", "stringof" ],
    [ "tupleof_", "tupleof" ],
    [ "length", null ],
    [ "remove", null ],
    [ "ptr", null ],
    [ "funcptr", null ],
    [ "dollar", "__dollar" ],
    [ "ctfe", "__ctfe" ],
    [ "offset", null ],
    [ "offsetof", null ],
    [ "ModuleInfo", null ],
    [ "ClassInfo", null ],
    [ "classinfo_", "classinfo" ],
    [ "typeinfo_", "typeinfo" ],
    [ "outer", null ],
    [ "Exception", null ],
    [ "AssociativeArray", null ],
    [ "Throwable", null ],
    [ "withSym", "__withSym" ],
    [ "result", "__result" ],
    [ "returnLabel", "__returnLabel" ],
    [ "delegate_", "delegate" ],
    [ "line", null ],
    [ "empty", "" ],
    [ "p", null ],
    [ "coverage", "__coverage" ],
    [ "__vptr", null ],
    [ "__monitor", null ],

    [ "TypeInfo", null ],
    [ "TypeInfo_Class", null ],
    [ "TypeInfo_Interface", null ],
    [ "TypeInfo_Struct", null ],
    [ "TypeInfo_Enum", null ],
    [ "TypeInfo_Typedef", null ],
    [ "TypeInfo_Pointer", null ],
    [ "TypeInfo_Array", null ],
    [ "TypeInfo_StaticArray", null ],
    [ "TypeInfo_AssociativeArray", null ],
    [ "TypeInfo_Function", null ],
    [ "TypeInfo_Delegate", null ],
    [ "TypeInfo_Tuple", null ],
    [ "TypeInfo_Const", null ],
    [ "TypeInfo_Invariant", null ],
    [ "TypeInfo_Shared", null ],
    [ "TypeInfo_Wild", "TypeInfo_Inout" ],

    [ "elements", null ],
    [ "_arguments_typeinfo", null ],
    [ "_arguments", null ],
    [ "_argptr", null ],
    [ "_match", null ],
    [ "destroy", null ],

    [ "LINE", "__LINE__" ],
    [ "FILE", "__FILE__" ],
    [ "DATE", "__DATE__" ],
    [ "TIME", "__TIME__" ],
    [ "TIMESTAMP", "__TIMESTAMP__" ],
    [ "VENDOR", "__VENDOR__" ],
    [ "VERSIONX", "__VERSION__" ],
    [ "EOFX", "__EOF__" ],

    [ "nan", null ],
    [ "infinity", null ],
    [ "dig", null ],
    [ "epsilon", null ],
    [ "mant_dig", null ],
    [ "max_10_exp", null ],
    [ "max_exp", null ],
    [ "min_10_exp", null ],
    [ "min_exp", null ],
    [ "min_normal", null ],
    [ "re", null ],
    [ "im", null ],

    [ "C", null ],
    [ "D", null ],
    [ "Windows", null ],
    [ "Pascal", null ],
    [ "System", null ],

    [ "exit", null ],
    [ "success", null ],
    [ "failure", null ],

    [ "keys", null ],
    [ "values", null ],
    [ "rehash", null ],

    [ "sort", null ],
    [ "reverse", null ],
    [ "dup", null ],
    [ "idup", null ],

    [ "property", null ],
    [ "safe", null ],
    [ "trusted", null ],
    [ "system", null ],
    [ "disable", null ],

    // For inline assembler
    [ "___out", "out" ],
    [ "___in", "in" ],
    [ "__int", "int" ],
    [ "__dollar", "$" ],
    [ "__LOCAL_SIZE", null ],

    // For operator overloads
    [ "uadd",	 "opPos" ],
    [ "neg",	 "opNeg" ],
    [ "com",	 "opCom" ],
    [ "add",	 "opAdd" ],
    [ "add_r",   "opAdd_r" ],
    [ "sub",	 "opSub" ],
    [ "sub_r",   "opSub_r" ],
    [ "mul",	 "opMul" ],
    [ "mul_r",   "opMul_r" ],
    [ "div",	 "opDiv" ],
    [ "div_r",   "opDiv_r" ],
    [ "mod",	 "opMod" ],
    [ "mod_r",   "opMod_r" ],
    [ "eq",	  "opEquals" ],
    [ "cmp",	 "opCmp" ],
    [ "iand",	"opAnd" ],
    [ "iand_r",  "opAnd_r" ],
    [ "ior",	 "opOr" ],
    [ "ior_r",   "opOr_r" ],
    [ "ixor",	"opXor" ],
    [ "ixor_r",  "opXor_r" ],
    [ "shl",	 "opShl" ],
    [ "shl_r",   "opShl_r" ],
    [ "shr",	 "opShr" ],
    [ "shr_r",   "opShr_r" ],
    [ "ushr",	"opUShr" ],
    [ "ushr_r",  "opUShr_r" ],
    [ "cat",	 "opCat" ],
    [ "cat_r",   "opCat_r" ],
    [ "assign",  "opAssign" ],
    [ "addass",  "opAddAssign" ],
    [ "subass",  "opSubAssign" ],
    [ "mulass",  "opMulAssign" ],
    [ "divass",  "opDivAssign" ],
    [ "modass",  "opModAssign" ],
    [ "andass",  "opAndAssign" ],
    [ "orass",   "opOrAssign" ],
    [ "xorass",  "opXorAssign" ],
    [ "shlass",  "opShlAssign" ],
    [ "shrass",  "opShrAssign" ],
    [ "ushrass", "opUShrAssign" ],
    [ "catass",  "opCatAssign" ],
    [ "postinc", "opPostInc" ],
    [ "postdec", "opPostDec" ],
    [ "index",	 "opIndex" ],
    [ "indexass", "opIndexAssign" ],
    [ "slice",	 "opSlice" ],
    [ "sliceass", "opSliceAssign" ],
    [ "call",	 "opCall" ],
    [ "cast_",	 "opCast" ],
    [ "match",	 "opMatch" ],
    [ "next",	 "opNext" ],
    [ "opIn", null ],
    [ "opIn_r", null ],
    [ "opStar", null ],
    [ "opDot", null ],
    [ "opDispatch", null ],
    [ "opImplicitCast", null ],
    [ "pow", "opPow" ],
    [ "pow_r", "opPow_r" ],
    [ "powass", "opPowAssign" ],

    [ "classNew", "new" ],
    [ "classDelete", "delete" ],

    // For foreach
    [ "apply", "opApply" ],
    [ "applyReverse", "opApplyReverse" ],

    [ "Fempty", "empty" ],
    [ "Fhead", "front" ],
    [ "Ftoe", "back" ],
    [ "Fnext", "popFront" ],
    [ "Fretreat", "popBack" ],

    [ "adDup", "_adDupT" ],
    [ "adReverse", "_adReverse" ],

    // For internal functions
    [ "aaLen", "_aaLen" ],
    [ "aaKeys", "_aaKeys" ],
    [ "aaValues", "_aaValues" ],
    [ "aaRehash", "_aaRehash" ],
    [ "monitorenter", "_d_monitorenter" ],
    [ "monitorexit", "_d_monitorexit" ],
    [ "criticalenter", "_d_criticalenter" ],
    [ "criticalexit", "_d_criticalexit" ],

    // For pragma's
    [ "GNU_asm", null ],
    [ "lib", null ],
    [ "msg", null ],
    [ "startaddress", null ],

    // For special functions
    [ "tohash", "toHash" ],
    [ "tostring", "toString" ],
    [ "getmembers", "getMembers" ],

    // Special functions
    [ "alloca", null ],
    [ "main", null ],
    [ "WinMain", null ],
    [ "DllMain", null ],
    [ "tls_get_addr", "___tls_get_addr" ],

    // Builtin functions
    [ "std", null ],
    [ "math", null ],
    [ "sin", null ],
    [ "cos", null ],
    [ "tan", null ],
    [ "_sqrt", "sqrt" ],
    [ "_pow", "pow" ],
    [ "fabs", null ],

    // Traits
    [ "isAbstractClass", null ],
    [ "isArithmetic", null ],
    [ "isAssociativeArray", null ],
    [ "isFinalClass", null ],
    [ "isFloating", null ],
    [ "isIntegral", null ],
    [ "isScalar", null ],
    [ "isStaticArray", null ],
    [ "isUnsigned", null ],
    [ "isVirtualFunction", null ],
    [ "isAbstractFunction", null ],
    [ "isFinalFunction", null ],
    [ "isStaticFunction", null ],
    [ "isRef", null ],
    [ "isOut", null ],
    [ "isLazy", null ],
    [ "hasMember", null ],
    [ "identifier", null ],
    [ "getMember", null ],
    [ "getOverloads", null ],
    [ "getVirtualFunctions", null ],
    [ "classInstanceSize", null ],
    [ "allMembers", null ],
    [ "derivedMembers", null ],
    [ "isSame", null ],
    [ "compiles", null]
];    

private string generateIdents()
{
    string res;
    foreach ( id; IDS ) {
        assert ( id[0] );
        res ~= "static Identifier " ~ id[0] ~ ";\n";
    }
    return res;
}

private string generateNames()
{
    string res;
    foreach ( id; IDS )
    {
        string tmp = id[1] ? id[1] : id[0];
        res ~= "\t" ~ id[0] ~ ` = Identifier.idPool("` ~ tmp ~ "\");\n";
    }
    return res;
}


class Identifier
{
    TOK value;
    string string_;

    this(string string_, TOK value)
    {
        this.string_ = string_;
        this.value = value;
    }
    
    override bool opEquals(Object o)
	{
		if (this is o) {
			return true;
		}

		if (auto i = cast(Identifier) o) {
			return string_ == i.string_;
		}

		return false;
	}

    hash_t hashCode()
    {
        assert(false);
    }

    void print()
    {
        //original... fprintf(stdmsg, "%s",string);
        assert(false);
    }

    string toChars()
    {
        return string_;
    }

    version (_DH) { string toHChars() { assert(false); } }

    string toHChars2()
    {
        string p;

        if (this == Id.ctor) p = "this";
        else if (this == Id.dtor) p = "~this";
        else if (this == Id.classInvariant) p = "invariant";
        else if (this == Id.unitTest) p = "unittest";
        else if (this == Id.dollar) p = "$";
        else if (this == Id.withSym) p = "with";
        else if (this == Id.result) p = "result";
        else if (this == Id.returnLabel) p = "return";
        else
        {
            p = toChars();
            if ( p[0] == '_')
            {
                if ( p == "_staticCtor")
                    p = "static this";
                else if ( p == "_staticDtor" )
                    p = "static ~this";
            }
        }
        return p;
    }

    DYNCAST dyncast()
    {
        return DYNCAST_IDENTIFIER;
    }

    static Identifier idPool(string s)
    {
        Identifier sv = stringtable.get( s, null );
        if ( sv is null )
            sv = new Identifier( s, TOKidentifier ); 
        return sv;
    }

    static Identifier uniqueId(string s)
    {
        static uint num = 0;
        num++;
        return uniqueId(s, num);
    }

    /*********************************************
     * Create a unique identifier using the prefix s.
     */
    static Identifier uniqueId(string s, int num)
    {
        string buffer = s ~ to!string(num);
        assert ( buffer.length + ( 3 * int.sizeof ) + 1 <= 32 );
        return idPool( buffer );
    }

}
