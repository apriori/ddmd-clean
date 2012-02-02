module dmd.templateParameters.TemplateTupleParameter;

import dmd.Global;
import dmd.TemplateParameter;
import dmd.Identifier;
import dmd.types.TypeIdentifier;
import dmd.declarations.AliasDeclaration;
import dmd.Scope;
import dmd.Declaration;
import dmd.HdrGenState;
import std.array;
import dmd.Dsymbol;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.Type;
import dmd.Expression;
import dmd.declarations.TupleDeclaration;

import dmd.DDMDExtensions;

class TemplateTupleParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

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
	
	
    override void print(Object oarg, Object oded)
	{
		writef(" %s... [", ident.toChars());
		Tuple v = isTuple(oded);
		assert(v);

		//printf("|%d| ", v.objects.length);
		for (int i = 0; i < v.objects.length; i++)
		{
			if (i)
				writef(", ");

			Object o = v.objects[i];

			Dsymbol sa = isDsymbol(o);
			if (sa)
				writef("alias: %s", sa.toChars());

			Type ta = isType(o);
			if (ta)
				writef("type: %s", ta.toChars());

			Expression ea = isExpression(o);
			if (ea)
				writef("exp: %s", ea.toChars());

			assert(!isTuple(o));		// no nested Tuple arguments
		}

		writef("]\n");
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(ident.toChars());
		buf.put("...");
	}
	
    override Object specialization()
	{
		return null;
	}
	
    override Object defaultArg(Loc loc, Scope sc)
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
	
	
    override Object dummyArg()
	{
		return null;
	}
}
