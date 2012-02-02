module dmd.expressions.NewExp;

import dmd.Global;
import dmd.Expression;
import dmd.declarations.NewDeclaration;
import dmd.declarations.CtorDeclaration;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;
import dmd.types.TypeFunction;
import dmd.types.TypeClass;
import dmd.types.TypeStruct;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.types.TypeDArray;
import dmd.Dsymbol;
import dmd.expressions.ThisExp;
import dmd.expressions.DotIdExp;
import dmd.Identifier;
import dmd.expressions.IntegerExp;
import dmd.types.TypePointer;



import std.string : toStringz;

import std.array;
import dmd.DDMDExtensions;

class NewExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* thisexp.new(newargs) newtype(arguments)
     */
    Expression thisexp;	// if !null, 'this' for class being allocated
    Expression[] newargs;	// Array of Expression's to call new operator
    Type newtype;
    Expression[] arguments;	// Array of Expression's

    CtorDeclaration member;	// constructor function
    NewDeclaration allocator;	// allocator function
    int onstack;		// allocate on stack

	this(Loc loc, Expression thisexp, Expression[] newargs, Type newtype, Expression[] arguments)
	{
		super(loc, TOKnew, NewExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.newtype = newtype;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewExp(loc,
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			newtype.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	




	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;

		if (thisexp)
		{
			expToCBuffer(buf, hgs, thisexp, PREC_primary);
			buf.put('.');
		}
		buf.put("new ");
		if (newargs && newargs.length)
		{
			buf.put('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.put(')');
		}
		newtype.toCBuffer(buf, null, hgs);
		if (arguments && arguments.length)
		{
			buf.put('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.put(')');
		}
	}





}

