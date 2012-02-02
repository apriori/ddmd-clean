module dmd.statements.AsmStatement;

import dmd.Global;
import dmd.Statement;
import dmd.Token;
import dmd.Scope;
import dmd.HdrGenState;
import std.array;
import dmd.dsymbols.LabelDsymbol;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.declarations.FuncDeclaration;
import dmd.Declaration;
import dmd.statements.LabelStatement;

import std.stdio;

import dmd.DDMDExtensions;

class AsmStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

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
