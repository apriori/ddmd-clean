module dmd.expressions.NewAnonClassExp;

import dmd.Global;
import dmd.Expression;
import dmd.Scope;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.expressions.DeclarationExp;
import dmd.expressions.NewExp;
import dmd.expressions.CommaExp;
import dmd.HdrGenState;
import dmd.Token;

import std.array;
import dmd.DDMDExtensions;

class NewAnonClassExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* thisexp.new(newargs) class baseclasses { } (arguments)
     */
    Expression thisexp;	// if !NULL, 'this' for class being allocated
    Expression[] newargs;	// Array of Expression's to call new operator
    ClassDeclaration cd;	// class being instantiated
    Expression[] arguments;	// Array of Expression's to call class constructor

	this(Loc loc, Expression thisexp, Expression[] newargs, ClassDeclaration cd, Expression[] arguments)
	{
		super(loc, TOKnewanonclass, NewAnonClassExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.cd = cd;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewAnonClassExp(loc, 
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			cast(ClassDeclaration)cd.syntaxCopy(null),
			arraySyntaxCopy(arguments));
	}
	


	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (thisexp)
		{	
			expToCBuffer(buf, hgs, thisexp, PREC_primary);
			buf.put('.');
		}
		buf.put("new");
		if (newargs && newargs.length)
		{
			buf.put('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.put(')');
		}
		buf.put(" class ");
		if (arguments && arguments.length)
		{
			buf.put('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.put(')');
		}
		//buf.put(" { }");
		if (cd)
		{
			cd.toCBuffer(buf, hgs);
		}
	}

}

