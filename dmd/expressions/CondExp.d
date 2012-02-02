module dmd.expressions.CondExp;

import dmd.Global;
import dmd.expressions.BinExp;
import dmd.expressions.PtrExp;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import dmd.Type;
import dmd.Token;



import std.array;
import dmd.DDMDExtensions;

class CondExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    Expression econd;

    this(Loc loc, Expression econd, Expression e1, Expression e2)
	{
		super(loc, TOKquestion, CondExp.sizeof, e1, e2);
		this.econd = econd;
	}
	
    override Expression syntaxCopy()
	{
		return new CondExp(loc, econd.syntaxCopy(), e1.syntaxCopy(), e2.syntaxCopy());
	}


	


    



    override Expression checkToBoolean()
	{
		e1 = e1.checkToBoolean();
		e2 = e2.checkToBoolean();
		return this;
	}


    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, econd, PREC_oror);
		buf.put(" ? ");
		expToCBuffer(buf, hgs, e1, PREC_expr);
		buf.put(" : ");
		expToCBuffer(buf, hgs, e2, PREC_cond);
	}





	
	

}
