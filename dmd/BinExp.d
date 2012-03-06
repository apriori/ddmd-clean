module dmd.binExp;

import dmd.global;
import dmd.declaration;
import dmd.expression;
import dmd.hdrGenState;
import dmd.token;
import dmd.type;
import dmd.identifier;
import dmd.varDeclaration;
import dmd.statement;
//import dmd.lexer;
import std.exception : assumeUnique;
import std.stdio : writef;
import std.array;

/**************************************
 * Combine types.
 * Output:
 *	*pt	merged type, if *pt is not null
 *	*pe1	rewritten e1
 *	*pe2	rewritten e2
 * Returns:
 *	!=0	success
 *	0	failed
 */

/**************************************
 * Hash table of array op functions already generated or known about.
 */

//int typeMerge(Scope sc, Expression e, Type* pt, Expression* pe1, Expression* pe2) { assert (false,"zd cut"); }

class BinExp : Expression
{
    Expression e1;
    Expression e2;

    this(Loc loc, TOK op, int size, Expression e1, Expression e2)
	{

		super(loc, op, size);
		this.e1 = e1;
		this.e2 = e2;
	}

    override Expression syntaxCopy()
	{
		BinExp e = cast(BinExp)copy();
		//BinExp e = this.dup; // superior, but not tested
		e.type = null;
		e.e1 = e.e1.syntaxCopy();
		e.e2 = e.e2.syntaxCopy();

		return e;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put(' ');
		buf.put(Token.toChars(op));
		buf.put(' ');
		expToCBuffer(buf, hgs, e2, precedence[op] + 1);
	}
   
   void swapOperands()
   {
      typeid(Expression).swap(cast(void*) e1, cast(void*) e2);
   }

}

class AddAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKaddass, AddAssignExp.sizeof, e1, e2);
	}

}

class AddExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKadd, AddExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.add;
	}

	override Identifier opId_r()
	{
		return Id.add_r;
	}

}

class AndAndExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKandand, AndAndExp.sizeof, e1, e2);
	}

	override Expression checkToBoolean()
	{
		e2 = e2.checkToBoolean();
		return this;
	}

	override int isBit()
	{
		assert(false);
	}

}

class AndAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKandass, AndAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.andass;
	}

}

class AndExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKand, AndExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.iand;
	}

	override Identifier opId_r()
	{
		return Id.iand_r;
	}

}

class AssignExp : BinExp
{
	int ismemset = 0;

	this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKassign, AssignExp.sizeof, e1, e2);
	}

	override Expression checkToBoolean()
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.assign;
	}
}

class CatAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcatass, CatAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.catass;
	}

}

class CatExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcat, CatExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.cat;
	}

	override Identifier opId_r()
	{
		return Id.cat_r;
	}

}

class CmpExp : BinExp
{
	this(TOK op, Loc loc, Expression e1, Expression e2)
	{

		super(loc, op, CmpExp.sizeof, e1, e2);
	}

	int isBit()
	{
		assert(false);
	}

	Identifier opId()
	{
		return Id.cmp;
	}

}

class CommaExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{

		super(loc, TOKcomma, CommaExp.sizeof, e1, e2);
	}

}

class CondExp : BinExp
{
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

class DivAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdivass, DivAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.divass;
	}

}

class DivExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdiv, DivExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.div;
	}

	override Identifier opId_r()
	{
		return Id.div_r;
	}

}

class DotExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKdotexp, DotExp.sizeof, e1, e2);
	}

}

class EqualExp : BinExp
{
	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		super(loc, op, EqualExp.sizeof, e1, e2);
		assert(op == TOKequal || op == TOKnotequal);
	}

	override bool isBit()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.eq;
	}
}

class IdentityExp : BinExp
{
	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		super(loc, op, IdentityExp.sizeof, e1, e2);
	}

	override int isBit()
	{
		assert(false);
	}
}

class InExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKin, InExp.sizeof, e1, e2);
	}

	override int isBit()
	{
		return 0;
	}

	override Identifier opId()
	{
		return Id.opIn;
	}

	override Identifier opId_r()
	{
		return Id.opIn_r;
	}
}

class IndexExp : BinExp
{
	VarDeclaration lengthVar;
	int modifiable = 0;	// assume it is an rvalue

	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKindex, IndexExp.sizeof, e1, e2);
		//printf("IndexExp.IndexExp('%s')\n", toChars());
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.put("[");
		expToCBuffer(buf, hgs, e2, PREC_assign);
		buf.put("]");
	}
}

class MinAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKminass, MinAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.subass;
	}
}

class MinExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmin, MinExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.sub;
	}

	override Identifier opId_r()
	{
		return Id.sub_r;
	}
}

class ModAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmodass, this.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.modass;
	}
}

class ModExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmod, ModExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.mod;
	}

	override Identifier opId_r()
	{
		return Id.mod_r;
	}
}

class MulAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmulass, MulAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.mulass;
	}
}

class MulExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKmul, MulExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.mul;
	}

	override Identifier opId_r()
	{
		return Id.mul_r;
	}
}

class OrAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKorass, OrAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.orass;
	}
}

class OrExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKor, OrExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.ior;
	}

	override Identifier opId_r()
	{
		return Id.ior_r;
	}
}

class OrOrExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKoror, OrOrExp.sizeof, e1, e2);
	}

    override Expression checkToBoolean()
	{
		e2 = e2.checkToBoolean();
		return this;
	}
	
    override int isBit()
	{
		assert(false);
	}
}

class PostExp : BinExp
{
	this(TOK op, Loc loc, Expression e)
	{
		super(loc, op, PostExp.sizeof, e, new IntegerExp(loc, 1, Type.tint32));
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put((op == TOKplusplus) ? "++" : "--");
	}

	override Identifier opId()
	{
		return (op == TOKplusplus) ? Id.postinc : Id.postdec;
	}
}

class PowAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
    {
        super(loc, TOKpowass, PowAssignExp.sizeof, e1, e2);
    }
    
    
    // For operator overloading
    override Identifier opId()
    {
        return Id.powass;
    }
};
class PowExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
    {
        super(loc, TOKpow, PowExp.sizeof, e1, e2);
    }

    // For operator overloading
    override Identifier opId()
    {
        return Id.pow;
    }
    
    override Identifier opId_r()
    {
        return Id.pow_r;
    }
}

class RemoveExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKremove, RemoveExp.sizeof, e1, e2);
		//type = Type.tvoid;
	}
}

class ShlAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshlass, ShlAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.shlass;
	}
}

class ShlExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshl, ShlExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.shl;
	}

	override Identifier opId_r()
	{
		return Id.shl_r;
	}
}

class ShrAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshrass, ShrAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.shrass;
	}
}

class ShrExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKshr, ShrExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.shr;
	}

	override Identifier opId_r()
	{
		return Id.shr_r;
	}
}

class UshrAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKushrass, UshrAssignExp.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.ushrass;
	}
}

class UshrExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKushr, UshrExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.ushr;
	}

	override Identifier opId_r()
	{
		return Id.ushr_r;
	}
}

class XorAssignExp : BinExp
{
    this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKxorass, this.sizeof, e1, e2);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.xorass;
	}
}

class XorExp : BinExp
{
	this(Loc loc, Expression e1, Expression e2)
	{
		super(loc, TOKxor, XorExp.sizeof, e1, e2);
	}

	override Identifier opId()
	{
		return Id.ixor;
	}

	override Identifier opId_r()
	{
		return Id.ixor_r;
	}
}

