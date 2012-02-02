module dmd.scopeDsymbols.TemplateInstance;

import dmd.Global;
import std.format;

import dmd.ScopeDsymbol;
import dmd.expressions.IntegerExp;
import dmd.Identifier;
import dmd.declarations.TupleDeclaration;
import dmd.TemplateParameter;
import dmd.declarations.AliasDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.TupleExp;
import dmd.scopeDsymbols.WithScopeSymbol;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Type;
import dmd.Expression;
import dmd.Token;
import dmd.types.TypeTuple;
import dmd.Parameter;
import dmd.initializers.ExpInitializer;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.VarDeclaration;
import dmd.expressions.VarExp;
import dmd.expressions.FuncExp;
import dmd.Declaration;
import dmd.types.TypeFunction;
import dmd.templateParameters.TemplateTupleParameter;
import dmd.declarations.FuncDeclaration;
import dmd.dsymbols.OverloadSet;


import dmd.DDMDExtensions;

Tuple isTuple(Object o)
{
    //return dynamic_cast<Tuple *>(o);
    ///if (!o || o.dyncast() != DYNCAST_TUPLE)
	///	return null;
    return cast(Tuple)o;
}

class TemplateInstance : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

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
version (IN_GCC) {
    /* On some targets, it is necessary to know whether a symbol
       will be emitted in the output or not before the symbol
       is used.  This can be different from getModule(). */
    Module objFileModule;
}

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
