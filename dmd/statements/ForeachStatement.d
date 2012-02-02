module dmd.statements.ForeachStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Token;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.declarations.FuncDeclaration;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import std.array;
import dmd.ScopeDsymbol;
import dmd.types.TypeAArray;
import dmd.Type;
import dmd.expressions.CallExp;
import dmd.types.TypeTuple;
import dmd.expressions.TupleExp;
import dmd.Initializer;
import dmd.initializers.ExpInitializer;
import dmd.expressions.IntegerExp;
import dmd.statements.ExpStatement;
import dmd.expressions.DeclarationExp;
import dmd.Dsymbol;
import dmd.statements.BreakStatement;
import dmd.statements.DefaultStatement;
import dmd.statements.CaseStatement;
import dmd.statements.SwitchStatement;
import dmd.expressions.VarExp;
import dmd.declarations.AliasDeclaration;
import dmd.statements.CompoundStatement;
import dmd.statements.ScopeStatement;
import dmd.statements.UnrolledLoopStatement;
import dmd.Identifier;
import dmd.Lexer;
import dmd.statements.DeclarationStatement;
import dmd.statements.CompoundDeclarationStatement;
import dmd.scopeDsymbols.AggregateDeclaration;
import dmd.types.TypeClass;
import dmd.expressions.NotExp;
import dmd.types.TypeStruct;
import dmd.declarations.FuncLiteralDeclaration;
import dmd.expressions.IdentifierExp;
import dmd.types.TypeFunction;
import dmd.statements.GotoStatement;
import dmd.expressions.FuncExp;
import dmd.statements.ReturnStatement;
import dmd.expressions.IndexExp;
import dmd.statements.ForStatement;
import dmd.expressions.SliceExp;
import dmd.expressions.DotIdExp;
import dmd.expressions.PostExp;
import dmd.expressions.AddAssignExp;
import dmd.expressions.CmpExp;
import dmd.Parameter;



import dmd.DDMDExtensions;

class ForeachStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    TOK op;		// TOKforeach or TOKforeach_reverse
    Parameter[] arguments;	// array of Argument*'s
    Expression aggr;
    Statement body_;

    VarDeclaration key;
    VarDeclaration value;

    FuncDeclaration func;	// function we're lexically in

    Statement[] cases;	// put breaks, continues, gotos and returns here
    Statement[] gotos;	// forward referenced goto's go here

    this(Loc loc, TOK op, Parameter[] arguments, Expression aggr, Statement body_)
	{
		super(loc);
		
		this.op = op;
		this.arguments = arguments;
		this.aggr = aggr;
		this.body_ = body_;
	}
	
    override bool hasBreak()
	{
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put(Token.toChars(op));
		buf.put(" (");
		for (int i = 0; i < arguments.length; i++)
		{
			auto a = arguments[i];
			if (i)
				buf.put(", ");
			if (a.storageClass & STCref) 
				buf.put((global.params.Dversion == 1) ? "inout " : "ref ");
			if (a.type)
				a.type.toCBuffer(buf, a.ident, hgs);
			else
				buf.put(a.ident.toChars());
		}
		buf.put("; ");
		aggr.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		buf.put('{');
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}


}
