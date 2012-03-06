module dmd.type;

import dmd.global;
import dmd.parameter;
import dmd.templateParameter;
import dmd.Module;
import dmd.varDeclaration;
import dmd.Scope;
import dmd.identifier;
import dmd.hdrGenState;
import dmd.expression;
import dmd.dsymbol;
import dmd.declaration;
import dmd.typeInfoDeclaration;
import dmd.scopeDsymbol;
import dmd.token;

import std.array;
import std.stdio;
import std.string;
import std.conv;
import std.format;

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
	static pure uint X(MOD m, MOD n)
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

/+
/***********************
 * Try to get arg as a type.
 */
Type getType()
{
   Type t = isType();
   if (!t)
   {   
      Expression e = isExpression();
      if (e)
         t = e.type;
   }
   return t;
}
+/

// MARK : Need this here?
Dobject objectSyntaxCopy(Dobject o)
{
    if (!o)
        return null;

    Type t = cast(Type)( o.isType() );
    if (t)
        return t.syntaxCopy();

    Expression e = cast(Expression)( o.isExpression() );
    if (e)
        return e.syntaxCopy();

    return o;
}

class Type : Dobject
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
    // unless I declare it in another module (dmd.token)
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

    bool equals(Dobject o) 
    {   
       Type t;

       t = cast(Type) o;
       //printf("Type::equals(%s, %s)\n", toChars(), t->toChars());
       if (this is o ||
             (t && (deco == t.deco)) && // deco strings are unique
             deco != null)             // and semantic() has been run
       {
          //printf("deco = '%s', t->deco = '%s'\n", deco, t->deco);
          return true;
       }
       //if (deco && t && t->deco) printf("deco = '%s', t->deco = '%s'\n", deco, t->deco);
       return false;
    }

    int covariant(Type t) { assert(false,"zd cut"); }

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
    
    string toChars()
    {
       auto buf = appender!(char[])();

       HdrGenState hgs;
       toCBuffer(buf, null, hgs);
       return buf.data.idup;
    }

    void toCBuffer(ref Appender!(char[]) buf, Identifier ident, ref HdrGenState hgs)
	{
		toCBuffer2(buf, hgs, 0/+MODundefined+/);
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
    
    bool isintegral()
	{
		return false;
	}

    bool isfloating()	// real, imaginary, or complex
	{
		return false;
	}

    // Apparently we've mistakenly parsed this Type as an Expression
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
   
   override Type isType() { return this; }
}

class TypeAArray : TypeArray
{
    Type	index;		// key type
    Loc		loc;
    Scope	sc;
    StructDeclaration impl;	// implementation

    this(Type t, Type index)
	{
		super(Taarray, t);
		this.index = index;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Type ti = index.syntaxCopy();
		if (t == next && ti == index)
			t = this;
		else
		{	
			t = new TypeAArray(t, ti);
			t.mod = mod;
		}
		return t;
	}

    override ulong size(Loc loc)
	{
		return PTRSIZE /* * 2*/;
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		index.toDecoBuffer(buf);
		next.toDecoBuffer(buf, (flag & 0x100) ? MODundefined : mod);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.put('[');
		index.toCBuffer2(buf, hgs, MODundefined);
		buf.put(']');
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoAssociativeArrayDeclaration(this);
	}
}

class TypeArray : TypeNext
{
    this(TY ty, Type next)
	{
		super(ty, next);
	}

}

class TypeBasic : Type
{
    string dstring_;
    uint flags;

    this(TY ty)
	{
		super(ty);

		enum TFLAGSintegral	= 1;
		enum TFLAGSfloating = 2;
		enum TFLAGSunsigned = 4;
		enum TFLAGSreal = 8;
		enum TFLAGSimaginary = 0x10;
		enum TFLAGScomplex = 0x20;

		string d;

		uint flags = 0;
		switch (ty)
		{
		case Tvoid:	d = Token.toChars(TOKvoid);
				break;

		case Tint8:	d = Token.toChars(TOKint8);
				flags |= TFLAGSintegral;
				break;

		case Tuns8:	d = Token.toChars(TOKuns8);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tint16:	d = Token.toChars(TOKint16);
				flags |= TFLAGSintegral;
				break;

		case Tuns16:	d = Token.toChars(TOKuns16);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tint32:	d = Token.toChars(TOKint32);
				flags |= TFLAGSintegral;
				break;

		case Tuns32:	d = Token.toChars(TOKuns32);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tfloat32:	d = Token.toChars(TOKfloat32);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Tint64:	d = Token.toChars(TOKint64);
				flags |= TFLAGSintegral;
				break;

		case Tuns64:	d = Token.toChars(TOKuns64);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tfloat64:	d = Token.toChars(TOKfloat64);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Tfloat80:	d = Token.toChars(TOKfloat80);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case Timaginary32: d = Token.toChars(TOKimaginary32);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Timaginary64: d = Token.toChars(TOKimaginary64);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Timaginary80: d = Token.toChars(TOKimaginary80);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case Tcomplex32: d = Token.toChars(TOKcomplex32);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tcomplex64: d = Token.toChars(TOKcomplex64);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tcomplex80: d = Token.toChars(TOKcomplex80);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case Tbool:	d = "bool";
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tascii:	d = Token.toChars(TOKchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Twchar:	d = Token.toChars(TOKwchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case Tdchar:	d = Token.toChars(TOKdchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;
		default:
		}

		this.dstring_ = d;
		this.flags = flags;
		merge();
	}

    override Type syntaxCopy()
	{
		// No semantic analysis done on basic types, no need to copy
		return this;
	}
	
    override ulong size(Loc loc)
	{
		uint size;

		//printf("TypeBasic.size()\n");
		switch (ty)
		{
			case Tint8:
			case Tuns8:	size = 1;	break;
			case Tint16:
			case Tuns16:	size = 2;	break;
			case Tint32:
			case Tuns32:
			case Tfloat32:
			case Timaginary32:
					size = 4;	break;
			case Tint64:
			case Tuns64:
			case Tfloat64:
			case Timaginary64:
					size = 8;	break;
			case Tfloat80:
			case Timaginary80:
					size = REALSIZE;	break;
			case Tcomplex32:
					size = 8;		break;
			case Tcomplex64:
					size = 16;		break;
			case Tcomplex80:
					size = REALSIZE * 2;	break;

			case Tvoid:
				//size = Type.size();	// error message
				size = 1;
				break;

			case Tbool:	size = 1;		break;
			case Tascii:	size = 1;		break;
			case Twchar:	size = 2;		break;
			case Tdchar:	size = 4;		break;

			default:
				assert(0);
		}

		//printf("TypeBasic.size() = %d\n", size);
		return size;
	}
	
    override uint alignsize()
	{
		uint sz;

		switch (ty)
		{
		case Tfloat80:
		case Timaginary80:
		case Tcomplex80:
			sz = REALALIGNSIZE;
			break;

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		case Tint64:
		case Tuns64:
		case Tfloat64:
		case Timaginary64:
		case Tcomplex32:
		case Tcomplex64:
			sz = 4;
			break;
}

		default:
			sz = cast(uint)size(Loc(0));	///
			break;
		}

		return sz;
	}
	
    override string toChars()
	{
		return Type.toChars();
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeBasic.toCBuffer2(mod = %d, this.mod = %d)\n", mod, this.mod);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(dstring_);
	}
	
    override bool isintegral()
	{
		//printf("TypeBasic.isintegral('%s') x%x\n", toChars(), flags);
		return (flags & TFLAGSintegral) != 0;
	}
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isfloating()
	{
		return (flags & TFLAGSfloating) != 0;
	}
	
    override bool isreal()
	{
		return (flags & TFLAGSreal) != 0;
	}
	
    override bool isimaginary()
	{
		return (flags & TFLAGSimaginary) != 0;
	}
	
    override bool iscomplex()
	{
		return (flags & TFLAGScomplex) != 0;
	}

    override bool isscalar()
	{
		return (flags & (TFLAGSintegral | TFLAGSfloating)) != 0;
	}
	
    override bool isunsigned()
	{
		return (flags & TFLAGSunsigned) != 0;
	}
	
    override bool builtinTypeInfo()
	{
		return mod ? false : true;
	}
	
    // For eliminating dynamic_cast
    override TypeBasic isTypeBasic()
	{
		return this;
	}
}

class TypeClass : Type
{
    ClassDeclaration sym;

    this(ClassDeclaration sym)
	{
		super(Tclass);
		this.sym = sym;
	}

    override ulong size(Loc loc)
	{
		return PTRSIZE;
	}
	
    override string toChars()
	{
		if (mod)
			return Type.toChars();
		return sym.toPrettyChars();
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		string name = sym.mangle();
		//printf("TypeClass.toDecoBuffer('%s' flag=%d mod=%x) = '%s'\n", toChars(), flag, mod, name);
		Type.toDecoBuffer(buf, flag);
		buf.put( name );
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(sym.toChars());
	}
	
    override ClassDeclaration isClassHandle()
	{
		return sym;
	}
	
    override bool isBaseOf(Type t, int* poffset)
    {
        assert (false);
    }	
	
    override bool isauto()
	{
		return sym.isauto;
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		if (sym.isInterfaceDeclaration())
			return new TypeInfoInterfaceDeclaration(this);
		else
			return new TypeInfoClassDeclaration(this);
	}
	
    override bool builtinTypeInfo()
	{
		/* This is statically put out with the ClassInfo, so
		 * claim it is built in so it isn't regenerated by each module.
		 */
		return mod ? false : true;
	}
	
}

// Dynamic array, no dimension
class TypeDArray : TypeArray
{
    this(Type t)
	{
		super(Tarray, t);
		//printf("TypeDArray(t = %p)\n", t);
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDArray(t);
			t.mod = mod;
		}
		return t;
	}
	
    override ulong size(Loc loc)
	{
		//printf("TypeDArray.size()\n");
		return PTRSIZE * 2;
	}
	
    override uint alignsize()
	{
		// A DArray consists of two ptr-sized values, so align it on pointer size
		// boundary
		return PTRSIZE;
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (next)
			next.toDecoBuffer(buf, (flag & 0x100) ? 0 : mod);
	}
	
	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		if (equals(global.tstring))
			buf.put("string");
		else
		{
			next.toCBuffer2(buf, hgs, this.mod);
			buf.put("[]");
		}
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoArrayDeclaration(this);
	}

}

class TypeDelegate : TypeNext
{
    // .next is a TypeFunction

    this(Type t)
	{
		super(Tfunction, t);
		ty = Tdelegate;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDelegate(t);
			t.mod = mod;
		}
		return t;
	}
	
    override ulong size(Loc loc)
	{
		return PTRSIZE * 2;
	}
    
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TypeFunction tf = cast(TypeFunction)next;

		tf.next.toCBuffer2(buf, hgs, MODundefined);
		buf.put(" delegate");
		Parameter.argsToCBuffer(buf, hgs, tf.parameters, tf.varargs);
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoDelegateDeclaration(this);
	}

}

class TypeEnum : Type
{
    EnumDeclaration sym;

    this(EnumDeclaration sym)
	{
		super(Tenum);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		if (!sym.memtype)
		{
			error(loc, "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.size(loc);
	}
	
	override uint alignsize()
	{
		if (!sym.memtype)
		{
			debug writef("1: ");

			error(Loc(0), "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.alignsize();
	}

	override string toChars()
	{
		if (mod)
			return super.toChars();
		return sym.toChars();
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		string name = sym.mangle();
		Type.toDecoBuffer(buf, flag);
		buf.put( name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(sym.toChars());
	}
	
    override bool isintegral()
	{
	    return sym.memtype.isintegral();
	}
	
    override bool isfloating()
	{
	    return sym.memtype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.memtype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.memtype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.memtype.iscomplex();
	}
	
    override bool checkBoolean()
	{
		return sym.memtype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.memtype.isAssignable();
	}
	
    override bool isscalar()
	{
	    return sym.memtype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.memtype.isunsigned();
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoEnumDeclaration(this);
	}
}

class TypeFunction : TypeNext
{
    // .next is the return type

    Parameter[] parameters;	// function parameters
    int varargs;	// 1: T t, ...) style for variable number of arguments
			// 2: T t ...) style for variable number of arguments
    bool isnothrow;	// true: nothrow
    bool ispure;	// true: pure
    bool isproperty;	// can be called without parentheses
    bool isref;		// true: returns a reference
    LINK linkage;	// calling convention
    TRUST trust;	// level of trust
    Expression[] fargs;	// function arguments

    int inuse;

    this(Parameter[] parameters, Type treturn, int varargs, LINK linkage)
	{
		super(Tfunction, treturn);

		//if (!treturn) *(char*)0=0;
	//    assert(treturn);
		assert(0 <= varargs && varargs <= 2);
		this.parameters = parameters;
		this.varargs = varargs;
		this.linkage = linkage;
        this.trust = TRUSTdefault;
	}
	
    override Type syntaxCopy()
	{
		Type treturn = next ? next.syntaxCopy() : null;
		auto params = Parameter.arraySyntaxCopy(parameters);
		TypeFunction t = new TypeFunction(params, treturn, varargs, linkage);
		t.mod = mod;
		t.isnothrow = isnothrow;
		t.ispure = ispure;
		t.isproperty = isproperty;
		t.isref = isref;
        t.trust = trust;
        t.fargs = fargs;

		return t;
	}
	
    //override void toDecoBuffer(ref Appender!(char[]) buf, int flag) { assert(false,"zd cut"); }
	
    override void toCBuffer(ref Appender!(char[]) buf, Identifier ident, ref HdrGenState hgs)
	{
		//printf("TypeFunction.toCBuffer() this = %p\n", this);
		string p = null;

		if (inuse)
		{	
			inuse = 2;		// flag error to caller
			return;
		}
		inuse++;

		/* Use 'storage class' style for attributes
		 */
	    if (mod)
        {
	        MODtoBuffer(buf, mod);
	        buf.put(' ');
        }

		if (ispure)
			buf.put("pure ");
		if (isnothrow)
			buf.put("nothrow ");
		if (isproperty)
			buf.put("@property ");
		if (isref)
			buf.put("ref ");

        switch (trust)
        {
           case TRUSTtrusted:
              buf.put("@trusted ");
              break;

           case TRUSTsafe:
              buf.put("@safe ");
              break;

           default:
        }

		if (next && (!ident || ident.toHChars2() == ident.toChars()))
			next.toCBuffer2(buf, hgs, MODundefined);
		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:		p = null;	break;
				case LINKc:		p = " C";	break;
				case LINKwindows:	p = " Windows";	break;
				case LINKpascal:	p = " Pascal";	break;
				case LINKcpp:	p = " C++";	break;
				default:
				assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.put(p);
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toHChars2());
		}
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);
		inuse--;
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeFunction::toCBuffer2() this = %p, ref = %d\n", this, isref);
		string p;

		if (inuse)
		{
			inuse = 2;		// flag error to caller
			return;
		}

		inuse++;
		if (next)
			next.toCBuffer2(buf, hgs, MODundefined);

		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:			p = null;		break;
				case LINKc:			p = "C ";		break;
				case LINKwindows:	p = "Windows ";	break;
				case LINKpascal:	p = "Pascal ";	break;
				case LINKcpp:		p = "C++ ";		break;
				default: assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.put(p);
		buf.put(" function");
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);

		/* Use postfix style for attributes
		 */
		if (mod != this.mod)
		{
			modToBuffer(buf);
		}

		if (ispure)
			buf.put(" pure");
		if (isnothrow)
			buf.put(" nothrow");
		if (isproperty)
			buf.put(" @property");
		if (isref)
			buf.put(" ref");

        switch (trust)
        {
	    case TRUSTtrusted:
	        buf.put(" @trusted");
	        break;

	    case TRUSTsafe:
	        buf.put(" @safe");
	        break;

		default:
        }
		inuse--;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoFunctionDeclaration(this);
	}
	
    //override Type reliesOnTident() { assert(false,"zd cut"); }
}

class TypeIdentifier : TypeQualified
{
    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		super(Tident, loc);
		this.ident = ident;
	}
	
    override Type syntaxCopy()
	{
		TypeIdentifier t = new TypeIdentifier(loc, ident);
		t.mod = mod;

		return t;
	}
	
    //char *toChars();
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = ident.toChars();
		buf.put( to!string(name.length) ~ name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.put(this.ident.toChars());
		toCBuffer2Helper(buf, hgs);
	}
	
    override Type reliesOnTident()
	{
		return this;
	}
	
}

/* Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
class TypeInstance : TypeQualified
{
	TemplateInstance tempinst;

	this(Loc loc, TemplateInstance tempinst)
	{
		super(Tinstance, loc);
		this.tempinst = tempinst;
	}

	override Type syntaxCopy()
	{
		//printf("TypeInstance::syntaxCopy() %s, %d\n", toChars(), idents.length);
		TypeInstance t;

		t = new TypeInstance(loc, cast(TemplateInstance)tempinst.syntaxCopy(null));
		t.mod = mod;
		return t;
	}

	//char *toChars();

	//void toDecoBuffer(ref Appender!(char[]) *buf, int flag);

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	toCBuffer3(buf, hgs, mod);
			return;
		}
		tempinst.toCBuffer(buf, hgs);
		toCBuffer2Helper(buf, hgs);
	}
}

/** T[new]
 */
class TypeNewArray : TypeNext
{
	this(Type next)
	{
		super(Tnarray, next);
		//writef("TypeNewArray\n");
	}

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.put("[new]");
	}
}

class TypeNext : Type
{
    Type next;

    this(TY ty, Type next)
	{
		super(ty);
		this.next = next;
	}

    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		super.toDecoBuffer(buf, flag);
		assert(next !is this);
		//printf("this = %p, ty = %d, next = %p, ty = %d\n", this, this.ty, next, next.ty);
		next.toDecoBuffer(buf, (flag & 0x100) ? 0 : mod);
	}

    override void checkDeprecated(Loc loc, Scope sc)
	{
		Type.checkDeprecated(loc, sc);
		if (next)	// next can be null if TypeFunction and auto return type
			next.checkDeprecated(loc, sc);
	}
	
    override Type reliesOnTident()
	{
		return next.reliesOnTident();
	}
	
    override int hasWild()
    {
        return mod == MODwild || next.hasWild();
    }

    /***************************************
     * Return MOD bits matching argument type (targ) to wild parameter type (this).
     */
    
    override Type nextOf()
	{
		return next;
	}
	
    override Type makeConst()
	{
		//printf("TypeNext::makeConst() %p, %s\n", this, toChars());
		if (cto)
		{
			assert(cto.mod == MODconst);
			return cto;
		}
		
		TypeNext t = cast(TypeNext)super.makeConst();
		if (ty != Tfunction && ty != Tdelegate &&
			(next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isConst())
		{
			if (next.isShared())
				t.next = next.sharedConstOf();
			else
				t.next = next.constOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		//writef("TypeNext::makeConst() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
    override Type makeInvariant()
	{
		//printf("TypeNext::makeInvariant() %s\n", toChars());
		if (ito)
		{	
			assert(ito.isImmutable());
			return ito;
		}
		TypeNext t = cast(TypeNext)Type.makeInvariant();
		if (ty != Tfunction && ty != Tdelegate && (next.deco || next.ty == Tfunction) && !next.isImmutable())
		{	
			t.next = next.invariantOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		return t;
	}
	
    override Type makeShared()
	{
		//printf("TypeNext::makeShared() %s\n", toChars());
		if (sto)
		{	
			assert(sto.mod == MODshared);
			return sto;
		}    
		TypeNext t = cast(TypeNext)Type.makeShared();
		if (ty != Tfunction && ty != Tdelegate &&
			(next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isShared())
		{
			if (next.isConst() || next.isWild())
				t.next = next.sharedConstOf();
			else
				t.next = next.sharedOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
		//writef("TypeNext::makeShared() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
	override Type makeSharedConst()
	{
		//printf("TypeNext::makeSharedConst() %s\n", toChars());
		if (scto)
		{
			assert(scto.mod == (MODshared | MODconst));
			return scto;
		}
		TypeNext t = cast(TypeNext) Type.makeSharedConst();
		if (ty != Tfunction && ty != Tdelegate &&
		    (next.deco || next.ty == Tfunction) &&
			!next.isImmutable() && !next.isSharedConst())
		{
			t.next = next.sharedConstOf();
		}
		if (ty == Taarray)
		{
			(cast(TypeAArray)t).impl = null;		// lazily recompute it
		}
//		writef("TypeNext::makeSharedConst() returns %p, %s\n", t, t.toChars());
		return t;
	}
	
    override Type makeWild()
    {
        //printf("TypeNext::makeWild() %s\n", toChars());
        if (wto)
        {
            assert(wto.mod == MODwild);
	        return wto;
        }    
        auto t = cast(TypeNext)Type.makeWild();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            !next.isImmutable() && !next.isConst() && !next.isWild())
        {
	        if (next.isShared())
	            t.next = next.sharedWildOf();
	        else
	            t.next = next.wildOf();
        }
        if (ty == Taarray)
        {
    	    (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeWild() returns %p, %s\n", t, t->toChars());
        return t;
    }

    override Type makeSharedWild()
    {
        //printf("TypeNext::makeSharedWild() %s\n", toChars());
        if (swto)
        {
            assert(swto.isSharedWild());
	        return swto;
        }    
        auto t = cast(TypeNext)Type.makeSharedWild();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            !next.isImmutable() && !next.isSharedConst())
        {
	        t.next = next.sharedWildOf();
        }
        if (ty == Taarray)
        {
	        (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeSharedWild() returns %p, %s\n", t, t->toChars());
        return t;
    }

    override Type makeMutable()
    {
        //printf("TypeNext::makeMutable() %p, %s\n", this, toChars());
        auto t = cast(TypeNext)Type.makeMutable();
        if (ty != Tfunction && ty != Tdelegate &&
	    (next.deco || next.ty == Tfunction) &&
            next.isWild())
        {
	        t.next = next.mutableOf();
        }
        if (ty == Taarray)
        {
	        (cast(TypeAArray)t).impl = null;		// lazily recompute it
        }
        //printf("TypeNext::makeMutable() returns %p, %s\n", t, t->toChars());
        return t;
    }
	
	void transitive()
	{
		/* Invoke transitivity of type attributes
		 */
		next = next.addMod(mod);
	}
}

class TypePointer : TypeNext
{
    this(Type t)
	{
		super(Tpointer, t);
	}

    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypePointer(t);
			t.mod = mod;
		}
		return t;
	}
	
    override ulong size(Loc loc)
	{
		return PTRSIZE;
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypePointer::toCBuffer2() next = %d\n", next->ty);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		if (next.ty != Tfunction)
			buf.put('*');
	}
	
    override bool isscalar()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoPointerDeclaration(this);
	}

}

class TypeQualified : Type
{
    Loc loc;
    Identifier[] idents;	// array of Identifier's representing ident.ident.ident etc.

    this(TY ty, Loc loc)
	{
		super(ty);
		this.loc = loc;
		
	}

    void addIdent(Identifier ident)
	{
		assert(ident !is null);
		idents ~= ident;
	}

    void toCBuffer2Helper(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		foreach (i; idents)
		{
			Identifier id = i;
			buf.put('.');

			if (id.dyncast() == DYNCAST_DSYMBOL)
			{
				TemplateInstance ti = cast(TemplateInstance)id;
				ti.toCBuffer(buf, hgs);
			} else {
				buf.put(id.toChars());
			}
		}
	}
}

class TypeReference : TypeNext
{
    this(Type t)
	{
		super( TY.init, null);
		assert(false);
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		assert(false);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		assert(false);
	}
	
}

class TypeReturn : TypeQualified
{
   this(Loc loc)
   {
      super(Treturn, loc);
   }

   void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
   {
      if (mod != this.mod)
      {   
         toCBuffer3(buf, hgs, mod);
         return;
      }
      buf.put("typeof(return)");
      toCBuffer2Helper(buf, hgs);
   }
}

// Static array, one with a fixed dimension
class TypeSArray : TypeArray
{
    Expression dim;

    this(Type t, Expression dim)
	{
		super(Tsarray, t);
		//printf("TypeSArray(%s)\n", dim.toChars());
		this.dim = dim;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Expression e = dim.syntaxCopy();
		t = new TypeSArray(t, e);
		t.mod = mod;
		return t;
	}

    override ulong size(Loc loc)
	{
		if (!dim)
			return Type.size(loc);

		long sz = dim.toInteger();

		{	
			long n, n2;
			n = next.size();
			n2 = n * sz;
			if (n && (n2 / n) != sz)
				goto Loverflow;

			sz = n2;
		}
		return sz;

	Loverflow:
		error(loc, "index %jd overflow for static array", sz);
		return 1;
	}
	
    override uint alignsize()
	{
		return next.alignsize();
	}

    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (dim)
			//buf.printf("%ju", dim.toInteger());	///
			formattedWrite(buf,"%s", dim.toInteger());
		if (next)
			/* Note that static arrays are value types, so
			 * for a parameter, propagate the 0x100 to the next
			 * level, since for T[4][3], any const should apply to the T,
			 * not the [4].
			 */
			next.toDecoBuffer(buf,  (flag & 0x100) ? flag : mod);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		formattedWrite(buf,"[%s]", dim.toChars());
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStaticArrayDeclaration(this);
	}
}

class TypeSlice : TypeNext
{
    Expression lwr;
    Expression upr;

    this(Type next, Expression lwr, Expression upr)
	{
		super(Tslice, next);
		//printf("TypeSlice[%s .. %s]\n", lwr.toChars(), upr.toChars());
		this.lwr = lwr;
		this.upr = upr;
	}
	
    override Type syntaxCopy()
	{
		Type t = new TypeSlice(next.syntaxCopy(), lwr.syntaxCopy(), upr.syntaxCopy());
		t.mod = mod;
		return t;
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		assert(false);
	}
}

class TypeStruct : Type
{
    StructDeclaration sym;

    this(StructDeclaration sym)
	{
		super(Tstruct);
		this.sym = sym;
	}
    override ulong size(Loc loc)
	{
		return sym.size(loc);
	}

    override uint alignsize()
	{
		uint sz;

		sym.size(Loc(0));		// give error for forward references
		sz = sym.alignsize;
		if (sz > sym.structalign)
			sz = sym.structalign;
		return sz;
	}

    override string toChars()
	{
		//printf("sym.parent: %s, deco = %s\n", sym.parent.toChars(), deco);
		if (mod)
			return Type.toChars();
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
		{
			return ti.toChars();
		}
		return sym.toChars();
	}

    override Type syntaxCopy()
	{
		assert(false);
	}

    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		string name = sym.mangle();
		//printf("TypeStruct.toDecoBuffer('%s') = '%s'\n", toChars(), name);
		Type.toDecoBuffer(buf, flag);
		formattedWrite(buf,"%s", name);
	}

    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
			buf.put(ti.toChars());
		else
			buf.put(sym.toChars());
	}

    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */

    override bool isAssignable()
	{
		/* If any of the fields are const or invariant,
		 * then one cannot assign this struct.
		 */
		for (size_t i = 0; i < sym.fields.length; i++)
		{
			VarDeclaration v = cast(VarDeclaration)sym.fields[i];
			if (v.isConst() || v.isImmutable())
				return false;
		}
		return true;
	}

    override bool checkBoolean()
	{
		return false;
	}

    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStructDeclaration(this);
	}

    override Type toHeadMutable()
	{
		assert(false);
	}

}

class TypeTuple : Type
{
	Parameter[] arguments;	// types making up the tuple

	this(Parameter[] arguments)
	{
		super(Ttuple);
		//printf("TypeTuple(this = %p)\n", this);
		this.arguments = arguments;
		//printf("TypeTuple() %p, %s\n", this, toChars());
		debug {
			if (arguments)
			{
				foreach (arg; arguments)
				{
					assert(arg && arg.type);
				}
			}
		}
	}

	/****************
	 * Form TypeTuple from the types of the expressions.
	 * Assume exps[] is already tuple expanded.
	 */
	this(Expression[] exps)
	{
		super(Ttuple);
		Parameter[] arguments;
		if (exps)
		{
			arguments.reserve(exps.length);
			for (size_t i = 0; i < exps.length; i++)
			{   
            auto e = exps[i];
            if (e.type.ty == Ttuple)
               e.error("cannot form tuple of tuples");
            auto arg = new Parameter(STCundefined, e.type, null, null);
            arguments[i] = arg;
			}
		}
		this.arguments = arguments;
        //printf("TypeTuple() %p, %s\n", this, toChars());
	}

	override Type syntaxCopy()
	{
		auto args = Parameter.arraySyntaxCopy(arguments);
		auto t = new TypeTuple(args);
		t.mod = mod;
		return t;
	}

	override bool equals(Dobject o)
	{
		Type t;

		t = cast(Type)o;
		//printf("TypeTuple::equals(%s, %s)\n", toChars(), t-cast>toChars());
		if (this == t)
		{
			return 1;
		}
		if (t.ty == Ttuple)
		{	auto tt = cast(TypeTuple)t;

			if (arguments.length == tt.arguments.length)
			{
				for (size_t i = 0; i < tt.arguments.length; i++)
				{   auto arg1 = arguments[i];
					auto arg2 = tt.arguments[i];

					if (!arg1.type.equals(arg2.type))
						return 0;
				}
				return 1;
			}
		}
		return 0;
	}

	override Type reliesOnTident()
	{
		if (arguments)
		{
			foreach (arg; arguments)
			{
				auto t = arg.type.reliesOnTident();
				if (t)
					return t;
			}
		}
		return null;
	}

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		Parameter.argsToCBuffer(buf, hgs, arguments, 0);
	}

	override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		//printf("TypeTuple::toDecoBuffer() this = %p, %s\n", this, toChars());
		Type.toDecoBuffer(buf, flag);
		auto buf2 = appender!(char[])();
		Parameter.argsToDecoBuffer(buf2, arguments);
		//buf.printf("%d%.*s", len, len, cast(char *)buf2.extractData());
		formattedWrite(buf,"%s", buf2.data);
	}

	override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTupleDeclaration(this);
	}
}

class TypeTypedef : Type
{
    TypedefDeclaration sym;

    this(TypedefDeclaration sym)
	{
		super(Ttypedef);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		return sym.basetype.size(loc);
	}
	
    override uint alignsize()
	{
		assert(false);
	}
	
    override string toChars()
	{
		assert(false);
	}
	
    override void toDecoBuffer(ref Appender!(char[]) buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = sym.mangle();
		formattedWrite(buf,"%s", name);
	}
	
    override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		//printf("TypeTypedef.toCBuffer2() '%s'\n", sym.toChars());
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		
		buf.put(sym.toChars());
	}
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isintegral()
	{
		//printf("TypeTypedef::isintegral()\n");
		//printf("sym = '%s'\n", sym->toChars());
		//printf("basetype = '%s'\n", sym->basetype->toChars());
		return sym.basetype.isintegral();
	}
	
    override bool isfloating()
	{
		return sym.basetype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.basetype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.basetype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.basetype.iscomplex();
	}
	
    override bool isscalar()
	{
		return sym.basetype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.basetype.isunsigned();
	}
	
    override bool checkBoolean()
	{
		return sym.basetype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.basetype.isAssignable();
	}

    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTypedefDeclaration(this);
	}
}

class TypeTypeof : TypeQualified
{
    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(Ttypeof, loc);
		this.exp = exp;
	}
	
}
