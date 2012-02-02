module dmd.expressions.RemoveExp;

import dmd.Global;
import dmd.Expression;
import dmd.expressions.BinExp;
import dmd.Token;
import dmd.Type;
import dmd.types.TypeAArray;


import dmd.DDMDExtensions;

/* This deletes the key e1 from the associative array e2
 */

class RemoveExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKremove, RemoveExp.sizeof, e1, e2);
		type = Type.tvoid;
	}

}

