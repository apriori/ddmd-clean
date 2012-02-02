module dmd.templateParameters.TemplateAliasParameter;

import dmd.Global;
import dmd.TemplateParameter;
import dmd.Identifier;
import dmd.Type;
import dmd.types.TypeIdentifier;
import dmd.Scope;
import dmd.Declaration;
import dmd.HdrGenState;
import std.array;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.declarations.AliasDeclaration;
import dmd.VarDeclaration;
import dmd.scopeDsymbols.TemplateDeclaration;

import dmd.DDMDExtensions;

class TemplateAliasParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

	/* Syntax:
	 *	specType ident : specAlias = defaultAlias
	 */

	Type specType;
	Object specAlias;
	Object defaultAlias;

	this(Loc loc, Identifier ident, Type specType, Object specAlias, Object defaultAlias)
	{
		super(loc, ident);

		this.specType = specType;
		this.specAlias = specAlias;
		this.defaultAlias = defaultAlias;
	}

	override TemplateAliasParameter isTemplateAliasParameter()
	{
		return this;
	}

	override TemplateParameter syntaxCopy()
	{
		TemplateAliasParameter tp = new TemplateAliasParameter(loc, ident, specType, specAlias, defaultAlias);
		if (tp.specType)
			tp.specType = specType.syntaxCopy();
		tp.specAlias = objectSyntaxCopy(specAlias);
		tp.defaultAlias = objectSyntaxCopy(defaultAlias);
		return tp;
	}

	override void declareParameter(Scope sc)
	{
		TypeIdentifier ti = new TypeIdentifier(loc, ident);
		sparam = new AliasDeclaration(loc, ident, ti);
		if (!sc.insert(sparam))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
	}


   override void print(Object oarg, Object oded)
   {
       assert(false);
   }


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("alias ");
		if (specType)
		{	HdrGenState hg;
			specType.toCBuffer(buf, ident, hg);
		}
		else
			buf.put(ident.toChars());
		if (specAlias)
		{
			buf.put(" : ");
			ObjectToCBuffer(buf, hgs, specAlias);
		}
		if (defaultAlias)
		{
			buf.put(" = ");
			ObjectToCBuffer(buf, hgs, defaultAlias);
		}
	}

	override Object specialization()
	{
		return specAlias;
	}

   override Object defaultArg(Loc loc, Scope sc)
   {
       assert(false);
   }

   
    /* Match actual argument against parameter.
     */
    override MATCH matchArg(Scope sc, Object[] tiargs, int i, TemplateParameter[] parameters, Object[] dedtypes, Declaration* psparam, int flags = 0)
    {
        assert(false);
    }

	override bool overloadMatch(TemplateParameter tp)
	{
		TemplateAliasParameter tap = tp.isTemplateAliasParameter();

		if (tap)
		{
			if (specAlias != tap.specAlias)
				goto Lnomatch;

			return true;			// match
		}

Lnomatch:
		return false;
	}


	override Object dummyArg()
	{
		if (!specAlias)
		{
			return global.sdummy;
		}
		return specAlias;
	}
}
