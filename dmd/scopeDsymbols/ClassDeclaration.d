module dmd.scopeDsymbols.ClassDeclaration;

import dmd.Global;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.scopeDsymbols.InterfaceDeclaration;
import dmd.varDeclarations.ThisDeclaration;
import dmd.statements.CompoundStatement;
import dmd.declarations.DeleteDeclaration;
import dmd.declarations.NewDeclaration;
import dmd.declarations.CtorDeclaration;
import dmd.types.TypeIdentifier;
import dmd.Parameter;
import dmd.types.TypeTuple;
import dmd.declarations.FuncDeclaration;
import dmd.types.TypeClass;
import dmd.Module;
import dmd.Type;
import dmd.dsymbols.OverloadSet;
import dmd.BaseClass;
import dmd.varDeclarations.ClassInfoDeclaration;
import dmd.varDeclarations.TypeInfoClassDeclaration;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.types.TypeFunction;
import dmd.HdrGenState;
import std.array;
import dmd.VarDeclaration;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.types.TypeSArray;
import dmd.ScopeDsymbol;

import dmd.DDMDExtensions;

import std.string;
import std.format;

enum CLASSINFO_SIZE = (0x3C+12+4);	// value of ClassInfo.size

enum OFFSET_RUNTIME = 0x76543210;

struct FuncDeclarationFinder
{
	bool visit(FuncDeclaration fd2)
	{
		//printf("param = %p, fd = %p %s\n", param, fd, fd.toChars());
		return fd is fd2;
	}

	FuncDeclaration fd;
}

class ClassDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

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


    bool isFuncHidden(FuncDeclaration fd) { assert(false,"zd cut"); }
    
    FuncDeclaration findFunc(Identifier ident, TypeFunction tf) { assert(false,"zd cut"); }






    override string kind()
	{
		return "class";
	}

    override string mangle() { assert(false,"zd cut"); }

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

	/******************************************
	 * Get offset of base class's vtbl[] initializer from start of csym.
	 * Returns ~0 if not this csym.
	 */
    uint baseVtblOffset(BaseClass bc) { assert(false,"zd cut"); }

	/*************************************
	 * Create the "ClassInfo" symbol
	 */

	/*************************************
	 * This is accessible via the ClassData, but since it is frequently
	 * needed directly (like for rtti comparisons), make it directly accessible.
	 */
    //Symbol* toVtblSymbol() { assert(false,"zd cut"); }

	// Generate the data for the static initializer.


    ///ClassDeclaration isClassDeclaration() { return cast(ClassDeclaration)this; }	/// huh?
    override ClassDeclaration isClassDeclaration() { return this; }
}
