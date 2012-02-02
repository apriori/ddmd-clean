module dmd.attribDeclarations.ConditionalDeclaration;

import dmd.AttribDeclaration;
import dmd.Condition;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class ConditionalDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Condition condition;
    Dsymbol[] elsedecl;	// array of Dsymbol's for else block

    this(Condition condition, Dsymbol[] decl, Dsymbol[] elsedecl)
	{
		super(decl);
		//printf("ConditionalDeclaration.ConditionalDeclaration()\n");
		this.condition = condition;
		this.elsedecl = elsedecl;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    ConditionalDeclaration dd;
	
	    assert(!s);
	    dd = new ConditionalDeclaration(condition.syntaxCopy(),
		Dsymbol.arraySyntaxCopy(decl),
		Dsymbol.arraySyntaxCopy(elsedecl));
	    return dd;
	}
	
    override bool oneMember(Dsymbol ps)
	{
		//printf("ConditionalDeclaration.oneMember(), inc = %d\n", condition.inc);
		if (condition.inc)
		{
			auto d = condition.include(null, null) ? decl : elsedecl;
			return Dsymbol.oneMembers(d, ps);
		}
		ps = null;
		return true;
	}
	
    override void emitComment(Scope sc)
	{
	    //printf("ConditionalDeclaration.emitComment(sc = %p)\n", sc);
	    if (condition.inc)
	    {
	    	AttribDeclaration.emitComment(sc);
	    }
	    else if (sc.docbuf.data)
	    {
			/* If generating doc comment, be careful because if we're inside
			 * a template, then include(NULL, NULL) will fail.
			 */
			auto d = decl ? decl : elsedecl;
			foreach(s; d)
			    s.emitComment(sc);
	    }
	}
	
	// Decide if 'then' or 'else' code should be included

    override Dsymbol[] include(Scope sc, ScopeDsymbol sd)
	{
		//printf("ConditionalDeclaration.include()\n");
		assert(condition);
		return condition.include(sc, sd) ? decl : elsedecl;
	}
	
    override void addComment(string comment)
	{
		/* Because addComment is called by the parser, if we called
		 * include() it would define a version before it was used.
		 * But it's no problem to drill down to both decl and elsedecl,
		 * so that's the workaround.
		 */

		if (comment)
		{
			auto d = decl;

			for (int j = 0; j < 2; j++)
			{
				if (d)
				{
					foreach(s; d)
						//printf("ConditionalDeclaration::addComment %s\n", s.toChars());
						s.addComment(comment);
				}
				d = elsedecl;
			}
		}
	}
	
    override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
	    condition.toCBuffer(buf, hgs);
	    if (decl || elsedecl)
	    {
			buf.put('\n');
			buf.put('{');
			buf.put('\n');
			if (decl)
			{
			    foreach (Dsymbol s; decl)
			    {
					buf.put("    ");
					s.toCBuffer(buf, hgs);
			    }
			}
			buf.put('}');
			if (elsedecl)
			{
			    buf.put('\n');
			    buf.put("else");
			    buf.put('\n');
			    buf.put('{');
			    buf.put('\n');
			    foreach (Dsymbol s; elsedecl)
			    {
					buf.put("    ");
					s.toCBuffer(buf, hgs);
			    }
			    buf.put('}');
			}
	    }
	    else
		buf.put(':');
	    buf.put('\n');
	}

	//override void toJsonBuffer(ref Appender!(char[]) buf) { assert(false,"zd cut"); }

    override void importAll(Scope sc)
    {
        Dsymbol[] d = include(sc, null);

        //writef("\tConditionalDeclaration::importAll '%s', d = %p\n",toChars(), d);
        if (d)
        {
           foreach (s; d)
               s.importAll(sc);
        }
    }
    
    override void setScope(Scope sc)
    {
		Dsymbol[] d = include(sc, null);
		
		//writef("\tConditionalDeclaration::setScope '%s', d = %p\n",toChars(), d);
		if (d)
		{
			foreach (s; d)
				s.setScope(sc);
		}

    }
}
