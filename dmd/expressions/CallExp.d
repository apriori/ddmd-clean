module dmd.expressions.CallExp;

import dmd.Global;
import dmd.expressions.ErrorExp;
import dmd.Expression;
import dmd.Cast;
import dmd.types.TypeFunction;
import dmd.ScopeDsymbol;
import dmd.expressions.CastExp;
import dmd.expressions.FuncExp;
import dmd.expressions.SymOffExp;
import dmd.types.TypePointer;
import dmd.expressions.ThisExp;
import dmd.expressions.OverExp;
import dmd.Dsymbol;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.types.TypeDelegate;
import dmd.scopeDsymbols.ClassDeclaration;
import dmd.expressions.DsymbolExp;
import dmd.expressions.DotExp;
import dmd.expressions.TemplateExp;
import dmd.types.TypeStruct;
import dmd.types.TypeClass;
import dmd.Identifier;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.expressions.DeclarationExp;
import dmd.declarations.CtorDeclaration;
import dmd.expressions.PtrExp;
import dmd.scopeDsymbols.TemplateDeclaration;
import dmd.expressions.StructLiteralExp;
import dmd.scopeDsymbols.StructDeclaration;
import dmd.expressions.DotTemplateExp;
import dmd.expressions.CommaExp;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.Type;
import dmd.expressions.ScopeExp;
import dmd.expressions.VarExp;
import dmd.expressions.DotTemplateInstanceExp;
import dmd.scopeDsymbols.TemplateInstance;
import dmd.expressions.DelegateExp;
import dmd.expressions.IdentifierExp;
import dmd.expressions.DotVarExp;
import dmd.expressions.DotIdExp;
import dmd.types.TypeAArray;
import dmd.expressions.RemoveExp;
import dmd.expressions.UnaExp;
import dmd.InterState;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Token;

import std.stdio;

import std.array;
import dmd.DDMDExtensions;

class CallExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression[] arguments;

	this(Loc loc, Expression e, Expression[] exps)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
		this.arguments = exps;
	}

	this(Loc loc, Expression e)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
	}

	this(Loc loc, Expression e, Expression earg1)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
		
		Expression[] arguments;
		if (earg1)
		{	
			arguments.reserve(1);
			arguments[0] = earg1;
		}
		this.arguments = arguments;
	}

	this(Loc loc, Expression e, Expression earg1, Expression earg2)
	{

		super(loc, TOKcall, CallExp.sizeof, e);
		
		Expression[] arguments;
		arguments.reserve(2);
		arguments[0] = earg1;
		arguments[1] = earg2;

		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new CallExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}





	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int i;
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.put('(');
		argsToCBuffer(buf, arguments, hgs);
		buf.put(')');
	}






}

