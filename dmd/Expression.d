module dmd.Expression;
// also defines enum WANT,

import dmd.Global;
import dmd.Parameter;
import dmd.expressions.IdentifierExp;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.declarations.FuncDeclaration;
import dmd.Identifier;
import dmd.expressions.DotIdExp;
import dmd.expressions.TypeExp;
import dmd.expressions.CallExp;
import dmd.expressions.VarExp;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.expressions.CommaExp;
import dmd.expressions.NullExp;
import dmd.expressions.AddrExp;
import dmd.expressions.FuncExp;
import dmd.statements.ReturnStatement;
import dmd.Statement;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.types.TypeFunction;
import dmd.expressions.ErrorExp;
import dmd.types.TypeStruct;
import dmd.expressions.CastExp;
import dmd.Token;
import dmd.types.TypeClass;
import dmd.expressions.PtrExp;
import dmd.types.TypeSArray;
import dmd.types.TypeReference;

import dmd.DDMDExtensions;

import std.stdio : writef;

import std.conv, std.array;

/* Things like:
 *	int.size
 *	foo.size
 *	(foo).size
 *	cast(foo).size
 */
Expression typeDotIdExp(Loc loc, Type type, Identifier ident)
{
	return new DotIdExp(loc, new TypeExp(loc, type), ident);
}

/+/
Expression EXP_CANT_INTERPRET = castToExpression(1);
Expression EXP_CONTINUE_INTERPRET = castToExpression(2);
Expression EXP_BREAK_INTERPRET = castToExpression(3);
Expression EXP_GOTO_INTERPRET = castToExpression(4);
Expression EXP_VOID_INTERPRET = castToExpression(5);
// +/

alias int WANT;
enum 
{
    WANTflags = 1,
    WANTvalue = 2,
    WANTinterpret = 4,
}

Expression castToExpression(int i)
{
	union U
	{
		int i;
		Expression e;
	}
	
	U u;
	u.i = i;
	return u.e;
}

/**************************************************
 * Write expression out to buf, but wrap it
 * in ( ) if its precedence is less than pr.
 */

void expToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Expression e, PREC pr)
{
    //if (precedence[e.op] == 0) e.dump(0);
    if ( precedence[e.op] < pr ||
	       /* Despite precedence, we don't allow a<b<c expressions.
	       * They must be parenthesized.
	       */
	       (pr == PREC_rel && precedence[e.op] == pr)
        )
    {
		buf.put('(');
		e.toCBuffer(buf, hgs);
		buf.put(')');
    }
    else
		e.toCBuffer(buf, hgs);
}

/**************************************************
 * Write out argument list to buf.
 */

void argsToCBuffer(ref Appender!(char[]) buf, Expression[] arguments, ref HdrGenState hgs)
{
    if (arguments)
    {
		foreach (size_t i, Expression arg; arguments)
		{   
			if (arg)
			{	
				if (i)
					buf.put(',');
				expToCBuffer(buf, hgs, arg, PREC_assign);
			}
		}
    }
}

class Expression
{
	mixin insertMemberExtension!(typeof(this));
	
    Loc loc;			// file location
    TOK op;		// handy to minimize use of dynamic_cast
    Type type;			// !=null means that semantic() has been run
    int size;			// # of bytes in Expression so we can copy() it

    this(Loc loc, TOK op, int size)
	{
		this.loc = loc;
		//writef("Expression.Expression(op = %d %s) this = %p\n", op, to!(string)(op), this);
		this.op = op;
		this.size = size;
		type = null;
	}

	//bool equals(Object o) { assert (false,"zd cut"); }

	/*********************************
	 * Does *not* do a deep copy.
	 */
    Expression copy()
	{
      return cloneThis(this);
	}
	
    Expression syntaxCopy()
	{
		//printf("Expression::syntaxCopy()\n");
		//dump(0);
		return copy();
	}
    
    /**************************************************
     * Write expression out to buf, but wrap it
     * in ( ) if its precedence is less than pr.
     */

    void expToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs, Expression e, PREC pr)
    {
        //if (precedence[e.op] == 0) e.dump(0);
        if (precedence[e.op] < pr ||
                /* Despite precedence, we don't allow a<b<c expressions.
                 * They must be parenthesized.
                 */
                (pr == PREC_rel && precedence[e.op] == pr))
        {
            buf.put('(');
            e.toCBuffer(buf, hgs);
            buf.put(')');
        }
        else
            e.toCBuffer(buf, hgs);
    }

    /**************************************************
     * Write out argument list to buf.
     */

    void argsToCBuffer(ref Appender!(char[]) buf, Expression[] arguments, ref HdrGenState hgs)
    {
        if (arguments)
            foreach (size_t i, Expression arg; arguments)
                if (arg)
                {	
                    if (i) buf.put(',');
                    expToCBuffer(buf, hgs, arg, PREC_assign);
                }
    }

    bool isBool(bool result)
    {
        return false;
    }

	Identifier opId()
	{
		assert(false);
	}

	void rvalue()
	{
   }
    //DYNCAST dyncast() { return DYNCAST.DYNCAST_EXPRESSION; }	// kludge for template.isExpression()

    void print()
	{
		assert(false);
	}
	
    string toChars()
	{
		auto buf = appender!(char[])();
		HdrGenState hgs;
	
		toCBuffer(buf, hgs);
		return buf.data.idup;
	}
	

    private void indent(int indent)
    {
        foreach (i; 0 .. indent)
            writef(" ");
    }

    private string type_print(Type type)
    {
        return type ? type.toChars() : "null";
    }


    void error(T...)(string format, T t)
    {
        .error(loc, format, t);
    }

    void warning(T...)(string format, T t)
    {
        super.warning(loc, format, t);
    }

	int isConst() { assert(false); }

	real toImaginary() { assert(false); }
	Identifier opId_r() { assert(false); }


        ulong toInteger()
        { assert (false);
        }
    int isBit()
    {
        assert (false);
    }

    static Expression combine(Expression e1, Expression e2)
	{
		if (e1)
		{
			if (e2)
			{
				e1 = new CommaExp(e1.loc, e1, e2);
				e1.type = e2.type;
			}
		}
		else
		{
			e1 = e2;
		}

		return e1;
	}
    
   // I think the whole thing is obviated by ".dup"
	static Expression[] arraySyntaxCopy(Expression[] exps)
	{
		Expression[] a = null;

		if (exps)
		{
			a.length = exps.length;
         // I think this is proper D code
         foreach ( i, e; exps )
         {
            if (e) 
                a[i] = e.syntaxCopy();
         }
         // used to go something like this:
			/+ for (size_t i = 0; i < a.length; i++)
			{   
				auto e = exps[i];

			    if (e)
					e = e.syntaxCopy();
				a[i] = e;
			} +/
		}
		return a;
	}

    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(op));
	}
	
    void toMangleBuffer(ref Appender!(char[]) buf)
	{
	}

    Expression checkToBoolean()
   {
       assert(false); 
   }
	/**************************************
	 * Do an implicit cast.
	 * Issue error if it can't be done.
	 */
    //Expression implicitCastTo(Scope sc, Type t) { assert (false,"zd cut"); }
    
	/****************************************
	 * Resolve __LINE__ and __FILE__ to loc.
	 */
	Expression resolveLoc(Loc loc, Scope sc)
	{
	    return this;
	}

}

