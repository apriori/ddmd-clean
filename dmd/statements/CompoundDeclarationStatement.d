module dmd.statements.CompoundDeclarationStatement;

import dmd.Global;
import dmd.statements.CompoundStatement;
import dmd.Token;
import dmd.VarDeclaration;
import dmd.expressions.AssignExp;
import dmd.initializers.ExpInitializer;
import dmd.Declaration;
import dmd.attribDeclarations.StorageClassDeclaration;
import dmd.statements.DeclarationStatement;
import dmd.expressions.DeclarationExp;
import dmd.Statement;
import dmd.HdrGenState;
import std.array;

import dmd.DDMDExtensions;

class CompoundDeclarationStatement : CompoundStatement
{
	mixin insertMemberExtension!(typeof(this));

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
