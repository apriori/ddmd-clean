module dmd.scopeDsymbols.TemplateDeclaration;

import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.Dsymbol;
import dmd.templateParameters.TemplateThisParameter;
import dmd.Identifier;
import dmd.types.TypeArray;
import dmd.Expression;
import dmd.Scope;
import dmd.types.TypeIdentifier;
import dmd.types.TypeDelegate;
import dmd.expressions.IntegerExp;
import dmd.types.TypeSArray;
import dmd.expressions.StringExp;
import dmd.Token;
import dmd.Parameter;
import dmd.declarations.CtorDeclaration;
import dmd.types.TypeFunction;
import dmd.Declaration;
import std.array;
import dmd.HdrGenState;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.declarations.FuncDeclaration;
import dmd.templateParameters.TemplateTupleParameter;
import dmd.Type;
import dmd.declarations.TupleDeclaration;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.templateParameters.TemplateValueParameter;
import dmd.declarations.AliasDeclaration;
import dmd.VarDeclaration;
import dmd.TemplateParameter;
import dmd.templateParameters.TemplateTypeParameter;


import std.stdio;

import dmd.DDMDExtensions;

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

class TemplateDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

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
static if (false) // Should handle template functions
{
		if (onemember && onemember.isFuncDeclaration())
			buf.put("foo ");
}
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
version(DMDV2)
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
