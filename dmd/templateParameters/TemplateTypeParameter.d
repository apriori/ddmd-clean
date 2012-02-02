module dmd.templateParameters.TemplateTypeParameter;

import dmd.Global;
import dmd.TemplateParameter;
import dmd.Type;
import dmd.Identifier;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Declaration;
import dmd.types.TypeIdentifier;
import dmd.declarations.AliasDeclaration;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class TemplateTypeParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* Syntax:
     *	ident : specType = defaultType
     */
    Type specType;	// type parameter: if !=null, this is the type specialization
    Type defaultType;

    this(Loc loc, Identifier ident, Type specType, Type defaultType)
	{
		super(loc, ident);
		this.ident = ident;
		this.specType = specType;
		this.defaultType = defaultType;
	}

    override TemplateTypeParameter isTemplateTypeParameter()
	{
		return this;
	}
	
    override TemplateParameter syntaxCopy()
    {
        assert (false);
    }
	
    override void declareParameter(Scope sc)
	{
		//printf("TemplateTypeParameter.declareParameter('%s')\n", ident.toChars());
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
		buf.put(ident.toChars());
		if (specType)
		{
			buf.put(" : ");
			specType.toCBuffer(buf, null, hgs);
		}
		if (defaultType)
		{
			buf.put(" = ");
			defaultType.toCBuffer(buf, null, hgs);
		}
	}

    override Object specialization()
	{
		return specType;
	}


    override bool overloadMatch(TemplateParameter)
	{
		assert(false);
	}

	/*******************************************
	 * Match to a particular TemplateParameter.
	 * Input:
	 *	i		i'th argument
	 *	tiargs[]	actual arguments to template instance
	 *	parameters[]	template parameters
	 *	dedtypes[]	deduced arguments to template instance
	 *	*psparam	set to symbol declared and initialized to dedtypes[i]
	 *	flags		1: don't do 'toHeadMutable()'
	 */
	
    override Object dummyArg()
	{
		Type t;

		if (specType)
			t = specType;
		else
		{   
			// Use this for alias-parameter's too (?)
			t = new TypeIdentifier(loc, ident);
		}
		return t;
	}
}
