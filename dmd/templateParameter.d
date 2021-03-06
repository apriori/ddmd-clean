module dmd.templateParameter;

import dmd.global;
import dmd.identifier;
import dmd.declaration;
import dmd.varDeclaration;
import dmd.dsymbol;
import dmd.scopeDsymbol;
import dmd.expression;
import dmd.Scope;
import dmd.hdrGenState;
import std.array;
import dmd.type;
//import dmd.types.TypeIdentifier;


class Tuple : Dobject
{
	Dobject[] objects;

	this()
	{
	}

	DYNCAST dyncast()
	{
		assert(false);
	}
}

class TemplateParameter : Dobject
{
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

   override TemplateParameter isTemplateParameter()
   {
      return this;
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
    abstract void print(Dobject oarg, Dobject oded);
    abstract void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs);
    abstract Dobject specialization();
    Dobject defaultArg(Loc loc, Scope sc)
    {
        assert(false);
    }

    /* If TemplateParameter's match as far as overloading goes.
     */
    abstract bool overloadMatch(TemplateParameter);

    /* Match actual argument against parameter.
     */
    MATCH matchArg(Scope sc, Dobject[] tiargs, int i, TemplateParameter[] parameters, Dobject[] dedtypes, Declaration* psparam, int flags = 0)
    {
        assert(false);
    }

    /* Create dummy argument based on parameter.
     */
    abstract Dobject dummyArg();
}

class TemplateAliasParameter : TemplateParameter
{
	/* Syntax:
	 *	specType ident : specAlias = defaultAlias
	 */

	Type specType;
	Dobject specAlias;
	Dobject defaultAlias;

	this(Loc loc, Identifier ident, Type specType, Dobject specAlias, Dobject defaultAlias)
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


   override void print(Dobject oarg, Dobject oded)
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
			DobjectToCBuffer(buf, hgs, specAlias);
		}
		if (defaultAlias)
		{
			buf.put(" = ");
			DobjectToCBuffer(buf, hgs, defaultAlias);
		}
	}

	override Dobject specialization()
	{
		return specAlias;
	}

   override Dobject defaultArg(Loc loc, Scope sc)
   {
       assert(false);
   }

   
    /* Match actual argument against parameter.
     */
    override MATCH matchArg(Scope sc, Dobject[] tiargs, int i, TemplateParameter[] parameters, Dobject[] dedtypes, Declaration* psparam, int flags = 0)
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


	override Dobject dummyArg()
	{
		if (!specAlias)
		{
			return global.sdummy;
		}
		return specAlias;
	}
}

class TemplateThisParameter : TemplateTypeParameter
{
    /* Syntax:
     *	this ident : specType = defaultType
     */
    Type specType;	// type parameter: if !=NULL, this is the type specialization
    Type defaultType;

    this(Loc loc, Identifier ident, Type specType, Type defaultType)
	{
		super(loc, ident, specType, defaultType);
	}

    override TemplateThisParameter isTemplateThisParameter()
	{	
		return this;
	}
	
    override TemplateParameter syntaxCopy()
    {
        assert (false);
    }
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("this ");
		super.toCBuffer(buf, hgs);
	}
}

class TemplateTupleParameter : TemplateParameter
{
    /* Syntax:
     *	ident ...
     */

    this(Loc loc, Identifier ident)
	{
		super(loc, ident);
		this.ident = ident;
	}

    override TemplateTupleParameter isTemplateTupleParameter()
	{
		return this;
	}
	
    override TemplateParameter syntaxCopy()
	{
		TemplateTupleParameter tp = new TemplateTupleParameter(loc, ident);
		return tp;
	}
	
    override void declareParameter(Scope sc)
	{
		TypeIdentifier ti = new TypeIdentifier(loc, ident);
		sparam = new AliasDeclaration(loc, ident, ti);
		if (!sc.insert(sparam))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
	}
	
    // Not sure when or where this gets called
    override void print(Dobject oarg, Dobject oded)
	{
		writef(" %s... [", ident.toChars());
		Tuple v = cast(Tuple)( oded.isTuple() );
		assert(v);

		//printf("|%d| ", v.objects.length);
		for (int i = 0; i < v.objects.length; i++)
		{
			if (i)
				writef(", ");

			Dobject o = v.objects[i];

			Dobject sa = o.isDsymbol();
			if (sa)
				writef("alias: %s", sa.toChars());

			Dobject ta = o.isType();
			if (ta)
				writef("type: %s", ta.toChars());

			Dobject ea = o.isExpression();
			if (ea)
				writef("exp: %s", ea.toChars());

			assert(!o.isTuple());		// no nested Tuple arguments
		}

		writef("]\n");
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(ident.toChars());
		buf.put("...");
	}
	
    override Dobject specialization()
	{
		return null;
	}
	
    override Dobject defaultArg(Loc loc, Scope sc)
	{
		return null;
	}
	
    override bool overloadMatch(TemplateParameter tp)
	{
		TemplateTupleParameter tvp = tp.isTemplateTupleParameter();
		if (tvp) {
			return true;			// match
		}

	Lnomatch:
		return false;
	}
	
	
    override Dobject dummyArg()
	{
		return null;
	}
}

class TemplateTypeParameter : TemplateParameter
{
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
	

    override void print(Dobject oarg, Dobject oded)
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

    override Dobject specialization()
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
	
    override Dobject dummyArg()
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

class TemplateValueParameter : TemplateParameter
{
    /* Syntax:
     *	valType ident : specValue = defaultValue
     */

    Type valType;
    Expression specValue;
    Expression defaultValue;

    this(Loc loc, Identifier ident, Type valType, Expression specValue, Expression defaultValue)
	{
		super(loc, ident);

		this.valType = valType;
		this.specValue = specValue;
		this.defaultValue = defaultValue;
	}

    override TemplateValueParameter isTemplateValueParameter()
	{
		return this;
	}

    override TemplateParameter syntaxCopy()
	{
		TemplateValueParameter tp = new TemplateValueParameter(loc, ident, valType, specValue, defaultValue);
		tp.valType = valType.syntaxCopy();
		if (specValue)
			tp.specValue = specValue.syntaxCopy();
		if (defaultValue)
			tp.defaultValue = defaultValue.syntaxCopy();
		return tp;
	}

    override void declareParameter(Scope sc)
	{
		VarDeclaration v = new VarDeclaration(loc, valType, ident, null);
		v.storage_class = STCtemplateparameter;
		if (!sc.insert(v))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
		sparam = v;
	}


    override void print(Dobject oarg, Dobject oded)
	{
		assert(false);
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		valType.toCBuffer(buf, ident, hgs);
		if (specValue)
		{
			buf.put(" : ");
			specValue.toCBuffer(buf, hgs);
		}
		if (defaultValue)
		{
			buf.put(" = ");
			defaultValue.toCBuffer(buf, hgs);
		}
	}

    override Dobject specialization()
	{
		return specValue;
	}


    override bool overloadMatch(TemplateParameter tp)
	{
		TemplateValueParameter tvp = tp.isTemplateValueParameter();

		if (tvp)
		{
			if (valType != tvp.valType)
				return false;

			if (valType && !valType.equals(tvp.valType))
				return false;

			if (specValue != tvp.specValue)
				return false;

			return true;			// match
		}

		return false;
	}


    override Dobject dummyArg()
	{
		if (!specValue)
		{
			return global.edummy;
		}

		return specValue;
	}
}
