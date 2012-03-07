import std.stdio;

// This file generates dmd/Id.txt which is imported in dmd.identifier
// You need not run it unless you change one of the identifiers listed below

void main()
{
   auto f = File("Id.txt","w");
   f.write( s );
}

/+ the Identifier/name pairs: +/
private enum string[2][] IDS = 
[
    [ "IUnknown", null ],
    [ "Object_", "Object" ],
    // module "object" is defined by default in any D program
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

/+++++++++++++++++ The main struct for Id.anything; +++++++++++++/
    /++ This mixin code generates a list of Identifier definitions, i.e.: +++/
    /+ 
    static Identifier Object_;
    static Identifier max;
    ...
    +/
    // And an initialization routine:
   /++ Initialize the Identifiers i.e.: +/
   /+
        Object_ = idPool("Object");
        max = idPool("max");
        ...
   +/
enum s = `
// This file was generated by running genIds.d
// and it gets imported as a mixin(import"Id.txt") by dmd.identifier.
struct Id
{
    ` ~ generateIdents() ~ `
    
    static void initIdentifiers()
    {
        ` ~ generateNames() ~ `
    }
}
`;
