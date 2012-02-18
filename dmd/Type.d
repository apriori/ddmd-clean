module dmd.Type;
// zd notes: remove MODXXX
// and TOK.TOKxxxx
// and TYxxxx
// now includes enum MATCH
// and OutBuffer;

import dmd.Global;
import dmd.Parameter;
import dmd.TemplateParameter;
import dmd.Module;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.Identifier;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Dsymbol;
import dmd.TypeInfoDeclaration;
import dmd.ScopeDsymbol;
import dmd.types.TypeBasic;
//import dmd.Lexer;
import dmd.types.TypeArray;
import dmd.types.TypeSArray;
import dmd.types.TypeDArray;
import dmd.types.TypeAArray;
import dmd.types.TypePointer;
import dmd.types.TypeReference;
import dmd.types.TypeFunction;
import dmd.types.TypeDelegate;
import dmd.types.TypeIdentifier;
import dmd.types.TypeInstance;
import dmd.types.TypeTypeof;
import dmd.types.TypeReturn;
import dmd.types.TypeStruct;
import dmd.types.TypeEnum;
import dmd.types.TypeTypedef;
import dmd.types.TypeClass;
import dmd.types.TypeTuple;
import dmd.types.TypeSlice;
import dmd.Token;

import std.array;
import std.stdio;
import std.string;

/+ REALSIZE = size a real consumes in memory
 + REALPAD = 'padding' added to the CPU real size to bring it up to REALSIZE
 + REALALIGNSIZE = alignment for reals
 +/
version (TARGET_OSX) {
	int REALSIZE = 16;
	int REALPAD = 6;
	int REALALIGNSIZE = 16;
} else version (POSIX) { /// TARGET_LINUX || TARGET_FREEBSD || TARGET_SOLARIS
	int REALSIZE = 12;
	int REALPAD = 2;
	int REALALIGNSIZE = 4;
} else {
	int REALSIZE = 10;
	int REALPAD = 0;
	int REALALIGNSIZE = 2;
}

alias int RET;
enum 
{
    RETregs     = 1,    // returned in registers
    RETstack    = 2,    // returned on stack
}

alias int TFLAGS;
enum 
{
	TFLAGSintegral	= 1,
	TFLAGSfloating	= 2,
	TFLAGSunsigned	= 4,
	TFLAGSreal		= 8,
	TFLAGSimaginary = 0x10,
	TFLAGScomplex	= 0x20,
}


alias int TRUST;
enum 
{
    TRUSTdefault,
    TRUSTsystem,    // @system (same as TRUSTdefault)
    TRUSTtrusted,   // @trusted
    TRUSTsafe,      // @safe
}

alias int PURE;
enum 
{
    PUREimpure,     // not pure at all
    PUREweak,       // no mutable globals are read or written
    PUREconst,      // parameters are values or const
    PUREstrong,     // parameters are values or immutable
    PUREfwdref,     // it's pure, but not known which level yet
}

alias int MOD;
enum 
{
	MODundefined = 0,
	MODconst = 1,	// type is const
	MODshared = 2,	// type is shared
	MODimmutable = 4,	// type is immutable
	MODwild	= 8,	// type is wild
	MODmutable = 0x10,	// type is mutable (only used in wildcard matching)
}

/***************************
 * Return !=0 if modfrom can be implicitly converted to modto
 */
int MODimplicitConv(MOD modfrom, MOD modto)
{
    if (modfrom == modto)
	return 1;

    //printf("MODimplicitConv(from = %x, to = %x)\n", modfrom, modto);
	static uint X(MOD m, MOD n)
	{
		return (((m) << 4) | (n));
	}
    switch (X(modfrom, modto))
    {
	    case X(MODundefined, MODconst):
	    case X(MODimmutable, MODconst):
	    case X(MODwild,      MODconst):
	    case X(MODimmutable, MODconst | MODshared):
	    case X(MODshared,    MODconst | MODshared):
	    case X(MODwild | MODshared,    MODconst | MODshared):
	        return 1;
	    default:
	        return 0;
    }
}

/*********************************
 * Mangling for mod.
 */
void MODtoDecoBuffer(ref Appender!(char[]) buf, MOD mod)
{
    switch (mod)
    {
        case MODundefined:
	        break;
	    case MODconst:
	        buf.put('x');
	        break;
	    case MODimmutable:
	        buf.put('y');
	        break;
	    case MODshared:
	        buf.put('O');
	        break;
	    case MODshared | MODconst:
	        buf.put("Ox");
	        break;
	    case MODwild:
	        buf.put("Ng");
	        break;
	    case MODshared | MODwild:
	        buf.put("ONg");
	        break;
	    default:
	        assert(0);
    }
}

/*********************************
 * Name for mod.
 */
void MODtoBuffer(ref Appender!(char[]) buf, MOD mod)
{
    switch (mod)
    {
    case MODundefined:
	    break;

	case MODimmutable:
	    buf.put(Token.tochars[TOKimmutable]);
	    break;

	case MODshared:
	    buf.put(Token.tochars[TOKshared]);
	    break;

	case MODshared | MODconst:
	    buf.put(Token.tochars[TOKshared]);
	    buf.put(' ');
	case MODconst:
	    buf.put(Token.tochars[TOKconst]);
	    break;

	case MODshared | MODwild:
	    buf.put(Token.tochars[TOKshared]);
	    buf.put(' ');
	case MODwild:
	    buf.put(Token.tochars[TOKwild]);
	    break;
	default:
	    assert(0);
    }
}

alias int ENUMTY;
alias int TY;

enum 
{   
    Tarray,      // slice array, aka T[]
    Tsarray,     // static array, aka T[dimension]
    Tnarray,     // resizable array, aka T[new]
    Taarray,     // associative array, aka T[type]
    Tpointer,
    Treference,
    Tfunction,
    Tident,
    Tclass,
    Tstruct,
    Tenum,
    Ttypedef,
    Tdelegate,

    Tnone,
    Tvoid,
    Tint8, Tuns8, Tint16, Tuns16,
    Tint32, Tuns32, Tint64, Tuns64,
    Tfloat32, Tfloat64, Tfloat80,

    Timaginary32, Timaginary64, Timaginary80,
    Tcomplex32, Tcomplex64, Tcomplex80,

    Tbit, Tbool, Tchar, 
    
    Twchar, Tdchar,

    Terror, Tinstance,

    Ttypeof,
    Ttuple,
    Tslice,
    Treturn,
    TMAX,
}

//BUG the compiler messed up Tascii = Tchar, when I put it 
// up in the enum : it didn't register
// any of the identifiers (TMAX) for the definitions
// that follow. This bug didn't reproduce easily.
enum Tascii = Tchar;
Type basic[TMAX];

int PTRSIZE = 4;  //32bits? Well, I guess they'll change eventually
int Tsize_t;
int Tptrdiff_t;

T cloneThis(T)(T arc)
{
    // I was so thrilled to fit it all into one line!
    return cast(T) ( ( cast(byte*) arc )[0..arc.classinfo.init.length].dup ).ptr;
    // It's possible that I need to create an instance or something idunno
    // Also the whole thing might be obviated by .dup :)
}

// MARK : Need this here?
Object objectSyntaxCopy(Object o)
{
    if (!o)
        return null;

    Type t = isType(o);
    if (t)
        return t.syntaxCopy();

    Expression e = isExpression(o);
    if (e)
        return e.syntaxCopy();

    return o;
}

class Type
{
    TY ty;
    MOD mod;	// modifiers MODxxxx

    // The mangled name of the type
    string deco;

    /* These are cached values that are lazily evaluated by constOf(), invariantOf(), etc.
     * They should not be referenced by anybody but mtype.c.
     * They can be null if not lazily evaluated yet.
     * Note that there is no "shared immutable", because that is just immutable
     * Naked == no MOD bits
     */

    Type cto;		// MODconst ? naked version of this type : const version
    Type ito;		// MODimmutable ? naked version of this type : immutable version
    Type sto;		// MODshared ? naked version of this type : shared mutable version
    Type scto;		// MODshared|MODconst ? naked version of this type : shared const version
    Type wto;		// MODwild ? naked version of this type : wild version
    Type swto;		// MODshared|MODwild ? naked version of this type : shared wild version


    Type pto;		// merged pointer to this type
    Type rto;		// reference to this type
    Type arrayof;	// array of this type
    TypeInfoDeclaration vtinfo;	// TypeInfo object for this Type

    //type* ctype;	// for back end ... lowercase, kinda strange!?zd

    // TMAX is not recognized by dmd for some strange reason,
    // unless I declare it in another module (dmd.Token)
    static ubyte[TMAX] mangleChar;
    static ubyte[TMAX] sizeTy;
    static Type[string]type_stringtable;

    this(TY ty)
	{
		this.ty = ty;
	}

    Type syntaxCopy()
	{
		assert(false);
	}

    bool equals(Object o) { assert(false,"zd cut"); }
    
    int covariant(Type t) { assert(false,"zd cut"); }

    string toChars()
	{
		auto buf = appender!(char[])();

		HdrGenState hgs;
		toCBuffer(buf, null, hgs);
		return buf.data.idup;
	}

    static char needThisPrefix() { assert(false,"zd cut"); }

    static void init()
	{
		foreach ( i; sizeTy )
			i = TypeBasic.sizeof;

		sizeTy[Tsarray] = TypeSArray.sizeof;
		sizeTy[Tarray] = TypeDArray.sizeof;
		//sizeTy[Tnarray] = TypeNArray.sizeof;
		sizeTy[Taarray] = TypeAArray.sizeof;
		sizeTy[Tpointer] = TypePointer.sizeof;
		sizeTy[Treference] = TypeReference.sizeof;
		sizeTy[Tfunction] = TypeFunction.sizeof;
		sizeTy[Tdelegate] = TypeDelegate.sizeof;
		sizeTy[Tident] = TypeIdentifier.sizeof;
		sizeTy[Tinstance] = TypeInstance.sizeof;
		sizeTy[Ttypeof] = TypeTypeof.sizeof;
		sizeTy[Tenum] = TypeEnum.sizeof;
		sizeTy[Ttypedef] = TypeTypedef.sizeof;
		sizeTy[Tstruct] = TypeStruct.sizeof;
		sizeTy[Tclass] = TypeClass.sizeof;
		sizeTy[Ttuple] = TypeTuple.sizeof;
		sizeTy[Tslice] = TypeSlice.sizeof;
		sizeTy[Treturn] = TypeReturn.sizeof;

		mangleChar[Tarray] = 'A';
		mangleChar[Tsarray] = 'G';
		mangleChar[Tnarray] = '@';
		mangleChar[Taarray] = 'H';
		mangleChar[Tpointer] = 'P';
		mangleChar[Treference] = 'R';
		mangleChar[Tfunction] = 'F';
		mangleChar[Tident] = 'I';
		mangleChar[Tclass] = 'C';
		mangleChar[Tstruct] = 'S';
		mangleChar[Tenum] = 'E';
		mangleChar[Ttypedef] = 'T';
		mangleChar[Tdelegate] = 'D';

		mangleChar[Tnone] = 'n';
		mangleChar[Tvoid] = 'v';
		mangleChar[Tint8] = 'g';
		mangleChar[Tuns8] = 'h';
		mangleChar[Tint16] = 's';
		mangleChar[Tuns16] = 't';
		mangleChar[Tint32] = 'i';
		mangleChar[Tuns32] = 'k';
		mangleChar[Tint64] = 'l';
		mangleChar[Tuns64] = 'm';
		mangleChar[Tfloat32] = 'f';
		mangleChar[Tfloat64] = 'd';
		mangleChar[Tfloat80] = 'e';

		mangleChar[Timaginary32] = 'o';
		mangleChar[Timaginary64] = 'p';
		mangleChar[Timaginary80] = 'j';
		mangleChar[Tcomplex32] = 'q';
		mangleChar[Tcomplex64] = 'r';
		mangleChar[Tcomplex80] = 'c';

		mangleChar[Tbool] = 'b';
		mangleChar[Tascii] = 'a';
		mangleChar[Twchar] = 'u';
		mangleChar[Tdchar] = 'w';

        // '@' shouldn't appear anywhere in the deco'd names
		mangleChar[Tbit] = '@';
		mangleChar[Tinstance] = '@';
		mangleChar[Terror] = '@';
		mangleChar[Ttypeof] = '@';
		mangleChar[Ttuple] = 'B';
		mangleChar[Tslice] = '@';
		mangleChar[Treturn] = '@';

debug {
		foreach (int i; mangleChar[0..TMAX] ) {
			if (!i) {
				writef("ty = %d\n", i);
			}
			assert(i);
		}
}
		// Set basic types
		enum TY[] basetab = [
			Tvoid, Tint8, Tuns8, Tint16, Tuns16, Tint32, Tuns32, Tint64, Tuns64,
			Tfloat32, Tfloat64, Tfloat80,
			Timaginary32, Timaginary64, Timaginary80,
			Tcomplex32, Tcomplex64, Tcomplex80,
			Tbool,
			Tascii, Twchar, Tdchar
		];
      
      foreach (bt; basetab) {
			Type t = new TypeBasic(bt);
			t = t.merge();
			basic[bt] = t;
		}

		basic[Terror] = basic[Tint32];

		global.tvoidptr = tvoid.pointerTo();
		global.tstring = tchar.invariantOf().arrayOf();
	}

	/+++++++++++++++++++++++++++++++
	 + If this is a shell around another type,
	 + get that other type.
	 +/

    Type toBasetype()
	{
		return this;
	}

    ulong size()
	{
		return size(Loc(0));
	}

    ulong size(Loc loc)
	{
		error(loc, "no size for type %s", toChars());
		return 1;
	}

    uint alignsize()
	{
		return cast(uint)size(Loc(0));	///
	}

	/********************************
	 * Name mangling.
	 * Input:
	 *	flag	0x100	do not do const/invariant
	 */
    void toDecoBuffer(ref Appender!(char[]) buf, int flag = 0)
	{
		if (flag != mod && flag != 0x100)
		{
			MODtoDecoBuffer(buf, mod);
		}
		buf.put(mangleChar[ty]);
	}

    Type merge()
	{
		Type t = this;
		assert(t);

		//printf("merge(%s)\n", toChars());
		if (deco is null)
		{
			auto buf = appender!(char[])();

			//if (next)
				//next = next.merge();
			toDecoBuffer(buf);
			auto s = buf.data.idup;
			Type sv = type_stringtable.get(s, null);
			if (sv)
			{
				t = sv;
            debug 
            {
               if (!t.deco)
                  writef("t = %s\n", t.toChars());
            }
				assert(t.deco);
				//printf("old value, deco = '%s' %p\n", t.deco, t.deco);
			}
			else
			{
            type_stringtable[s] = this;
				deco = s;
				//printf("new value, deco = '%s' %p\n", t.deco, t.deco);
			}
		}
		return t;
	}


	/*************************************
	 * This version does a merge even if the deco is already computed.
	 * Necessary for types that have a deco, but are not merged.
	 */
    Type merge2() { assert(false,"zd cut"); }

    void toCBuffer(ref Appender!(char[]) buf, Identifier ident, ref HdrGenState hgs)
	{
		toCBuffer2(buf, hgs, MODundefined);
		if (ident)
		{
			buf.put(' ');
			buf.put(ident.toChars());
		}
	}

    void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(toChars());
	}

    void toCBuffer3(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			if (this.mod & MODshared)
	        {
	            MODtoBuffer(buf, this.mod & MODshared);
	            buf.put('(');
	        }

	        if (this.mod & ~MODshared)
	        {
	            MODtoBuffer(buf, this.mod & ~MODshared);
	            buf.put('(');
	            toCBuffer2(buf, hgs, this.mod);
	            buf.put(')');
	        }
	        else
	            toCBuffer2(buf, hgs, this.mod);
	        if (this.mod & MODshared)
	        {
	            buf.put(')');
	        }
		}
	}

    void modToBuffer(ref Appender!(char[]) buf)
	{
        if (mod)
        {
    	    buf.put(' ');
	        MODtoBuffer(buf, mod);
        }
	}
    
    bool isintegral()
	{
		return false;
	}

    bool isfloating()	// real, imaginary, or complex
	{
		return false;
	}

    // Apparently we've mistakenly parsed this Type as an Erpession
    Expression toExpression()
	{
		return null;
	}

    bool isreal()
	{
		return false;
	}

    bool isimaginary()
	{
		return false;
	}

    bool iscomplex()
	{
		return false;
	}

    bool isscalar()
	{
		return false;
	}

    bool isunsigned()
	{
		return false;
	}

    bool isauto()
	{
		return false;
	}

    bool isString()
	{
		return false;
	}

	/**************************
	 * Given:
	 *	T a, b;
	 * Can we assign:
	 *	a = b;
	 * ?
	 */
    bool isAssignable()
	{
		return true;
	}

	// if can be converted to boolean value
    bool checkBoolean() { assert(false,"zd cut"); }

	/*********************************
	 * Check type to see if it is based on a deprecated symbol.
	 */
    void checkDeprecated(Loc loc, Scope sc) { assert(false,"zd cut"); }

    bool isConst()	{ return (mod & MODconst) != 0; }

	int isImmutable()	{ return mod & MODimmutable; }

	int isMutable()	{ return !(mod & (MODconst | MODimmutable | MODwild)); }

	int isShared()	{ return mod & MODshared; }

	int isSharedConst()	{ return mod == (MODshared | MODconst); }

    int isWild()	{ return mod & MODwild; }

    int isSharedWild()	{ return mod == (MODshared | MODwild); }

    int isNaked()	{ return mod == 0; }


	/********************************
	 * Convert to 'const'.
	 */
	Type constOf()
	{
		//printf("Type.constOf() %p %s\n", this, toChars());
		if (mod == MODconst)
			return this;
		if (cto)
		{
			assert(cto.mod == MODconst);
			return cto;
		}
		Type t = makeConst();
		t = t.merge();
		t.fixTo(this);
		//printf("-Type.constOf() %p %s\n", t, toChars());
		return t;
	}

	/********************************
	 * Convert to 'immutable'.
	 */
    Type invariantOf()
	{
		//printf("Type.invariantOf() %p %s\n", this, toChars());
		if (isImmutable())
		{
			return this;
		}
		if (ito)
		{
			assert(ito.isImmutable());
			return ito;
		}

		Type t = makeInvariant();
		t = t.merge();
		t.fixTo(this);
		//printf("\t%p\n", t);
		return t;
	}

    Type mutableOf()
	{
		//printf("Type.mutableOf() %p, %s\n", this, toChars());
		Type t = this;
		if (isConst())
		{
			if (isShared())
				t = sto;		// shared const => shared
			else
				t = cto;		// const => naked
			assert(!t || t.isMutable());
		}
		else if (isImmutable())
		{
			t = ito;
			assert(!t || (t.isMutable() && !t.isShared()));
		}
        else if (isWild())
        {
	        if (isShared())
	            t = sto;		// shared wild => shared
	        else
	            t = wto;		// wild => naked
	        assert(!t || t.isMutable());
        }
		if (!t)
		{
            t = makeMutable();
			t = t.merge();
			t.fixTo(this);
		}
            assert(t.isMutable());
		return t;
	}

    Type sharedOf()
	{
		//printf("Type.sharedOf() %p, %s\n", this, toChars());
		if (mod == MODshared)
		{
			return this;
		}
		if (sto)
		{
			assert(sto.isShared());
			return sto;
		}

		Type t = makeShared();
		t = t.merge();
		t.fixTo(this);

		//printf("\t%p\n", t);
		return t;
	}

    Type sharedConstOf()
	{
		//printf("Type.sharedConstOf() %p, %s\n", this, toChars());
		if (mod == (MODshared | MODconst))
		{
			return this;
		}
		if (scto)
		{
			assert(scto.mod == (MODshared | MODconst));
			return scto;
		}

		Type t = makeSharedConst();
		t = t.merge();
		t.fixTo(this);
		//printf("\t%p\n", t);

		return t;
	}

	/********************************
	 * Make type unshared.
     *	0            => 0
     *	const        => const
     *	immutable    => immutable
     *	shared       => 0
     *	shared const => const
     *	wild         => wild
     *	shared wild  => wild
	 */
	Type unSharedOf()
	{
		//writef("Type::unSharedOf() %p, %s\n", this, toChars());
		Type t = this;

		if (isShared())
		{
			if (isConst())
				t = cto;	// shared const => const
	        else if (isWild())
	            t = wto;	// shared wild => wild
			else
				t = sto;
			assert(!t || !t.isShared());
		}

		if (!t)
		{
			t = cloneThis(this);
			t.mod = mod & ~MODshared;
			t.deco = null;
			t.arrayof = null;
			t.pto = null;
			t.rto = null;
			t.cto = null;
			t.ito = null;
			t.sto = null;
			t.scto = null;
	        t.wto = null;
	        t.swto = null;
			t.vtinfo = null;
			t = t.merge();

			t.fixTo(this);
		}
		assert(!t.isShared());
		return t;
	}



    /********************************
     * Convert to 'wild'.
     */

    Type wildOf()
    {
        //printf("Type::wildOf() %p %s\n", this, toChars());
        if (mod == MODwild)
        {
	        return this;
        }
        if (wto)
        {
    	    assert(wto.isWild());
	        return wto;
        }
        Type t = makeWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t->toChars());
        return t;
    }

    Type sharedWildOf()
    {
        //printf("Type::sharedWildOf() %p, %s\n", this, toChars());
        if (mod == (MODwild))
        {
    	    return this;
        }
        if (swto)
        {
	        assert(swto.mod == (MODshared | MODwild));
	        return swto;
        }
        Type t = makeSharedWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p\n", t);
        return t;
    }

	/**********************************
	 * For our new type 'this', which is type-constructed from t,
	 * fill in the cto, ito, sto, scto, wto shortcuts.
	 */
    void fixTo(Type t)
	{
	   // A nice little one-letter nested function
      static uint X(MOD m, MOD n) { return (((m) << 4) | (n)); }

		ito = t.ito;

		assert(mod != t.mod);

      switch (X(mod, t.mod))
      {
         case X(MODundefined, MODconst):
            cto = t;
            break;

         case X(MODundefined, MODimmutable):
            ito = t;
            break;

         case X(MODundefined, MODshared):
            sto = t;
            break;

         case X(MODundefined, MODshared | MODconst):
            scto = t;
            break;

         case X(MODundefined, MODwild):
            wto = t;
            break;

         case X(MODundefined, MODshared | MODwild):
            swto = t;
            break;


         case X(MODconst, MODundefined):
            cto = null;
            goto L2;

         case X(MODconst, MODimmutable):
            ito = t;
            goto L2;

         case X(MODconst, MODshared):
            sto = t;
            goto L2;

         case X(MODconst, MODshared | MODconst):
            scto = t;
            goto L2;

         case X(MODconst, MODwild):
            wto = t;
            goto L2;

         case X(MODconst, MODshared | MODwild):
            swto = t;
L2:
            t.cto = this;
            break;


         case X(MODimmutable, MODundefined):
            ito = null;
            goto L3;

         case X(MODimmutable, MODconst):
            cto = t;
            goto L3;

         case X(MODimmutable, MODshared):
            sto = t;
            goto L3;

         case X(MODimmutable, MODshared | MODconst):
            scto = t;
            goto L3;

         case X(MODimmutable, MODwild):
            wto = t;
            goto L3;

         case X(MODimmutable, MODshared | MODwild):
            swto = t;
L3:
            t.ito = this;
            if (t.cto) t.cto.ito = this;
            if (t.sto) t.sto.ito = this;
            if (t.scto) t.scto.ito = this;
            if (t.wto) t.wto.ito = this;
            if (t.swto) t.swto.ito = this;
            break;


         case X(MODshared, MODundefined):
            sto = null;
            goto L4;

         case X(MODshared, MODconst):
            cto = t;
            goto L4;

         case X(MODshared, MODimmutable):
            ito = t;
            goto L4;

         case X(MODshared, MODshared | MODconst):
            scto = t;
            goto L4;

         case X(MODshared, MODwild):
            wto = t;
            goto L4;

         case X(MODshared, MODshared | MODwild):
            swto = t;
L4:
            t.sto = this;
            break;


         case X(MODshared | MODconst, MODundefined):
            scto = null;
            goto L5;

         case X(MODshared | MODconst, MODconst):
            cto = t;
            goto L5;

         case X(MODshared | MODconst, MODimmutable):
            ito = t;
            goto L5;

         case X(MODshared | MODconst, MODwild):
            wto = t;
            goto L5;

         case X(MODshared | MODconst, MODshared):
            sto = t;
            goto L5;

         case X(MODshared | MODconst, MODshared | MODwild):
            swto = t;
L5:
            t.scto = this;
            break;

         case X(MODwild, MODundefined):
            wto = null;
            goto L6;

         case X(MODwild, MODconst):
            cto = t;
            goto L6;

         case X(MODwild, MODimmutable):
            ito = t;
            goto L6;

         case X(MODwild, MODshared):
            sto = t;
            goto L6;

         case X(MODwild, MODshared | MODconst):
            scto = t;
            goto L6;

         case X(MODwild, MODshared | MODwild):
            swto = t;
L6:
            t.wto = this;
            break;


         case X(MODshared | MODwild, MODundefined):
            swto = null;
            goto L7;

         case X(MODshared | MODwild, MODconst):
            cto = t;
            goto L7;

         case X(MODshared | MODwild, MODimmutable):
            ito = t;
            goto L7;

         case X(MODshared | MODwild, MODshared):
            sto = t;
            goto L7;

         case X(MODshared | MODwild, MODshared | MODconst):
            scto = t;
            goto L7;

         case X(MODshared | MODwild, MODwild):
            wto = t;
L7:
            t.swto = this;
            break;
         default:
            // QUALITY probably can just "break;" w/ no message
            writeln("Type.fixTo() found a caseX it didn't match with... error?");
            break;
      }

      check();
      t.check();
      //printf("fixTo: %s, %s\n", toChars(), t.toChars());
   }

   /***************************
    * Look for bugs in constructing types.
    */
   void check()
   {
      switch (mod)
      {
         case MODundefined:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODconst:
            if (cto) assert(cto.mod == MODundefined);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODimmutable:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODundefined);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODshared:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODundefined);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODshared | MODconst:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == MODundefined);
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODwild:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODundefined);
            if (swto) assert(swto.mod == (MODshared | MODwild));
            break;

         case MODshared | MODwild:
            if (cto) assert(cto.mod == MODconst);
            if (ito) assert(ito.mod == MODimmutable);
            if (sto) assert(sto.mod == MODshared);
            if (scto) assert(scto.mod == (MODshared | MODconst));
            if (wto) assert(wto.mod == MODwild);
            if (swto) assert(swto.mod == MODundefined);
            break;
         default:
            // QUALITY this message is proabbly totally unnecessary
            import std.stdio;
            writeln("Type.check found a case it couldn't match.");
            break;
      }

      Type tn = nextOf();
      if (tn && ty != Tfunction && ty != Tdelegate)
      {
         // Verify transitivity
         switch (mod)
         {
            case MODundefined:
               break;

            case MODconst:
               assert(tn.mod & MODimmutable || tn.mod & MODconst);
               break;

            case MODimmutable:
               assert(tn.mod == MODimmutable);
               break;

            case MODshared:
               assert(tn.mod & MODimmutable || tn.mod & MODshared);
               break;

            case MODshared | MODconst:
               assert(tn.mod & MODimmutable || tn.mod & (MODshared | MODconst));
               break;

            case MODwild:
               assert(tn.mod);
               break;

            case MODshared | MODwild:
               assert(tn.mod == MODimmutable || tn.mod == (MODshared | MODconst) || tn.mod == (MODshared | MODwild));
               break;
            default:
               break;
         }
         tn.check();
		}
	}

	/************************************
	 * Apply MODxxxx bits to existing type.
	 */
    Type castMod(uint mod)
	{
		Type t;

		switch (mod)
		{
		case 0:
			t = unSharedOf().mutableOf();
			break;

		case MODconst:
			t = unSharedOf().constOf();
			break;

		case MODimmutable:
			t = invariantOf();
			break;

		case MODshared:
			t = mutableOf().sharedOf();
			break;

		case MODshared | MODconst:
			t = sharedConstOf();
	        break;

	    case MODwild:
	        t = unSharedOf().wildOf();
	        break;

	    case MODshared | MODwild:
	        t = sharedWildOf();
			break;

		default:
			assert(0);
		}
		return t;
	}

	/************************************
	 * Add MODxxxx bits to existing type.
	 * We're adding, not replacing, so adding const to
	 * a shared type => "shared const"
	 */
    Type addMod(MOD mod)
	{
		Type t = this;

		/* Add anything to immutable, and it remains immutable
		 */
        //printf("addMod(%x) %s\n", mod, toChars());
		if (!t.isImmutable())
		{
			switch (mod)
			{
				case MODundefined:
					break;

				case MODconst:
					if (isShared())
						t = sharedConstOf();
					else
						t = constOf();
					break;

				case MODimmutable:
					t = invariantOf();
					break;

				case MODshared:
					if (isConst())
						t = sharedConstOf();
		            else if (isWild())
		                t = sharedWildOf();
					else
						t = sharedOf();
					break;

				case MODshared | MODconst:
					t = sharedConstOf();
					break;

	            case MODwild:
		            if (isConst())
                    {}
		            else if (isShared())
		                t = sharedWildOf();
		            else
		                t = wildOf();
		            break;

	            case MODshared | MODwild:
		            t = sharedWildOf();
		            break;
               default:
                  break;
			}
		}
		return t;
	}

    Type addStorageClass(StorageClass stc)
	{
		/* Just translate to MOD bits and let addMod() do the work
		 */
		MOD mod = MODundefined;

		if (stc & STCimmutable)
			mod = MODimmutable;
		else
		{
			if (stc & (STCconst | STCin))
				mod = MODconst;
			if (stc & STCshared)
				mod |= MODshared;
	        if (stc & STCwild)
	            mod |= MODwild;
		}

		return addMod(mod);
	}

    Type pointerTo()
	{
		if (pto is null)
		{
			Type t = new TypePointer(this);
			pto = t.merge();
		}

		return pto;
	}

    Type referenceTo()
	{
		assert(false);
	}

	final Type clone() { return cloneThis(this); }

    Type arrayOf()
	{
		if (!arrayof)
		{
			Type t = new TypeDArray(this);
			arrayof = t.merge();
		}
		return arrayof;
	}


    Type makeConst()
	{
		//printf("Type.makeConst() %p, %s\n", this, toChars());
		if (cto)
			return cto;

		Type t = clone();
		t.mod = MODconst;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		//printf("-Type.makeConst() %p, %s\n", t, toChars());
		return t;
	}

    Type makeInvariant()
	{
		if (ito) {
			return ito;
		}

		Type t = clone();
		t.mod = MODimmutable;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeShared()
	{
		if (sto)
			return sto;

		Type t = clone();
		t.mod = MODshared;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeSharedConst()
	{
		if (scto)
			return scto;

		Type t = clone();
		t.mod = MODshared | MODconst;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeWild()
    {
        if (wto)
	        return wto;

        Type t = clone();
        t.mod = MODwild;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

    Type makeSharedWild()
    {
        if (swto)
	        return swto;

        Type t = clone();
        t.mod = MODshared | MODwild;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

    Type makeMutable()
    {
        Type t = clone();
        t.mod =  mod & MODshared;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

	/*******************************
	 * If this is a shell around another type,
	 * get that other type.
	 */


	/**************************
	 * Return type with the top level of it being mutable.
	 */
    Type toHeadMutable()
	{
		if (!mod)
			return this;

		return mutableOf();
	}


    bool isBaseOf(Type t, int* poffset) 
    { 
      return false; // assume not
    }
	
   /*******************************
	 * Determine if converting 'this' to 'to' is an identity operation,
	 * a conversion to const operation, or the types aren't the same.
	 * Returns:
	 *	MATCHequal	'this' == 'to'
	 *	MATCHconst	'to' is const
	 *	MATCHnomatch	conversion to mutable or invariant
	 */
    MATCH constConv(Type to)
	{
		if (equals(to))
			return MATCHexact;
		if (ty == to.ty && MODimplicitConv(mod, to.mod))
			return MATCHconst;
		return MATCHnomatch;
	}

	/********************************
	 * Determine if 'this' can be implicitly converted
	 * to type 'to'.
	 * Returns:
	 *	MATCHnomatch, MATCHconvert, MATCHconst, MATCHexact
	 */
    MATCH implicitConvTo(Type to)
	{
		//printf("Type.implicitConvTo(this=%p, to=%p)\n", this, to);
		//printf("from: %s\n", toChars());
		//printf("to  : %s\n", to.toChars());
		if (this is to)
			return MATCHexact;

		return MATCHnomatch;
	}


    TypeBasic isTypeBasic() { assert(false); }


    ClassDeclaration isClassHandle()
	{
		return null;
	}

    Identifier getTypeInfoIdent(int internal)
	{
		// _init_10TypeInfo_%s
		auto buf = appender!(char[])();
		Identifier id;
      string name;

		if (internal)
		{
			buf.put(mangleChar[ty]);
			if (ty == Tarray)
				buf.put(mangleChar[(cast(TypeArray)this).next.ty]);
		}
		else
			toDecoBuffer(buf);

      name = format("_D%dTypeInfo_%s6__initZ", 9 + buf.data.length , buf.data);

		id = Identifier.idPool(name);
		return id;
	}


	/****************************************************
	 * Get the exact TypeInfo.
	 */
    Expression getTypeInfo(Scope sc) { assert(false,"zd cut"); }

    TypeInfoDeclaration getTypeInfoDeclaration() { assert(false,"zd cut"); }

	/* These decide if there's an instance for them already in std.typeinfo,
	 * because then the compiler doesn't need to build one.
	 */
    bool builtinTypeInfo()
	{
		return false;
	}

	/*******************************
	 * If one of the subtypes of this type is a TypeIdentifier,
	 * i.e. it's an unresolved type, return that type.
	 */
    Type reliesOnTident()
	{
		return null;
	}

    /***************************************
     * Return !=0 if the type or any of its subtypes is wild.
     */

    int hasWild() { assert(false,"zd cut"); }

    /***************************************
     * Return MOD bits matching argument type (targ) to wild parameter type (this).
     */

    uint wildMatch(Type targ) { assert(false,"zd cut"); }


	/***************************************
	 * Return true if type has pointers that need to
	 * be scanned by the GC during a collection cycle.
	 */

	/*************************************
	 * If this is a type of something, return that something.
	 */
    Type nextOf()
	{
		return null;
	}

	/****************************************
	 * Return the mask that an integral type will
	 * fit into.
	 */
    //ulong sizemask() { assert(false,"zd cut"); }

    static void error(T...)(Loc loc, string format, T t)
	{
		.error(loc, format, t);
	}

    static void warning(T...)(Loc loc, string format, T t)
	{
		assert(false);
	}

    // For backend
	/*****************************
	 * Return back end type corresponding to D front end type.
	 */

	/***************************************
	 * Convert from D type to C type.
	 * This is done so C debug info can be generated.
	 */



    // For eliminating dynamic_cast
    //TypeBasic isTypeBasic() { assert(false,"zd cut"); }

	@property
	static ref Type[TMAX] basic()
	{
		return global.basic;
	}

	static Type tvoid()
	{
		return basic[Tvoid];
	}

	static Type tint8()
	{
		return basic[Tint8];
	}

	static Type tuns8()
	{
		return basic[Tuns8];
	}

	static Type tint16()
	{
		return basic[Tint16];
	}

	static Type tuns16()
	{
		return basic[Tuns16];
	}

	static Type tint32()
	{
		return basic[Tint32];
	}

	static Type tuns32()
	{
		return basic[Tuns32];
	}

	static Type tint64()
	{
		return basic[Tint64];
	}

	static Type tuns64()
	{
		return basic[Tuns64];
	}

	static Type tfloat32()
	{
		return basic[Tfloat32];
	}

	static Type tfloat64()
	{
		return basic[Tfloat64];
	}

	static Type tfloat80()
	{
		return basic[Tfloat80];
	}

	static Type timaginary32()
	{
		return basic[Timaginary32];
	}

	static Type timaginary64()
	{
		return basic[Timaginary64];
	}

	static Type timaginary80()
	{
		return basic[Timaginary80];
	}

	static Type tcomplex32()
	{
		return basic[Tcomplex32];
	}

	static Type tcomplex64()
	{
		return basic[Tcomplex64];
	}

	static Type tcomplex80()
	{
		return basic[Tcomplex80];
	}

	static Type tbit()
	{
		return basic[Tbit];
	}

	static Type tbool()
	{
		return basic[Tbool];
	}

	static Type tchar()
	{
		return basic[Tchar];
	}

	static Type twchar()
	{
		return basic[Twchar];
	}

	static Type tdchar()
	{
		return basic[Tdchar];
	}

	// Some special types
    static Type tshiftcnt()
	{
		return tint32;		// right side of shift expression
	}

//    #define tboolean	tint32		// result of boolean expression
    static Type tboolean()
	{
		return tbool;		// result of boolean expression
	}

    static Type tindex()
	{
		return tint32;		// array/ptr index
	}

	static Type terror()
	{
		return basic[Terror];	// for error recovery
	}

    static Type tsize_t()
	{
		return basic[Tsize_t];		// matches size_t alias
	}

    static Type tptrdiff_t()
	{
		return basic[Tptrdiff_t];	// matches ptrdiff_t alias
	}

    static Type thash_t()
	{
		return tsize_t;			// matches hash_t alias
	}
}

