module dmd.expressions.FileInitExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.expressions.DefaultInitExp;
import dmd.expressions.StringExp;
import dmd.Token;
import dmd.Type;

import dmd.DDMDExtensions;

class FileInitExp : DefaultInitExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		super(loc, TOKfile, this.sizeof);
	}


}
