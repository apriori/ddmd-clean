module dmd.templateParameters.TemplateThisParameter;

import dmd.Global;
import dmd.templateParameters.TemplateTypeParameter;
import dmd.Type;
import dmd.Identifier;
import dmd.TemplateParameter;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class TemplateThisParameter : TemplateTypeParameter
{
	mixin insertMemberExtension!(typeof(this));

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
