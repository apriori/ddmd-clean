module dmd.templateParameters.TemplateValueParameter;

import dmd.Global;
import dmd.TemplateParameter;
import dmd.Scope;
import dmd.Declaration;
import dmd.Type;
import dmd.Expression;
import dmd.Identifier;
import dmd.HdrGenState;
import std.array;
import dmd.VarDeclaration;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.expressions.DefaultInitExp;
import dmd.Dsymbol;
import dmd.Token;

import dmd.Dsymbol : isExpression;

import dmd.DDMDExtensions;

class TemplateValueParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

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


    override void print(Object oarg, Object oded)
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

    override Object specialization()
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


    override Object dummyArg()
	{
		if (!specValue)
		{
			return global.edummy;
		}

		return specValue;
	}
}
