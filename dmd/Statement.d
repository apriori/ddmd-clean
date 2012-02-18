module dmd.Statement;

import dmd.Global;
import dmd.Initializer;
import dmd.BinExp;
import dmd.Catch;
import dmd.Scope;
import dmd.Parameter;
import dmd.VarDeclaration;
import dmd.Declaration;
import dmd.FuncDeclaration;
import dmd.AttribDeclaration;
import dmd.Dsymbol;
import dmd.Condition;
import dmd.Token;
import dmd.Identifier;
import dmd.HdrGenState;
import dmd.Expression;

import std.stdio, std.format;
import std.array;


//! startup code used in *Statement.interpret() functions
enum START = `
	if (istate.start)
	{
		if (istate.start !is this)
			return null;
		istate.start = null;
	}
`;

/* How a statement exits; this is returned by blockExit()
 */
alias int BE;
enum 
{
    BEnone =	 0,
    BEfallthru = 1,
    BEthrow =    2,
    BEreturn =   4,
    BEgoto =     8,
    BEhalt =	 0x10,
    BEbreak =	 0x20,
    BEcontinue = 0x40,
    BEany = (BEfallthru | BEthrow | BEreturn | BEgoto | BEhalt),
}


class Statement
{
    Loc loc;

    this(Loc loc)
    {
        this.loc = loc;
    }

    Statement syntaxCopy()
    {
        assert(false);
    }

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

    void error(T...)(string format, T t)
    {
        .error(loc, format, t);
    }

    void warning(T...)(string format, T t)
    {
        if (global.params.warnings && !global.gag)
        {
            writef("warning - ");
            .error(loc, format, t);
        }
    }

    void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
    {
        assert(false);
    }

    void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
    { assert (false);
    }

    // Avoid dynamic_cast
    TryCatchStatement isTryCatchStatement() { return null; }
    GotoStatement isGotoStatement() { return null; }
    AsmStatement isAsmStatement() { return null; }
    version (_DH) { int incontract; }
    ScopeStatement isScopeStatement() { return null; }
    DeclarationStatement isDeclarationStatement() { return null; }
    CompoundStatement isCompoundStatement() { return null; }
    ReturnStatement isReturnStatement() { return null; }
    IfStatement isIfStatement() { return null; }

    bool hasBreak()
    {
        assert(false);
    }

    bool hasContinue()
    {
        assert(false);
    }

    // TRUE if statement uses exception handling



    // true if statement 'comes from' somewhere else, like a goto
    bool comeFrom()
    {
        //printf("Statement::comeFrom()\n");
        return false;
    }

    // Return TRUE if statement has no code in it
    bool isEmpty()
    {
        //printf("Statement::isEmpty()\n");
        return false;
    }

    /*********************************
     * Flatten out the scope by presenting the statement
     * as an array of statements.
     * Returns NULL if no flattening necessary.
     */
    Statement[] flatten(Scope sc)
    {
        return null;
    }

}

class AsmStatement : Statement
{
    Token*[] tokens;
    //code* asmcode;
    uint asmalign;		// alignment of this statement
    bool refparam;		// true if function parameter is referenced
    bool naked;		// true if function is to be naked
    uint regs;		// mask of registers modified

    this(Loc loc, Token*[] tokens)
	{

		super(loc);
		this.tokens = tokens;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override bool comeFrom()
	{
		assert(false);
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("asm { ");
		Token*[] toks = tokens;
      //TODO unittest this
		foreach (t; toks)
		{
			buf.put(t.toChars());
			if (t.next                         &&
			   t.value != TOKmin               &&
			   t.value != TOKcomma             &&
			   t.next.value != TOKcomma       &&
			   t.value != TOKlbracket          &&
			   t.next.value != TOKlbracket    &&
			   t.next.value != TOKrbracket    &&
			   t.value != TOKlparen            &&
			   t.next.value != TOKlparen      &&
			   t.next.value != TOKrparen      &&
			   t.value != TOKdot               &&
			   t.next.value != TOKdot)
			{
				buf.put(' ');
			}
		}
		buf.put("; }");
		buf.put('\n');
	}
	
    override AsmStatement isAsmStatement() { return this; }

}

class BreakStatement : Statement
{
    Identifier ident;

    this(Loc loc, Identifier ident)
	{

		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		BreakStatement s = new BreakStatement(loc, ident);
		return s;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("break");
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}

}

class CaseRangeStatement : Statement
{
    Expression first;
    Expression last;
    Statement statement;

    this(Loc loc, Expression first, Expression last, Statement s)
	{

		super(loc);
		this.first = first;
		this.last = last;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("case ");
		first.toCBuffer(buf, hgs);
		buf.put(": .. case ");
		last.toCBuffer(buf, hgs);
		buf.put('\n');
		statement.toCBuffer(buf, hgs);
	}
}

class CaseStatement : Statement
{
    Expression exp;
    Statement statement;

    int index = 0;			// which case it is (since we sort this)
    //block* cblock = null;	// back end: label for the block

    this(Loc loc, Expression exp, Statement s)
	{

		super(loc);
		
		this.exp = exp;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		CaseStatement s = new CaseStatement(loc, exp.syntaxCopy(), statement.syntaxCopy());
		return s;
	}
	
    override int opCmp(Object obj)
	{
		// Sort cases so we can do an efficient lookup
		CaseStatement cs2 = cast(CaseStatement)obj;

		return exp.opCmp(cs2.exp);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    buf.put("case ");
		exp.toCBuffer(buf, hgs);
		buf.put(':');
		buf.put('\n');
		statement.toCBuffer(buf, hgs);
	}

}

class CompileStatement : Statement
{
	Expression exp;

	this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}

	override Statement syntaxCopy()
	{
		Expression e = exp.syntaxCopy();
		CompileStatement es = new CompileStatement(loc, e);
		return es;
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.put(");");
		if (!hgs.FLinit.init)
			buf.put('\n');
	}

}

class CompoundStatement : Statement
{
    Statement[] statements;

    this(Loc loc, Statement[] s)
	{
		super(loc);
		statements = s;
	}
	
    this(Loc loc, Statement s1, Statement s2)
	{
		super(loc);
		
		statements.reserve(2);
		statements ~= (s1);
		statements ~= (s2);
	}
	
    override Statement syntaxCopy()
	{
		Statement[] a;
		a.reserve(statements.length);

		foreach (size_t i, Statement s; statements)
		{	
			if (s)
				s = s.syntaxCopy();
			a[i] = s;
		}

		return new CompoundStatement(loc, a);
	}
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		foreach (s; statements)
		{
			if (s)
				s.toCBuffer(buf, hgs);
		}
	}

    override Statement[] flatten(Scope sc)
	{
		return statements;
	}

    override ReturnStatement isReturnStatement()
	{
		ReturnStatement rs = null;

		foreach(s; statements)
		{	
			if (s)
			{
				rs = s.isReturnStatement();
				if (rs)
					break;
			}
		}
		return rs;
	}

    override CompoundStatement isCompoundStatement() { return this; }
}

class CompoundDeclarationStatement : CompoundStatement
{
    this(Loc loc, Statement[] s)
	{
		super(loc, s);
		///statements = s;
	}

    override Statement syntaxCopy()
	{
		Statement[] a; 
		a.length = statements.length;
		for (size_t i = 0; i < statements.length; i++)
		{
			Statement s = statements[i];
			if (s)
				s = s.syntaxCopy();
			a[i] = s;
		}
		CompoundDeclarationStatement cs = new CompoundDeclarationStatement(loc, a);
		return cs;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		int nwritten = 0;
		foreach (Statement s; statements)
		{
			if (s)
			{
				DeclarationStatement ds = s.isDeclarationStatement();
				assert(ds);
				DeclarationExp de = cast(DeclarationExp)ds.exp;
				assert(de.op == TOKdeclaration);
				Declaration d = de.declaration.isDeclaration();
				assert(d);
				VarDeclaration v = d.isVarDeclaration();
				if (v)
				{
					/* This essentially copies the part of VarDeclaration.toCBuffer()
					 * that does not print the type.
					 * Should refactor this.
					 */
					if (nwritten)
					{
						buf.put(',');
						buf.put(v.ident.toChars());
					}
					else
					{
						StorageClassDeclaration.stcToCBuffer(buf, v.storage_class);
						if (v.type)
							v.type.toCBuffer(buf, v.ident, hgs);
						else
							buf.put(v.ident.toChars());
					}

					if (v.init)
					{
						buf.put(" = ");
						ExpInitializer ie = v.init.isExpInitializer();
						if (ie && (ie.exp.op == TOKconstruct || ie.exp.op == TOKblit))
							(cast(AssignExp)ie.exp).e2.toCBuffer(buf, hgs);
						else
							v.init.toCBuffer(buf, hgs);
					}
				}
				else
					d.toCBuffer(buf, hgs);
				nwritten++;
			}
		}
		buf.put(';');
		if (!hgs.FLinit.init)
			buf.put('\n');
	}
}

class ConditionalStatement : Statement
{
    Condition condition;
    Statement ifbody;
    Statement elsebody;

    this(Loc loc, Condition condition, Statement ifbody, Statement elsebody)
	{
		super(loc);
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
	
    override Statement syntaxCopy()
	{
		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();
		ConditionalStatement s = new ConditionalStatement(loc, condition.syntaxCopy(), ifbody.syntaxCopy(), e);
		return s;
	}
	
    override Statement[] flatten(Scope sc)
	{
		Statement s;

		if (condition.include(sc, null))
			s = ifbody;
		else
			s = elsebody;

		Statement[] a;
		a ~= (s);

		return a;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

class ContinueStatement : Statement
{
    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		ContinueStatement s = new ContinueStatement(loc, ident);
		return s;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("continue");
		if (ident)
		{   
			buf.put(' ');
			buf.put(ident.toChars());
		}
		buf.put(';');
		buf.put('\n');
	}

}

class DefaultStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement s)
	{
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		DefaultStatement s = new DefaultStatement(loc, statement.syntaxCopy());
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("default:\n");
		statement.toCBuffer(buf, hgs);
	}

}

class DoStatement : Statement
{
    Statement body_;
    Expression condition;

    this(Loc loc, Statement b, Expression c)
	{
		super(loc);
		body_ = b;
		condition = c;
	}
	
    override Statement syntaxCopy()
	{
		DoStatement s = new DoStatement(loc, body_ ? body_.syntaxCopy() : null, condition.syntaxCopy());
		return s;
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
	    buf.put("do");
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.put("while (");
		condition.toCBuffer(buf, hgs);
		buf.put(')');
	}

}

class ExpStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}
	
	/*
	~this()
	{
		delete exp;
	}
	*/
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		ExpStatement es = new ExpStatement(loc, e);
		return es;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.put(';');
		if (!hgs.FLinit.init)
			buf.put('\n');
	}

}

class DeclarationStatement : ExpStatement
{
    // Doing declarations as an expression, rather than a statement,
    // makes inlining functions much easier.

    this(Loc loc, Dsymbol declaration)
	{
		super(loc, new DeclarationExp(loc, declaration));
	}
	
    this(Loc loc, Expression exp)
	{
		super(loc, exp);
	}
	
    override Statement syntaxCopy()
	{
		DeclarationStatement ds = new DeclarationStatement(loc, exp.syntaxCopy());
		return ds;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		exp.toCBuffer(buf, hgs);
	}
	

    override DeclarationStatement isDeclarationStatement() { return this; }
}

class ForStatement : Statement
{
    Statement init;
    Expression condition;
    Expression increment;
    Statement body_;

    this(Loc loc, Statement init, Expression condition, Expression increment, Statement body_)
	{
		super(loc);
		
		this.init = init;
		this.condition = condition;
		this.increment = increment;
		this.body_ = body_;
	}

    override Statement syntaxCopy()
	{
		Statement i = null;
		if (init)
			i = init.syntaxCopy();
		Expression c = null;
		if (condition)
			c = condition.syntaxCopy();
		Expression inc = null;
		if (increment)
			inc = increment.syntaxCopy();
		ForStatement s = new ForStatement(loc, i, c, inc, body_.syntaxCopy());
		return s;
	}
	
    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("ForStatement::scopeCode()\n");
		//print();
		if (init)
			init.scopeCode(sc, sentry, sexception, sfinally);
		else
			Statement.scopeCode(sc, sentry, sexception, sfinally);
	}
	
    override bool hasBreak()
	{
		//printf("ForStatement.hasBreak()\n");
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("for (");
		if (init)
		{
			hgs.FLinit.init++;
			init.toCBuffer(buf, hgs);
			hgs.FLinit.init--;
		}
		else
			buf.put(';');
		if (condition)
		{   buf.put(' ');
			condition.toCBuffer(buf, hgs);
		}
		buf.put(';');
		if (increment)
		{   
			buf.put(' ');
			increment.toCBuffer(buf, hgs);
		}
		buf.put(')');
		buf.put('\n');
		buf.put('{');
		buf.put('\n');
		body_.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
	
}

class ForeachRangeStatement : Statement
{
    TOK op;		// TOKforeach or TOKforeach_reverse
    Parameter arg;		// loop index variable
    Expression lwr;
    Expression upr;
    Statement body_;

    VarDeclaration key = null;

    this(Loc loc, TOK op, Parameter arg, Expression lwr, Expression upr, Statement body_)
	{
		super(loc);
		this.op = op;
		this.arg = arg;
		this.lwr = lwr;
		this.upr = upr;
		this.body_ = body_;
	}
	
    override Statement syntaxCopy()
	{
		ForeachRangeStatement s = new ForeachRangeStatement(loc, op,
			arg.syntaxCopy(),
			lwr.syntaxCopy(),
			upr.syntaxCopy(),
			body_ ? body_.syntaxCopy() : null);

		return s;
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

		if (arg.type)
			arg.type.toCBuffer(buf, arg.ident, hgs);
		else
			buf.put(arg.ident.toChars());

		buf.put("; ");
		lwr.toCBuffer(buf, hgs);
		buf.put(" .. ");
		upr.toCBuffer(buf, hgs);
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

class ForeachStatement : Statement
{
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

class GotoCaseStatement : Statement
{
    Expression exp;		// NULL, or which case to goto
    CaseStatement cs;		// case statement it resolves to

    this(Loc loc, Expression exp)
	{
		super(loc);
		cs = null;
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		GotoCaseStatement s = new GotoCaseStatement(loc, e);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto case");
		if (exp)
		{   
			buf.put(' ');
			exp.toCBuffer(buf, hgs);
		}
		buf.put(';');
		buf.put('\n');
	}

}

class GotoDefaultStatement : Statement
{
    SwitchStatement sw;

    this(Loc loc)
	{
		super(loc);
		sw = null;
	}

    override Statement syntaxCopy()
	{
		GotoDefaultStatement s = new GotoDefaultStatement(loc);
		return s;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto default;\n");
	}

}

class GotoStatement : Statement
{
    Identifier ident;
    LabelDsymbol label = null;
    TryFinallyStatement tf = null;

    this(Loc loc, Identifier ident)
	{
		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		GotoStatement s = new GotoStatement(loc, ident);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("goto ");
		buf.put(ident.toChars());
		buf.put(';');
		buf.put('\n');
	}
	
    override GotoStatement isGotoStatement() { return this; }
}

class IfStatement : Statement
{
    Parameter arg;
    Expression condition;
    Statement ifbody;
    Statement elsebody;

    VarDeclaration match;	// for MatchExpression results

    this(Loc loc, Parameter arg, Expression condition, Statement ifbody, Statement elsebody)
	{
		super(loc);
		this.arg = arg;
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
		
    override Statement syntaxCopy()
	{
		Statement i = null;
		if (ifbody)
			i = ifbody.syntaxCopy();

		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();

		Parameter a = arg ? arg.syntaxCopy() : null;
		IfStatement s = new IfStatement(loc, a, condition.syntaxCopy(), i, e);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("if (");
		if (arg)
		{
			if (arg.type)
				arg.type.toCBuffer(buf, arg.ident, hgs);
			else
			{   
				buf.put("auto ");
				buf.put(arg.ident.toChars());
			}
			buf.put(" = ");
		}
		condition.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		ifbody.toCBuffer(buf, hgs);
		if (elsebody)
		{   
			buf.put("else");
			buf.put('\n');
			elsebody.toCBuffer(buf, hgs);
		}
	}
	
    override IfStatement isIfStatement() { return this; }
	
}

class LabelStatement : Statement
{
    Identifier ident;
    Statement statement;
    TryFinallyStatement tf = null;
    //block* lblock = null;		// back end
    int isReturnLabel = 0;

    this(Loc loc, Identifier ident, Statement statement)
	{
		super(loc);
		this.ident = ident;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		LabelStatement s = new LabelStatement(loc, ident, statement.syntaxCopy());
		return s;
	}

    override Statement[] flatten(Scope sc)
	{
		Statement[] a = null;

		if (statement)
		{
			a = statement.flatten(sc);
			if (a)
			{
				if (!a.length)
					a ~= (new ExpStatement(loc, null));

				Statement s = a[0];

				s = new LabelStatement(loc, ident, s);
				a[0] = s;
			}
		}

		return a;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(ident.toChars());
		buf.put(':');
		buf.put('\n');
		if (statement)
			statement.toCBuffer(buf, hgs);
	}
	
}

class OnScopeStatement : Statement
{
    TOK tok;
    Statement statement;

    this(Loc loc, TOK tok, Statement statement)
	{
		super(loc);

		this.tok = tok;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		OnScopeStatement s = new OnScopeStatement(loc,
			tok, statement.syntaxCopy());
		return s;
	}

    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put(Token.toChars(tok));
		buf.put(' ');
		statement.toCBuffer(buf, hgs);
	}

    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
    {
        assert(false);
    }

}

class PeelStatement : Statement
{
	Statement s;

	this(Statement s)
	{
		assert(false);
		super(Loc(0));
	}

}

class PragmaStatement : Statement
{
	Identifier ident;
	Expression[] args;		// array of Expression's
	Statement body_;

	this(Loc loc, Identifier ident, Expression[] args, Statement body_)
	{
		super(loc);
		this.ident = ident;
		this.args = args;
		this.body_ = body_;
	}
	
	override Statement syntaxCopy()
	{
		Statement b = null;
		if (body_)
		b = body_.syntaxCopy();
		PragmaStatement s = new PragmaStatement(loc,
			ident, Expression.arraySyntaxCopy(args), b);
		return s;

	}
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("pragma (");
		buf.put(ident.toChars());
		if (args && args.length)
		{
			buf.put(", ");
         // This is defined right below
			argsToCBuffer(buf, args, hgs);
		}
		buf.put(')');
		if (body_)
		{
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
	
			body_.toCBuffer(buf, hgs);
	
			buf.put('}');
			buf.put('\n');
		}
		else
		{
			buf.put(';');
			buf.put('\n');
		}

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

}

class ReturnStatement : Statement
{
   Expression exp;

   this(Loc loc, Expression exp)
   {
      super(loc);
      this.exp = exp;
   }

   override Statement syntaxCopy()
   {
      Expression e = exp ? exp.syntaxCopy() : null;
      return new ReturnStatement(loc, e);
   }
	
	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"return ");
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.put(';');
		buf.put('\n');
	}
	
    override ReturnStatement isReturnStatement() { return this; }
}

class ScopeStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement s)
	{
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		Statement s = statement ? statement.syntaxCopy() : null;
		s = new ScopeStatement(loc, s);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put('{');
		buf.put('\n');

		if (statement)
			statement.toCBuffer(buf, hgs);

		buf.put('}');
		buf.put('\n');
	}
	
    override ScopeStatement isScopeStatement() { return this; }
	
    override bool hasBreak()
	{
		//printf("ScopeStatement.hasBreak() %s\n", toChars());
		return statement ? statement.hasBreak() : false;
	}
	
    override bool hasContinue()
	{
		return statement ? statement.hasContinue() : false;
	}

}

class StaticAssertStatement : Statement
{
    StaticAssert sa;

    this(StaticAssert sa)
	{
		super(sa.loc);
		this.sa = sa;
	}
	
    override Statement syntaxCopy()
	{
		StaticAssertStatement s = new StaticAssertStatement(cast(StaticAssert)sa.syntaxCopy(null));
		return s;
	}
    
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
}

class SwitchErrorStatement : Statement
{
	this(Loc loc)
	{
		super(loc);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("SwitchErrorStatement.toCBuffer()");
		buf.put('\n');
	}

}

class SwitchStatement : Statement
{
    Expression condition;
    Statement body_;
    bool isFinal;

    DefaultStatement sdefault = null;
    TryFinallyStatement tf = null;
    GotoCaseStatement[] gotoCases;		// array of unresolved GotoCaseStatement's
    CaseStatement[] cases;		// array of CaseStatement's
    int hasNoDefault = 0;	// !=0 if no default statement
    int hasVars = 0;		// !=0 if has variable case values

    this(Loc loc, Expression c, Statement b, bool isFinal)
	{
		super(loc);
		
		this.condition = c;
		this.body_ = b;
		this.isFinal = isFinal;
		
	}
	
    override Statement syntaxCopy()
	{
		SwitchStatement s = new SwitchStatement(loc,
			condition.syntaxCopy(), body_.syntaxCopy(), isFinal);
		return s;
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("switch (");
		condition.toCBuffer(buf, hgs);
		buf.put(')');
		buf.put('\n');
		if (body_)
		{
			if (!body_.isScopeStatement())
			{   
				buf.put('{');
				buf.put('\n');
				body_.toCBuffer(buf, hgs);
				buf.put('}');
				buf.put('\n');
			}
			else
			{
				body_.toCBuffer(buf, hgs);
			}
		}
	}

}

class SynchronizedStatement : Statement
{
    Expression exp;
    Statement body_;

    this(Loc loc, Expression exp, Statement body_)
	{
		super(loc);
		
		this.exp = exp;
		this.body_ = body_;
		//this.esync = null;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool hasContinue()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}

class ThrowStatement : Statement
{
    Expression exp;

    this(Loc loc, Expression exp)
	{
		super(loc);
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		ThrowStatement s = new ThrowStatement(loc, exp.syntaxCopy());
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"throw ");
		exp.toCBuffer(buf, hgs);
		buf.put(';');
		buf.put('\n');
	}

}

class TryCatchStatement : Statement
{
    Statement body_;
    Catch[] catches;

    this(Loc loc, Statement body_, Catch[] catches)
	{
		super(loc);
		this.body_ = body_;
		this.catches = catches;
	}
	
    override Statement syntaxCopy()
	{
		Catch[] a;
		a.reserve(catches.length);
		for (int i = 0; i < a.length; i++)
		{   
			Catch c = catches[i];
			c = c.syntaxCopy();
			a[i] = c;
		}
		TryCatchStatement s = new TryCatchStatement(loc, body_.syntaxCopy(), a);
		return s;
	}
	
    override bool hasBreak()
	{
		assert(false);
	}

	/***************************************
	 * Builds the following:
	 *	_try
	 *	block
	 *	jcatch
	 *	handler
	 * A try-catch statement.
	 */
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("try");
		buf.put('\n');
		if (body_)
			body_.toCBuffer(buf, hgs);
		for (size_t i = 0; i < catches.length; i++)
		{
			Catch c = catches[i];
			c.toCBuffer(buf, hgs);
		}
	}
	
    override TryCatchStatement isTryCatchStatement() { return this; }
}

class TryFinallyStatement : Statement
{
    Statement body_;
    Statement finalbody;

    this(Loc loc, Statement body_, Statement finalbody)
	{
		super(loc);
		this.body_ = body_;
		this.finalbody = finalbody;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		formattedWrite(buf,"try\n{\n");
		body_.toCBuffer(buf, hgs);
		formattedWrite(buf,"}\nfinally\n{\n");
		finalbody.toCBuffer(buf, hgs);
		buf.put('}');
		buf.put('\n');
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool hasContinue()
	{
		assert(false);
	}

	/****************************************
	 * A try-finally statement.
	 * Builds the following:
	 *	_try
	 *	block
	 *	_finally
	 *	finalbody
	 *	_ret
	 */
}

class UnrolledLoopStatement : Statement
{
	Statement[] statements;

	this(Loc loc, Statement[] s)
	{
		super(loc);
		statements = s;
	}

	override Statement syntaxCopy()
	{
		assert(false);
	}

	override bool hasBreak()
	{
		assert(false);
	}

	override bool hasContinue()
	{
		assert(false);
	}

	override bool comeFrom()
	{
		assert(false);
	}

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}

class VolatileStatement : Statement
{
    Statement statement;

    this(Loc loc, Statement statement)
	{
		super(loc);
		this.statement = statement;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override Statement[] flatten(Scope sc)
	{
		Statement[] a = statement ? statement.flatten(sc) : null;
		if (a)
		{	
			foreach (ref Statement s; a)
			{   
				s = new VolatileStatement(loc, s);
			}
		}

		return a;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		buf.put("volatile");
		if (statement)
		{   
			if (statement.isScopeStatement())
				buf.put('\n');
			else
				buf.put(' ');
			statement.toCBuffer(buf, hgs);
		}
	}

}

class WhileStatement : Statement
{
    Expression condition;
    Statement body_;

    this(Loc loc, Expression c, Statement b)
	{
		super(loc);
		condition = c;
		body_ = b;
	}
	
    override Statement syntaxCopy()
	{
		WhileStatement s = new WhileStatement(loc, condition.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
    override bool hasBreak()
	{
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override bool comeFrom()
	{
		assert(false);
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}
	
}

class WithStatement : Statement
{
    Expression exp;
    Statement body_;
    VarDeclaration wthis;

    this(Loc loc, Expression exp, Statement body_)
	{
		super(loc);
		this.exp = exp;
		this.body_ = body_;
		wthis = null;
	}
	
    override Statement syntaxCopy()
	{
		WithStatement s = new WithStatement(loc, exp.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		assert(false);
	}

}
