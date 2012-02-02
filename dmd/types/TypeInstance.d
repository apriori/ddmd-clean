module dmd.types.TypeInstance;

import dmd.Global;
import dmd.types.TypeQualified;
import dmd.templateParameters.TemplateAliasParameter;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.TemplateParameter;
import dmd.templateParameters.TemplateValueParameter;
import dmd.templateParameters.TemplateTupleParameter;
import dmd.expressions.VarExp;
import dmd.Type;
import dmd.HdrGenState;
import std.array;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Scope;
import dmd.Token;

import dmd.DDMDExtensions;

/* Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
class TypeInstance : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

	TemplateInstance tempinst;

	this(Loc loc, TemplateInstance tempinst)
	{
		super(Tinstance, loc);
		this.tempinst = tempinst;
	}

	override Type syntaxCopy()
	{
		//printf("TypeInstance::syntaxCopy() %s, %d\n", toChars(), idents.length);
		TypeInstance t;

		t = new TypeInstance(loc, cast(TemplateInstance)tempinst.syntaxCopy(null));
		t.mod = mod;
		return t;
	}

	//char *toChars();

	//void toDecoBuffer(ref Appender!(char[]) *buf, int flag);

	override void toCBuffer2(ref Appender!(char[]) buf, ref HdrGenState hgs, MOD mod)
	{
		if (mod != this.mod)
		{	toCBuffer3(buf, hgs, mod);
			return;
		}
		tempinst.toCBuffer(buf, hgs);
		toCBuffer2Helper(buf, hgs);
	}
}
