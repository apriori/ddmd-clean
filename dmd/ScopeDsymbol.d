module dmd.ScopeDsymbol;

import dmd.Global;
import dmd.BaseClass;
import dmd.Dsymbol;
import dmd.Declaration;
import dmd.Expression;
import dmd.Identifier;
import dmd.FuncDeclaration;
import dmd.Scope;
import dmd.Statement;
import dmd.Token;
import dmd.Type;
import dmd.types.TypeClass;
import dmd.TypeInfoDeclaration;
import dmd.types.TypeStruct;
import dmd.types.TypeTuple;
import dmd.types.TypeEnum;
import dmd.TemplateParameter;
import dmd.VarDeclaration;
import dmd.HdrGenState;

import std.stdio : writef;
import std.array, std.format;

// I'm putting all extraneous data and functions up top for now
enum OFFSET_RUNTIME = 0x76543210; // ???

Tuple isTuple(Object o)
{
    //return dynamic_cast<Tuple *>(o);
    ///if (!o || o.dyncast() != DYNCAST_TUPLE)
	///	return null;
    return cast(Tuple)o;
}

/**************************************
 * Determine if TemplateDeclaration is variadic.
 */

TemplateTupleParameter isVariadic(TemplateParameter[] parameters)
{   
	size_t dim = parameters.length;
	TemplateTupleParameter tp = null;

	if (dim)
		tp = parameters[dim - 1].isTemplateTupleParameter();

	return tp;
}

void ObjectToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Object oarg)
{
	//printf("ObjectToCBuffer()\n");
	Type t = isType(oarg);
	Expression e = isExpression(oarg);
	Dsymbol s = isDsymbol(oarg);
	Tuple v = isTuple(oarg);
	if (t)
	{	
		//printf("\tt: %s ty = %d\n", t.toChars(), t.ty);
		t.toCBuffer(buf, null, hgs);
	}
	else if (e)
		e.toCBuffer(buf, hgs);
	else if (s)
	{
		string p = s.ident ? s.ident.toChars() : s.toChars();
		buf.put(p);
	}
	else if (v)
	{
		Object[] args = v.objects;
		for (size_t i = 0; i < args.length; i++)
		{
			if (i)
				buf.put(',');
			Object o = args[i];
			ObjectToCBuffer(buf, hgs, o);
		}
	}
	else if (!oarg)
	{
		buf.put("null");
	}
	else
	{
		debug writef("bad Object = %p\n", oarg);
		assert(0);
	}
}

class ScopeDsymbol : Dsymbol
{
    Dsymbol[] members;		// all Dsymbol's in this scope
    Dsymbol[string] symtab;	// members[] sorted into table

    ScopeDsymbol[] imports;		// imported ScopeDsymbol's
    PROT* prots;	// array of PROT, one for each import

    this()
	{
		// do nothing
	}
	
    this(Identifier id)
	{
		super(id);
	}
	
    Dsymbol syntaxCopy(Dsymbol s)
	{
	    //printf("ScopeDsymbol.syntaxCopy('%s')\n", toChars());

	    ScopeDsymbol sd;
	    if (s)
		sd = cast(ScopeDsymbol)s;
	    else
		sd = new ScopeDsymbol(ident);
	    sd.members = arraySyntaxCopy(members);
	    return sd;
	}
	
    bool isOverloadable()
    {
        return bool.init; 
    }
	
    void addLocalClass(ClassDeclaration[] aclasses) { assert(false); }
    bool isBaseOf(ClassDeclaration cd, int* poffset) { assert(false); }


    string mangle()
    {
        assert (false);
    }
    PROT prot()
    {
        assert (false);
    }
    bool isDeprecated()		// is aggregate deprecated?
    {
        assert (false);
    }
    Type getType()
    {
        assert (false);
    }

    int isforwardRef()
	{
		return (members is null);
	}
	
    void defineRef(Dsymbol s)
	{
		ScopeDsymbol ss = s.isScopeDsymbol();
		members = ss.members;
		ss.members = null;
	}

    static void multiplyDefined(Loc loc, Dsymbol s1, Dsymbol s2)
	{
		if (loc.filename)
		{
			.error(loc, "%s at %s conflicts with %s at %s",
			s1.toPrettyChars(),
			s1.locToChars(),
			s2.toPrettyChars(),
			s2.locToChars());
		}
		else
		{
			s1.error(loc, "conflicts with %s %s at %s", s2.kind(), s2.toPrettyChars(), s2.locToChars());
		}
	}

    Dsymbol nameCollision(Dsymbol s)
	{
		assert(false);
	}
	
    string kind()
	{
		assert(false);
	}

	/*******************************************
	 * Look for member of the form:
	 *	const(MemberInfo)[] getMembers(string);
	 * Returns NULL if not found
	 */
    FuncDeclaration findGetMembers() { assert(false,"zd cut"); }

    Dsymbol symtabInsert(Dsymbol s)
    {
      if ( s.ident.string_ in symtab ) return null;
      symtab[s.ident.string_] = s;
      return s; 
    }

    void emitMemberComments(Scope sc)
	{
		assert(false);
	}


   // static Dsymbol getNth(Dsymbol[] members, size_t nth, size_t* pn = null) { assert(false); }
    override ScopeDsymbol isScopeDsymbol() { return this; }
}

class AggregateDeclaration : ScopeDsymbol
{
    Type type;
    StorageClass storage_class;
    PROT protection = PROTpublic;
    Type handle;		// 'this' type
    uint structsize;	// size of struct
    uint alignsize;		// size of struct for alignment purposes
    uint structalign;	// struct member alignment in effect
    int hasUnions;		// set if aggregate has overlapping fields
    VarDeclaration[] fields;	// VarDeclaration fields
    uint sizeok;		// set when structsize contains valid data
				// 0: no size
				// 1: size is correct
				// 2: cannot determine size; fwd referenced
    bool isdeprecated;		// true if deprecated

    bool isnested;		// true if is nested
    VarDeclaration vthis;	// 'this' parameter if this aggregate is nested

    // Special member functions
    InvariantDeclaration inv;		// invariant
    NewDeclaration aggNew;		// allocator
    DeleteDeclaration aggDelete;	// deallocator

    //CtorDeclaration *ctor;
    Dsymbol ctor;			// CtorDeclaration or TemplateDeclaration
    CtorDeclaration defaultCtor;	// default constructor
    Dsymbol aliasthis;			// forward unresolved lookups to aliasthis

    FuncDeclaration[] dtors;	// Array of destructors
    FuncDeclaration dtor;	// aggregate destructor

    this(Loc loc, Identifier id)
	{
		super(id);
		this.loc = loc;
	}


    override uint size(Loc loc)
	{
		//printf("AggregateDeclaration.size() = %d\n", structsize);
		if (!members)
			error(loc, "unknown size");

		if (sizeok != 1)
		{
			error(loc, "no size yet for forward reference");
			//*(char*)0=0;
		}

		return structsize;
	}

    override Type getType()
	{
		return type;
	}


    override bool isDeprecated()		// is aggregate deprecated?
	{
		return isdeprecated;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	/*******************************
	 * Do access check for member of this class, this class being the
	 * type of the 'this' pointer used to access smember.
	 */

    override PROT prot()
	{
		assert(false);
	}

    override AggregateDeclaration isAggregateDeclaration() { return this; }
}

class AnonymousAggregateDeclaration : AggregateDeclaration
{
    this()
    {
		super(Loc(0), null);
    }

    AnonymousAggregateDeclaration isAnonymousAggregateDeclaration() { return this; }
}

class ArrayScopeSymbol : ScopeDsymbol
{
    Expression exp;	// IndexExp or SliceExp
    TypeTuple type;	// for tuple[length]
    TupleDeclaration td;	// for tuples of objects
    Scope sc;

    this(Scope sc, Expression e)
	{
		super();
		assert(e.op == TOKindex || e.op == TOKslice);
		this.exp = e;
		this.sc = sc;
	}
	
    this(Scope sc, TypeTuple t)
	{
		exp = null;
		type = t;
		td = null;
		this.sc = sc;
	}
	
    this(Scope sc, TupleDeclaration s)
	{

		exp = null;
		type = null;
		td = s;
		this.sc = sc;
	}
	

    override ArrayScopeSymbol isArrayScopeSymbol() { return this; }
}

class ClassDeclaration : AggregateDeclaration
{
    ClassDeclaration baseClass;	// null only if this is Object
    FuncDeclaration staticCtor;
    FuncDeclaration staticDtor;
    FuncDeclaration[] vtbl;   //  FuncDeclaration's making up the vtbl[]
    FuncDeclaration[] vtblFinal; 	// More FuncDeclaration's that aren't in vtbl[]

    BaseClass[] baseclasses;		//  BaseClass's; first is super,
					// rest are Interface's

    int interfaces_dim;
    BaseClass* interfaces;		// interfaces[interfaces_dim] for this class
					// (does not include baseClass)

    BaseClass[] vtblInterfaces;	// array of base interfaces that have
					// their own vtbl[]

    TypeInfoClassDeclaration vclassinfo;	// the ClassInfo object for this ClassDeclaration
    bool com;				// true if this is a COM class (meaning
					// it derives from IUnknown)
    bool isauto;				// true if this is an auto class
    bool isabstract;			// true if abstract class
    int inuse;				// to prevent recursive attempts

    this(Loc loc, Identifier id, BaseClass[] baseclasses)
	{

		super(loc, id);

		enum msg = "only object.d can define this reserved class name";

		if (baseclasses) {
			this.baseclasses = baseclasses;
		}

		//printf("ClassDeclaration(%s), dim = %d\n", id.toChars(), this.baseclasses.length);

		// For forward references
		type = new TypeClass(this);

		if (id)
		{
			// Look for special class names

			if (id is Id.__sizeof || id is Id.alignof_ || id is Id.mangleof_)
				error("illegal class name");

			// BUG: What if this is the wrong TypeInfo, i.e. it is nested?
			if (id.toChars()[0] == 'T')
			{
				if (id is Id.TypeInfo)
				{
					if (global.typeinfo) {
						global.typeinfo.error("%s", msg);
					}

					global.typeinfo = this;
				}

				if (id is Id.TypeInfo_Class)
				{
					if (global.typeinfoclass)
						global.typeinfoclass.error("%s", msg);
					global.typeinfoclass = this;
				}

				if (id is Id.TypeInfo_Interface)
				{
					if (global.typeinfointerface)
						global.typeinfointerface.error("%s", msg);
					global.typeinfointerface = this;
				}

				if (id is Id.TypeInfo_Struct)
				{
					if (global.typeinfostruct)
						global.typeinfostruct.error("%s", msg);
					global.typeinfostruct = this;
				}

				if (id is Id.TypeInfo_Typedef)
				{
					if (global.typeinfotypedef)
						global.typeinfotypedef.error("%s", msg);
					global.typeinfotypedef = this;
				}

				if (id is Id.TypeInfo_Pointer)
				{
					if (global.typeinfopointer)
						global.typeinfopointer.error("%s", msg);
					global.typeinfopointer = this;
				}

				if (id is Id.TypeInfo_Array)
				{
					if (global.typeinfoarray)
						global.typeinfoarray.error("%s", msg);
					global.typeinfoarray = this;
				}

				if (id is Id.TypeInfo_StaticArray)
				{	//if (global.typeinfostaticarray)
					//global.typeinfostaticarray.error("%s", msg);
					global.typeinfostaticarray = this;
				}

				if (id is Id.TypeInfo_AssociativeArray)
				{
					if (global.typeinfoassociativearray)
						global.typeinfoassociativearray.error("%s", msg);
					global.typeinfoassociativearray = this;
				}

				if (id is Id.TypeInfo_Enum)
				{
					if (global.typeinfoenum)
						global.typeinfoenum.error("%s", msg);
					global.typeinfoenum = this;
				}

				if (id is Id.TypeInfo_Function)
				{
					if (global.typeinfofunction)
						global.typeinfofunction.error("%s", msg);
					global.typeinfofunction = this;
				}

				if (id is Id.TypeInfo_Delegate)
				{
					if (global.typeinfodelegate)
						global.typeinfodelegate.error("%s", msg);
					global.typeinfodelegate = this;
				}

				if (id is Id.TypeInfo_Tuple)
				{
					if (global.typeinfotypelist)
						global.typeinfotypelist.error("%s", msg);
					global.typeinfotypelist = this;
				}

				if (id is Id.TypeInfo_Const)
				{
					if (global.typeinfoconst)
						global.typeinfoconst.error("%s", msg);
					global.typeinfoconst = this;
				}

				if (id is Id.TypeInfo_Invariant)
				{
					if (global.typeinfoinvariant)
						global.typeinfoinvariant.error("%s", msg);
					global.typeinfoinvariant = this;
				}

				if (id is Id.TypeInfo_Shared)
				{
					if (global.typeinfoshared)
						global.typeinfoshared.error("%s", msg);
					global.typeinfoshared = this;
				}

	            if (id == Id.TypeInfo_Wild)
	            {
                    if (global.typeinfowild)
		                global.typeinfowild.error("%s", msg);
		            global.typeinfowild = this;
	            }
			}

			if (id is Id.Object_)
			{
				if (global.object)
					global.object.error("%s", msg);
				global.object = this;
			}

//			if (id is Id.ClassInfo)
			if (id is Id.TypeInfo_Class)
			{
				if (global.classinfo)
					global.classinfo.error("%s", msg);
				global.classinfo = this;
			}

			if (id is Id.ModuleInfo)
			{
				if (global.moduleinfo)
					global.moduleinfo.error("%s", msg);
				global.moduleinfo = this;
			}
		}

		com = 0;
		isauto = false;
		isabstract = false;
		inuse = 0;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		ClassDeclaration cd;

		//printf("ClassDeclaration.syntaxCopy('%s')\n", toChars());
		if (s)
			cd = cast(ClassDeclaration)s;
		else
		cd = new ClassDeclaration(loc, ident, null);

		cd.storage_class |= storage_class;

		cd.baseclasses.reserve(this.baseclasses.length);
		for (size_t i = 0; i < cd.baseclasses.length; i++)
		{
			auto b = this.baseclasses[i];
			auto b2 = new BaseClass(b.type.syntaxCopy(), b.protection);
			cd.baseclasses[i] = b2;
		}

		ScopeDsymbol.syntaxCopy(cd);
		return cd;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (!isAnonymous())
		{
			formattedWrite(buf, "%s ", kind());
			buf.put(toChars());
			if (baseclasses.length)
				buf.put(" : ");
		}
		foreach (size_t i, BaseClass b; baseclasses)
		{
			if (i)
				buf.put(',');
			//buf.put(b.base.ident.toChars());
			b.type.toCBuffer(buf, null, hgs);
		}
		if (members)
		{
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
			foreach (s; members)
			{
				buf.put("    ");
				s.toCBuffer(buf, hgs);
			}
			buf.put("}");
		}
		else
			buf.put(';');
		buf.put('\n');
	}

	/*********************************************
	 * Determine if 'this' is a base class of cd.
	 * This is used to detect circular inheritance only.
	 */
    int isBaseOf2(ClassDeclaration cd)
	{
		if (!cd)
			return 0;
		//printf("ClassDeclaration::isBaseOf2(this = '%s', cd = '%s')\n", toChars(), cd.toChars());
		foreach (b; cd.baseclasses)
		{
			if (b.base is this || isBaseOf2(b.base))
				return 1;
		}
		return 0;
	}

	/*******************************************
	 * Determine if 'this' is a base class of cd.
	 */
///    #define OFFSET_RUNTIME 0x76543210
    bool isBaseOf(ClassDeclaration cd, ref int poffset)
	{
		if (!cd)
			return 0;
		//printf("ClassDeclaration::isBaseOf2(this = '%s', cd = '%s')\n", toChars(), cd.toChars());
		foreach (b; cd.baseclasses)
		{
			if (b.base == this || isBaseOf2(b.base))
				return 1;
		}

		return 0;
	}

    override string kind()
	{
		return "class";
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}


    override void addLocalClass(ClassDeclaration[] aclasses)
	{
		aclasses ~= (this);
	}

    void toDebug()
	{
		assert(false);
	}

    ///ClassDeclaration isClassDeclaration() { return cast(ClassDeclaration)this; }	/// huh?
    override ClassDeclaration isClassDeclaration() { return this; }
}

class EnumDeclaration : ScopeDsymbol
{
   /* enum ident : memtype { ... }
     */
    Type type;			// the TypeEnum
    Type memtype;		// type of the members
    
    Expression maxval;
    Expression minval;
    Expression defaultval;	// default initializer
	bool isdeprecated = false;
	bool isdone = false;	// 0: not done
							// 1: semantic() successfully completed
    
    this(Loc loc, Identifier id, Type memtype)
	{
		super(id);
		this.loc = loc;
		type = new TypeEnum(this);
		this.memtype = memtype;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    Type t = null;
	    if (memtype)
		t = memtype.syntaxCopy();

	    EnumDeclaration ed;
	    if (s)
	    {	ed = cast(EnumDeclaration)s;
		ed.memtype = t;
	    }
	    else
		ed = new EnumDeclaration(loc, ident, t);
	    ScopeDsymbol.syntaxCopy(ed);
	    return ed;
	}
	
	
    override bool oneMember(Dsymbol ps)
	{
    		if (isAnonymous())
			return Dsymbol.oneMembers(members, ps);
	    	return Dsymbol.oneMember(ps);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put("enum ");
	    if (ident)
	    {	buf.put(ident.toChars());
		buf.put(' ');
	    }
	    if (memtype)
	    {
		buf.put(": ");
		memtype.toCBuffer(buf, null, hgs);
	    }
	    if (!members)
	    {
		buf.put(';');
		buf.put('\n');
		return;
	    }
	    buf.put('\n');
	    buf.put('{');
	    buf.put('\n');
	    foreach(Dsymbol s; members)
	    {
		EnumMember em = s.isEnumMember();
		if (!em)
		    continue;
		//buf.put("    ");
		em.toCBuffer(buf, hgs);
		buf.put(',');
		buf.put('\n');
	    }
	    buf.put('}');
	    buf.put('\n');
	}
	
    override Type getType()
	{
		return type;
	}
	
    override string kind()
	{
		return "enum";
	}
	
    override bool isDeprecated()			// is Dsymbol deprecated?
	{
		return isdeprecated;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

    override EnumDeclaration isEnumDeclaration() { return this; }

	
    void toDebug()
	{
		assert(false);
	}
	
    //Symbol* sinit;

}

class InterfaceDeclaration : ClassDeclaration
{
    bool cpp;				// true if this is a C++ interface

    this(Loc loc, Identifier id, BaseClass[] baseclasses)
	{
		super(loc, id, baseclasses);

		if (id is Id.IUnknown)	// IUnknown is the root of all COM interfaces
		{
			com = true;
			cpp = true;		// IUnknown is also a C++ interface
		}
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		InterfaceDeclaration id;

		if (s)
			id = cast(InterfaceDeclaration)s;
		else
			id = new InterfaceDeclaration(loc, ident, null);

		ClassDeclaration.syntaxCopy(id);
		return id;
	}

    override string kind()
	{
		assert(false);
	}

    override InterfaceDeclaration isInterfaceDeclaration() { return this; }
}

class StructDeclaration : AggregateDeclaration
{
    bool zeroInit;		// true if initialize with 0 fill

    int hasIdentityAssign;	// !=0 if has identity opAssign
    FuncDeclaration cpctor;	// generated copy-constructor, if any
    FuncDeclaration eq;	// bool opEquals(ref const T), if any

    FuncDeclaration[] postblits;	// Array of postblit functions
    FuncDeclaration postblit;	// aggregate postblit

    this(Loc loc, Identifier id)
	{
		super(loc, id);

		// For forward references
		type = new TypeStruct(this);

	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StructDeclaration sd;

		if (s)
			sd = cast(StructDeclaration)s;
		else
			sd = new StructDeclaration(loc, ident);
		ScopeDsymbol.syntaxCopy(sd);
		return sd;
	}



    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

    override string mangle()
	{
		//printf("StructDeclaration.mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}

    override string kind()
	{
		assert(false);
	}

version(DMDV1)
    Expression cloneMembers()
	{
		assert(false);
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}





    override StructDeclaration isStructDeclaration() { return this; }
}

class TemplateDeclaration : ScopeDsymbol
{
	TemplateParameter[] parameters;	// array of TemplateParameter's

	TemplateParameter[] origParameters;	// originals for Ddoc
	Expression constraint;
	TemplateInstance[] instances;			// array of TemplateInstance's

	TemplateDeclaration overnext;	// next overloaded TemplateDeclaration
	TemplateDeclaration overroot;	// first in overnext list

	int semanticRun;			// 1 semantic() run

	Dsymbol onemember;		// if !=NULL then one member of this template

	int literal;		// this template declaration is a literal

	this(Loc loc, Identifier id, TemplateParameter[] parameters, Expression constraint, Dsymbol[] decldefs)
	{	
		super(id);
		
	version (LOG) {
		printf("TemplateDeclaration(this = %p, id = '%s')\n", this, id.toChars());
	}
	static if (false) {
		if (parameters)
			for (int i = 0; i < parameters.length; i++)
			{   
				TemplateParameter tp = cast(TemplateParameter)parameters.data[i];
				//printf("\tparameter[%d] = %p\n", i, tp);
				TemplateTypeParameter ttp = tp.isTemplateTypeParameter();

				if (ttp)
				{
					printf("\tparameter[%d] = %s : %s\n", i, tp.ident.toChars(), ttp.specType ? ttp.specType.toChars() : "");
				}
			}
	}
		
		this.loc = loc;
		this.parameters = parameters;
		this.origParameters = parameters;
		this.constraint = constraint;
		this.members = decldefs;
		
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		//printf("TemplateDeclaration.syntaxCopy()\n");
		TemplateDeclaration td;
		TemplateParameter[] p;
		Dsymbol[] d;

		p = null;
		if (parameters)
		{
			p.length = parameters.length;
			for (int i = 0; i < p.length; i++)
			{   
				auto tp = parameters[i];
				p[i] = tp.syntaxCopy();
			}
		}
		
		Expression e = null;
		if (constraint)
			e = constraint.syntaxCopy();
		d = Dsymbol.arraySyntaxCopy(members);
		td = new TemplateDeclaration(loc, ident, p, e, d);
		return td;
	}


	/**********************************
	 * Overload existing TemplateDeclaration 'this' with the new one 's'.
	 * Return !=0 if successful; i.e. no conflict.
	 */

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(kind());
		buf.put(' ');
		buf.put(ident.toChars());
		buf.put('(');
		foreach (size_t i, TemplateParameter tp; parameters)
		{
			if (hgs.ddoc)
				tp = origParameters[i];
			if (i)
				buf.put(',');
			tp.toCBuffer(buf, hgs);
		}
		buf.put(')');

		if (constraint)
		{   buf.put(" if (");
			constraint.toCBuffer(buf, hgs);
			buf.put(')');
		}

		if (hgs.hdrgen)
		{
			hgs.tpltMember++;
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
			foreach (Dsymbol s; members)
				s.toCBuffer(buf, hgs);

			buf.put('}');
			buf.put('\n');
			hgs.tpltMember--;
		}
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

	override string kind()
	{
		return (onemember && onemember.isAggregateDeclaration())
			? onemember.kind()
			: "template";
	}

	override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		/// memset(&hgs, 0, hgs.sizeof);
		buf.put(ident.toChars());
		buf.put('(');
		foreach (size_t i, TemplateParameter tp; parameters)
		{
			if (i)
				buf.put(',');
			tp.toCBuffer(buf, hgs);
		}
		buf.put(')');
		if (constraint)
		{
			buf.put(" if (");
			constraint.toCBuffer(buf, hgs);
			buf.put(')');
		}
		return buf.data.idup;
	}

	override void emitComment(Scope sc)
	{
		assert(false);
	}
	
//	void toDocBuffer(ref Appender!(char[]) *buf);


	/*************************************************
	 * Match function arguments against a specific template function.
	 * Input:
	 *	loc		instantiation location
	 *	targsi		Expression/Type initial list of template arguments
	 *	ethis		'this' argument if !null
	 *	fargs		arguments to function
	 * Output:
	 *	dedargs		Expression/Type deduced template arguments
	 * Returns:
	 *	match level
	 */
	
	/*************************************************
	 * Given function arguments, figure out which template function
	 * to expand, and return that function.
	 * If no match, give error message and return null.
	 * Input:
	 *	sc		instantiation scope
	 *	loc		instantiation location
	 *	targsi		initial list of template arguments
	 *	ethis		if !null, the 'this' pointer argument
	 *	fargs		arguments to function
	 *	flags		1: do not issue error message on no match, just return null
	 */
	
	/**************************************************
	 * Declare template parameter tp with value o, and install it in the scope sc.
	 */
	
	override TemplateDeclaration isTemplateDeclaration() { return this; }

	TemplateTupleParameter isVariadic()
	{
		return .isVariadic(parameters);
	}
	
	/***********************************
	 * We can overload templates.
	 */
	override bool isOverloadable()
	{
		return true;
	}
    
    /****************************
     * Declare all the function parameters as variables
     * and add them to the scope
     */
}

class TemplateInstance : ScopeDsymbol
{
    /* Given:
     *	foo!(args) =>
     *	    name = foo
     *	    tiargs = args
     */
    Identifier name;
    //Identifier[] idents;
    Object[] tiargs;		// Array of Types/Expression[] of template
				// instance arguments [int*, char, 10*10]

    Object[] tdtypes;		// Array of Types/Expression[] corresponding
				// to TemplateDeclaration.parameters
				// [int, char, 100]

    TemplateDeclaration tempdecl;	// referenced by foo.bar.abc
    TemplateInstance inst;		// refer to existing instance
    TemplateInstance tinst;		// enclosing template instance
    ScopeDsymbol argsym;		// argument symbol table
    AliasDeclaration aliasdecl;	// !=null if instance is an alias for its
					// sole member
    WithScopeSymbol withsym;		// if a member of a with statement
    int semanticRun;	// has semantic() been done?
    int semantictiargsdone;	// has semanticTiargs() been done?
    int nest;		// for recursion detection
    int havetempdecl;	// 1 if used second constructor
    Dsymbol isnested;	// if referencing local symbols, this is the context
    int errors;		// 1 if compiled with errors

    this(Loc loc, Identifier ident)
	{
		super(null);
		
	version (LOG) {
		printf("TemplateInstance(this = %p, ident = '%s')\n", this, ident ? ident.toChars() : "null");
	}
		this.loc = loc;
		this.name = ident;
	}

	/*****************
	 * This constructor is only called when we figured out which function
	 * template to instantiate.
	 */
    this(Loc loc, TemplateDeclaration td, Object[] tiargs)
	{
		super(null);
		
	version (LOG) {
		printf("TemplateInstance(this = %p, tempdecl = '%s')\n", this, td.toChars());
	}
		this.loc = loc;
		this.name = td.ident;
		this.tiargs = tiargs;
		this.tempdecl = td;
		this.semantictiargsdone = 1;
		this.havetempdecl = 1;

		assert(cast(size_t)cast(void*)tempdecl.scope_ > 0x10000);
	}

    static Object[] arraySyntaxCopy(Object[] objs)
	{
	    Object[] a = null;
	    if (objs)
	    {	
		a.reserve(objs.length);
		for (size_t i = 0; i < objs.length; i++)
		{
		    a[i] = objectSyntaxCopy(objs[i]);
		}
	    }
	    return a;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    TemplateInstance ti;

	    if (s)
		ti = cast(TemplateInstance)s;
	    else
		ti = new TemplateInstance(loc, name);

	    ti.tiargs = arraySyntaxCopy(tiargs);

	    ScopeDsymbol.syntaxCopy(ti);
	    return ti;
	}





	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;

		Identifier id = name;
		buf.put(id.toChars());
		buf.put("!(");
		if (nest)
			buf.put("...");
		else
		{
			nest++;
			Object[] args = tiargs;
			for (i = 0; i < args.length; i++)
			{
				if (i)
					buf.put(',');
				Object oarg = args[i];
				ObjectToCBuffer(buf, hgs, oarg);
			}
			nest--;
		}
		buf.put(')');
	}
	
	
    override string kind()
	{
	    return "template instance";
	}
	
    
    
    override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		toCBuffer(buf, hgs);
		return buf.data.idup;
	}

    override TemplateInstance isTemplateInstance() { return this; }

    override AliasDeclaration isAliasDeclaration()
	{
		assert(false);
	}
}

class TemplateMixin : TemplateInstance
{
	Identifier[] idents;
	Type tqual;

	this(Loc loc, Identifier ident, Type tqual, Identifier[] idents, Object[] tiargs)
	{
		super( loc, idents[$] );
		//printf("TemplateMixin(ident = '%s')\n", ident ? ident.toChars() : "");
		this.ident = ident;
		this.tqual = tqual;
		this.idents = idents;
		this.tiargs = tiargs;
		//this.semantictiargsdone = 1;
		//this.havetempdecl = 1;
	}






	override string kind()
	{
		return "mixin";
	}

	override bool oneMember(Dsymbol* ps)
	{
		return Dsymbol.oneMember(ps);
	}


	override string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;

		TemplateInstance.toCBuffer(buf, hgs);
		string s = buf.data.idup;
		buf.clear();
		return s;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin ");

		for (int i = 0; i < idents.length; i++)
		{   Identifier id = idents[i];

			if (i)
				buf.put('.');
			buf.put(id.toChars());
		}
		buf.put("!(");
		if (tiargs)
		{
			for (int i = 0; i < tiargs.length; i++)
			{   if (i)
				buf.put(',');
				Object oarg = tiargs[i];
				Type t = isType(oarg);
				Expression e = isExpression(oarg);
				Dsymbol s = isDsymbol(oarg);
				if (t)
					t.toCBuffer(buf, null, hgs);
				else if (e)
					e.toCBuffer(buf, hgs);
				else if (s)
				{
					string p = s.ident ? s.ident.toChars() : s.toChars();
					buf.put(p);
				}
				else if (!oarg)
				{
					buf.put("null");
				}
				else
				{
					assert(0);
				}
			}
		}
		buf.put(')');
		if (ident)
		{
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}


	override TemplateMixin isTemplateMixin() { return this; }
}

class UnionDeclaration : StructDeclaration
{
	this(Loc loc, Identifier id)
	{
		super(loc, id);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		UnionDeclaration ud;

		if (s)
			ud = cast(UnionDeclaration)s;
		else
			ud = new UnionDeclaration(loc, ident);
		StructDeclaration.syntaxCopy(ud);
		return ud;
	}

	override string kind()
	{
		return "union";
	}

	override UnionDeclaration isUnionDeclaration() { return this; }
}

class WithScopeSymbol : ScopeDsymbol
{
    WithStatement withstate;

    this(WithStatement withstate)
	{
		this.withstate = withstate;
	}

    override WithScopeSymbol isWithScopeSymbol() { return this; }
}
