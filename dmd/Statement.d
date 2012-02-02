module dmd.Statement;

import dmd.Global;
import dmd.statements.TryCatchStatement;
import dmd.statements.GotoStatement;
import dmd.statements.AsmStatement;
import dmd.statements.ScopeStatement;
import dmd.statements.DeclarationStatement;
import dmd.statements.CompoundStatement;
import dmd.statements.ReturnStatement;
import dmd.statements.IfStatement;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Expression;

import std.stdio;
import std.array;

import dmd.DDMDExtensions;

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
    mixin insertMemberExtension!(typeof(this));

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
