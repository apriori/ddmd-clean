module dmd.expressions.OverExp;

import dmd.Global;
import dmd.Expression;
import dmd.dsymbols.OverloadSet;
import dmd.Scope;
import dmd.Token;
import dmd.Type;

import dmd.DDMDExtensions;

//! overload set
class OverExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	OverloadSet vars;

	this(OverloadSet s)
	{
		super(loc, TOKoverloadset, OverExp.sizeof);
		//printf("OverExp(this = %p, '%s')\n", this, var.toChars());
		vars = s;
		type = Type.tvoid;
	}


}

