module dmd.TemplateParameter;

import dmd.Global;
import dmd.Identifier;
import dmd.Declaration;
import dmd.templateParameters.TemplateTypeParameter;
import dmd.templateParameters.TemplateValueParameter;
import dmd.templateParameters.TemplateAliasParameter;
import dmd.templateParameters.TemplateThisParameter;
import dmd.templateParameters.TemplateTupleParameter;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.Type;

import dmd.DDMDExtensions;

class Tuple
{
	Object[] objects;

	this()
	{
	}

	DYNCAST dyncast()
	{
		assert(false);
	}
}

class TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* For type-parameter:
     *	template Foo(ident)		// specType is set to NULL
     *	template Foo(ident : specType)
     * For value-parameter:
     *	template Foo(valType ident)	// specValue is set to NULL
     *	template Foo(valType ident : specValue)
     * For alias-parameter:
     *	template Foo(alias ident)
     * For this-parameter:
     *	template Foo(this ident)
     */

    Loc loc;
    Identifier ident;

    Declaration sparam;

    this(Loc loc, Identifier ident)
	{
		this.loc = loc;
		this.ident = ident;
	}

    TemplateTypeParameter isTemplateTypeParameter()
	{
		return null;
	}
	
    TemplateValueParameter isTemplateValueParameter()
	{
		return null; 
	}
	
    TemplateAliasParameter isTemplateAliasParameter()
	{
		return null; 
	}
	
    TemplateThisParameter isTemplateThisParameter()
	{
		return null; 
	}

    TemplateTupleParameter isTemplateTupleParameter()
	{
		return null;
	}

    abstract TemplateParameter syntaxCopy();
    abstract void declareParameter(Scope sc);
    //abstract void semantic(Scope);
    abstract void print(Object oarg, Object oded);
    abstract void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs);
    abstract Object specialization();
    Object defaultArg(Loc loc, Scope sc)
    {
        assert(false);
    }

    /* If TemplateParameter's match as far as overloading goes.
     */
    abstract bool overloadMatch(TemplateParameter);

    /* Match actual argument against parameter.
     */
    MATCH matchArg(Scope sc, Object[] tiargs, int i, TemplateParameter[] parameters, Object[] dedtypes, Declaration* psparam, int flags = 0)
    {
        assert(false);
    }

    /* Create dummy argument based on parameter.
     */
    abstract Object dummyArg();
}
