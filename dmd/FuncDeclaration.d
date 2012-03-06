module dmd.funcDeclaration;

import dmd.global;
import dmd.declaration;
import dmd.token;
import dmd.scopeDsymbol;
import dmd.parameter;
import dmd.statement;
import dmd.identifier;
import dmd.varDeclaration;
import dmd.type;
import dmd.expression;
import dmd.dsymbol;
import dmd.Scope;
import dmd.hdrGenState;
import std.array;
import dmd.Module;
import dmd.attribDeclaration;

import std.string;

/*******************************
 * Generate unique unittest function Id so we can have multiple
 * instances per module.
 */
Identifier unitTestId()
{
    return Identifier.uniqueId("__unittest");
}

class FuncDeclaration : Declaration
{
    Type[] fthrows;			// Array of Type's of exceptions (not used)
    Statement frequire;
    Statement fensure;
    Statement fbody;

    FuncDeclaration[] foverrides;	// functions this function overrides
    FuncDeclaration fdrequire;		// function that does the in contract
    FuncDeclaration fdensure;		// function that does the out contract

    Identifier outId;			// identifier for out statement
    VarDeclaration vresult;		// variable corresponding to outId
    LabelDsymbol returnLabel;		// where the return goes

    Dsymbol[string] localsymtab;		// used to prevent symbols in different
                          // scopes from having the same name
    VarDeclaration vthis;		// 'this' parameter (member and nested)
    //VarDeclaration v_arguments;	// '_arguments' parameter
    Dsymbol[] parameters;		// Array of VarDeclaration's for parameters
    LabelDsymbol[string] labtab;		// statement label symbol table
    Declaration overnext;		// next in overload list
    Loc endloc;					// location of closing curly bracket
    int vtblIndex;				// for member functions, index into vtbl[]
    int naked;					// !=0 if naked
    int inlineAsm;				// !=0 if has inline assembler
    int inlineNest;				// !=0 if nested inline
    int cantInterpret;			// !=0 if cannot interpret function
    PASS semanticRun;
								// this function's frame ptr
    ForeachStatement fes;		// if foreach body, this is the foreach
    int introducing;			// !=0 if 'introducing' function
    Type tintro;			// if !=null, then this is the type
					// of the 'introducing' function
					// this one is overriding
    int inferRetType;			// !=0 if return type is to be inferred

    // Things that should really go into Scope
    int hasReturnExp;			// 1 if there's a return exp; statement
					// 2 if there's a throw statement
					// 4 if there's an assert(0)
					// 8 if there's inline asm

    // Support for NRVO (named return value optimization)
    bool nrvo_can = true;			// !=0 means we can do it
    VarDeclaration nrvo_var;		// variable to replace with shidden
    //Symbol* shidden;			// hidden pointer passed to function

    //BUILTIN builtin;		// set if this is a known, builtin
					// function we can evaluate at compile
					// time

    //int tookAddressOf;			// set if someone took the address of
					// this function
    Dsymbol[] closureVars;		// local variables in this function
					// which are referenced by nested
					// functions
    
    this(Loc loc, Loc endloc, Identifier id, StorageClass storage_class, Type type)
	{
		super(id);

		this.storage_class = storage_class;
		this.type = type;
		this.loc = loc;
		this.endloc = endloc;
		vtblIndex = -1;
		semanticRun = PASSinit;
		/* The type given for "infer the return type" is a TypeFunction with
		 * null for the return type.
		 */
		inferRetType = (type && type.nextOf() is null);
		nrvo_can = 1;
		//builtin = BUILTINunknown;
	}

   override Dsymbol syntaxCopy(Dsymbol s)
	{
		FuncDeclaration f;

		if (s)
			f = cast(FuncDeclaration)s;
		else
			f = new FuncDeclaration(loc, endloc, ident, storage_class, type.syntaxCopy());

		f.outId = outId;
		f.frequire = frequire ? frequire.syntaxCopy() : null;
		f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
		f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
		assert(!fthrows); // deprecated

		return f;
	}

   override Dobject descend( int rank )
   {
      switch (rank)
      {
         case 1:
            return type;
            break;
         case 2:
            return ident;
            break;
         case 3:
            return parameters[0];
            break;
         case 4:
            return fbody;
            break;
         default:
            return fbody;
      }
      return null;
   }

	override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		StorageClassDeclaration.stcToCBuffer(buf, storage_class);
		type.toCBuffer(buf, ident, hgs);
      buf.put(hgs.nL);
		bodyToCBuffer(buf, hgs);
      buf.put(hgs.nL);
	}

	void bodyToCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
	{
		if (fbody )
		{
         // in{}
			if (frequire)
			{
            buf.put(hgs.indent);
				buf.put("in");
				buf.put(hgs.nL);
				frequire.toCBuffer(buf, hgs);
			}
			// out{}
			if (fensure)
			{
            buf.put(hgs.indent);
				buf.put("out");
				if (outId)
				{
					buf.put('(');
					buf.put(outId.toChars());
					buf.put(')');
				}
				buf.put(hgs.nL);
				fensure.toCBuffer(buf, hgs);
			}
			if (frequire || fensure)
			{
            buf.put(hgs.indent);
				buf.put("body");
				buf.put(hgs.nL);
			}
         buf.put(hgs.indent);
			buf.put('{');
         buf.put(hgs.pushNewLine);
			fbody.toCBuffer(buf, hgs);
         buf.put(hgs.popIndent);
			buf.put('}');
			buf.put(hgs.nL);
		}
		else
		{   
         buf.put(';');
		}
	}

	/********************************
	 * Labels are in a separate scope, one per function.
	 */
    LabelDsymbol searchLabel(Identifier ident)
	{
		LabelDsymbol s;

		s = labtab.get(ident.toChars(),null);
		if (!s)
		{
			s = new LabelDsymbol(ident);
			labtab[ident.toChars()] = s;
		}

		return s;
	}

	/****************************************
	 * If non-static member function that has a 'this' pointer,
	 * return the aggregate it is a member of.
	 * Otherwise, return null.
	 */
    override AggregateDeclaration isThis()
	{
		AggregateDeclaration ad = null;

		if ((storage_class & STCstatic) == 0)
		{
			ad = isMember2();
		}
		return ad;
	}

    AggregateDeclaration isMember2()
	{
		AggregateDeclaration ad = null;

		for (Dsymbol s = this; s; s = s.parent)
		{
			ad = s.isMember();
			if (ad)
			{ 
					break;
			}
			if (!s.parent || (!s.parent.isTemplateInstance()))
			{   
					break;
			}
		}
		
		return ad;
	}

    void appendExp(Expression e)
	{
		assert(false);
	}

    void appendState(Statement s)
	{
		assert(false);
	}

    override string mangle()
	out (result)
	{
		assert(result.length > 0);
	}
	body
	{
		if (isMain()) {
			return "_Dmain";
		}

		if (isWinMain() || isDllMain() || ident == Id.tls_get_addr)
			return ident.toChars();

		assert(this);

		return Declaration.mangle();
	}

    override string toPrettyChars()
	{
		if (isMain())
			return "D main";
		else
			return Dsymbol.toPrettyChars();
	}

    int isMain()
	{
		return ident is Id.main && linkage != LINKc && !isMember() && !isNested();
	}

    int isWinMain()
	{
		return ident == Id.WinMain && linkage != LINKc && !isMember();
	}

    int isDllMain()
	{
		return ident == Id.DllMain && linkage != LINKc && !isMember();
	}

    override bool isExport()
	{
		return protection == PROTexport;
	}

    override bool isImportedSymbol()
	{
		return (protection == PROTexport) && !fbody;
	}

    override bool isAbstract()
	{
		return (storage_class & STCabstract) != 0;
	}

    override bool isCodeseg()
	{
		return true;		// functions are always in the code segment
	}

    override bool isOverloadable()
	{
		return 1;			// functions can be overloaded
	}

    bool isPure()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).ispure;
	}

	int isSafe()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUSTsafe;
	}

	int isTrusted()
	{
		assert(type.ty == Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUSTtrusted;
	}

    bool isNested()
	{
		return ((storage_class & STCstatic) == 0) &&
		   (toParent2().isFuncDeclaration() !is null);
	}

    override bool needThis()
	{
		bool needThis = isThis() !is null;

		if (!needThis) {
			if (auto fa = isFuncAliasDeclaration()) {
				needThis = fa.funcalias.needThis();
			}
		}

		return needThis;
	}

    bool isVirtual()
	{
	    Dsymbol p = toParent();
	    return isMember() &&
			!(isStatic() || protection == PROTprivate || protection == PROTpackage) &&
			p.isClassDeclaration() &&
			!(p.isInterfaceDeclaration() && isFinal());
	}

    override bool isFinal()
	{
		ClassDeclaration cd;
		return isMember() && (Declaration.isFinal() || ((cd = toParent().isClassDeclaration()) !is null && cd.storage_class & STCfinal));
	}

    override string kind()
	{
		return "function";
	}

    override void toDocBuffer(ref Appender!(char[]) buf)
	{
		assert(false);
	}

	FuncDeclaration isUnique()
	{
        assert(false);
	}

	/*******************************
	 * Look at all the variables in this function that are referenced
	 * by nested functions, and determine if a closure needs to be
	 * created for them.
	 */

    /****************************************************
	 * Merge into this function the 'in' contracts of all it overrides.
	 * 'in's are OR'd together, i.e. only one of them needs to pass.
	 */


    /*********************************************
     * Return the function's parameter list, and whether
     * it is variadic or not.
     */

    Parameter[] getParameters(ref int pvarargs)
    {
        Parameter[] fparameters;
        int fvarargs;

        if (type)
        {
	        assert(type.ty == Tfunction);
	        auto fdtype = cast(TypeFunction)type;
	        fparameters = fdtype.parameters;
	        fvarargs = fdtype.varargs;
        }
        else // Constructors don't have type's
        {
            CtorDeclaration fctor = isCtorDeclaration();
	        assert(fctor);
	        fparameters = fctor.arguments;
	        fvarargs = fctor.varargs;
        }
        if (pvarargs)
	     pvarargs = fvarargs;
        return fparameters;
    }

    override FuncDeclaration isFuncDeclaration() { return this; }
}

class CtorDeclaration : FuncDeclaration
{
   Parameter[] arguments;
   int varargs;

   this(Loc loc, Loc endloc, Parameter[] arguments, int varargs)
   {
      super(loc, endloc, Id.ctor, STCundefined, null);

      this.arguments = arguments;
      this.varargs = varargs;
      //printf("CtorDeclaration(loc = %s) %s\n", loc.toChars(), toChars());
   }

   override Dsymbol syntaxCopy(Dsymbol)
   {
      CtorDeclaration f = new CtorDeclaration(loc, endloc, null, varargs);

      f.outId = outId;
      f.frequire = frequire ? frequire.syntaxCopy() : null;
      f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
      f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
      assert(!fthrows); // deprecated

      f.arguments = Parameter.arraySyntaxCopy(arguments);
      return f;
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("this");
      Parameter.argsToCBuffer(buf, hgs, arguments, varargs);
      buf.put(hgs.nL);
      bodyToCBuffer(buf, hgs);
      buf.put(hgs.nL);
   }

   override string kind()
   {
      return "constructor";
   }

   override string toChars()
   {
      return "this";
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return (isThis() && vthis && global.params.useInvariants);
   }

   override void toDocBuffer(ref Appender!(char[]) buf)
   {
      assert(false);
   }

   override CtorDeclaration isCtorDeclaration() { return this; }
}

class DeleteDeclaration : FuncDeclaration
{
   Parameter[] arguments;

   this(Loc loc, Loc endloc, Parameter[] arguments)
   {
      super(loc, endloc, Id.classDelete, STCstatic, null);
      this.arguments = arguments;
   }

   override Dsymbol syntaxCopy(Dsymbol)
   {
      DeleteDeclaration f;

      f = new DeleteDeclaration(loc, endloc, null);

      FuncDeclaration.syntaxCopy(f);

      f.arguments = Parameter.arraySyntaxCopy(arguments);

      return f;
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("delete");
      Parameter.argsToCBuffer(buf, hgs, arguments, 0);
      bodyToCBuffer(buf, hgs);
   }

   override string kind()
   {
      return "deallocator";
   }

   override bool isDelete()
   {
      return true;
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   version (_DH) {
      DeleteDeclaration isDeleteDeclaration() { return this; }
   }
}

class DtorDeclaration : FuncDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, Id.dtor, STCundefined, null);
   }

   this(Loc loc, Loc endloc, Identifier id)
   {
      super(loc, endloc, id, STCundefined, null);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      DtorDeclaration dd = new DtorDeclaration(loc, endloc, ident);
      return super.syntaxCopy(dd);
   }


   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("~this()");
		buf.put(hgs.nL);
      bodyToCBuffer(buf, hgs);
   }

   override void toJsonBuffer(ref Appender!(char[]) buf)
   {
      // intentionally empty
   }

   override string kind()
   {
      return "destructor";
   }

   override string toChars()
   {
      return "~this";
   }

   override bool isVirtual()
   {
      /* This should be FALSE so that dtor's don't get put into the vtbl[],
       * but doing so will require recompiling everything.
       */
      version (BREAKABI) {
         return false;
      } else {
         return super.isVirtual();
      }
   }

   override bool addPreInvariant()
   {
      return (isThis() && vthis && global.params.useInvariants);
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override bool overloadInsert(Dsymbol s)
   {
      return false;	   // cannot overload destructors
   }

   override void emitComment(Scope sc)
   {
      // intentionally empty
   }

   override DtorDeclaration isDtorDeclaration() { return this; }
}

class FuncAliasDeclaration : FuncDeclaration
{
   FuncDeclaration funcalias;

   this(FuncDeclaration funcalias)
   {
      super(funcalias.loc, funcalias.endloc, funcalias.ident, funcalias.storage_class, funcalias.type);
      assert(funcalias !is this);
      this.funcalias = funcalias;
   }

   override FuncAliasDeclaration isFuncAliasDeclaration() { return this; }

   override string kind()
   {
      return "function alias";
   }

}

class FuncLiteralDeclaration : FuncDeclaration
{
   TOK tok;			// TOKfunction or TOKdelegate

   this(Loc loc, Loc endloc, Type type, TOK tok, ForeachStatement fes)
   {
      super(loc, endloc, null, STCundefined, type);

      string id;

      if (fes)
         id = "__foreachbody";
      else if (tok == TOKdelegate)
         id = "__dgliteral";
      else
         id = "__funcliteral";

      this.ident = Identifier.uniqueId(id);
      this.tok = tok;
      this.fes = fes;

      //printf("FuncLiteralDeclaration() id = '%s', type = '%s'\n", this->ident->toChars(), type->toChars());
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put(kind());
      buf.put(' ');
      type.toCBuffer(buf, null, hgs);
      bodyToCBuffer(buf, hgs);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      FuncLiteralDeclaration f;

      //printf("FuncLiteralDeclaration.syntaxCopy('%s')\n", toChars());
      if (s)
         f = cast(FuncLiteralDeclaration)s;
      else
      {	
         f = new FuncLiteralDeclaration(loc, endloc, type.syntaxCopy(), tok, fes);
         f.ident = ident;		// keep old identifier
      }
      FuncDeclaration.syntaxCopy(f);
      return f;
   }

   override bool isNested()
   {
      //printf("FuncLiteralDeclaration::isNested() '%s'\n", toChars());
      return (tok == TOKdelegate);
   }

   override bool isVirtual()
   {
      return false;
   }

   override FuncLiteralDeclaration isFuncLiteralDeclaration() { return this; }

   override string kind()
   {
      return (tok == TOKdelegate) ? "delegate" : "function";
   }
}

class InvariantDeclaration : FuncDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, Id.classInvariant, STCundefined, null);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      InvariantDeclaration id = new InvariantDeclaration(loc, endloc);
      FuncDeclaration.syntaxCopy(id);
      return id;
   }


   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override void emitComment(Scope sc)
   {
      assert(false);
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (hgs.hdrgen)
         return;
      buf.put("invariant");
      bodyToCBuffer(buf, hgs);
   }

   override void toJsonBuffer(ref Appender!(char[]) buf)
   {
   }

   override InvariantDeclaration isInvariantDeclaration() { return this; }
}

class NewDeclaration : FuncDeclaration
{
   Parameter[] arguments;
   int varargs;

   this(Loc loc, Loc endloc, Parameter[] arguments, int varargs)
   {
      super(loc, endloc, Id.classNew, STCstatic, null);
      this.arguments = arguments;
      this.varargs = varargs;
   }

   override Dsymbol syntaxCopy(Dsymbol)
   {
      NewDeclaration f;

      f = new NewDeclaration(loc, endloc, null, varargs);

      FuncDeclaration.syntaxCopy(f);

      f.arguments = Parameter.arraySyntaxCopy(arguments);

      return f;
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("new");
      Parameter.argsToCBuffer(buf, hgs, arguments, varargs);
      bodyToCBuffer(buf, hgs);
   }

   override string kind()
   {
      return "allocator";
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override NewDeclaration isNewDeclaration() { return this; }
}

class PostBlitDeclaration : FuncDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, Id._postblit, STCundefined, null);
   }

   this(Loc loc, Loc endloc, Identifier id)
   {
      super(loc, loc, id, STCundefined, null);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      PostBlitDeclaration dd = new PostBlitDeclaration(loc, endloc, ident);
      return super.syntaxCopy(dd);
   }


   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("this(this)");
      bodyToCBuffer(buf, hgs);
   }

   override void toJsonBuffer(ref Appender!(char[]) buf)
   {
      // intentionally empty
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return (isThis() && vthis && global.params.useInvariants);
   }

   override bool overloadInsert(Dsymbol s)
   {
      return false;	   // cannot overload postblits
   }

   override void emitComment(Scope sc)
   {
      // intentionally empty
   }

   override PostBlitDeclaration isPostBlitDeclaration() { return this; }
}

class StaticCtorDeclaration : FuncDeclaration
{
   this(Loc loc, Loc endloc, string name = "_staticCtor")
   {
      super(loc, endloc, Identifier.uniqueId("_staticCtor"), STCstatic, null);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      StaticCtorDeclaration scd = new StaticCtorDeclaration(loc, endloc);
      return FuncDeclaration.syntaxCopy(scd);
   }


   override AggregateDeclaration isThis()
   {
      return null;
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override void emitComment(Scope sc)
   {
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (hgs.hdrgen)
      {
         buf.put("static this();\n");
         return;
      }
      buf.put("static this()");
      bodyToCBuffer(buf, hgs);
   }

   override void toJsonBuffer(ref Appender!(char[]) buf)
   {
   }

   override StaticCtorDeclaration isStaticCtorDeclaration() { return this; }
}

class SharedStaticCtorDeclaration : StaticCtorDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, "_sharedStaticCtor");
   }

   Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      SharedStaticCtorDeclaration scd = new SharedStaticCtorDeclaration(loc, endloc);
      return FuncDeclaration.syntaxCopy(scd);
   }

   void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      buf.put("shared ");
      StaticCtorDeclaration.toCBuffer(buf, hgs);
   }

   SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return this; }
}

class StaticDtorDeclaration : FuncDeclaration
{
   VarDeclaration vgate;	// 'gate' variable

   this(Loc loc, Loc endloc, string name = "_staticDtor")
   {
      super(loc, endloc, Identifier.uniqueId(name), STCstatic, null);
      vgate = null;
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      StaticDtorDeclaration sdd = new StaticDtorDeclaration(loc, endloc);
      return super.syntaxCopy(sdd);
   }


   override AggregateDeclaration isThis()
   {
      return null;
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override void emitComment(Scope sc)
   {
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (hgs.hdrgen)
         return;
      buf.put("static ~this()");
      bodyToCBuffer(buf, hgs);
   }

   override void toJsonBuffer(ref Appender!(char[]) buf)
   {
   }

   override StaticDtorDeclaration isStaticDtorDeclaration() { return this; }
}

class SharedStaticDtorDeclaration : StaticDtorDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, "_sharedStaticDtor");
   }

   Dsymbol syntaxCopy(Dsymbol s)
   {
      assert(!s);
      SharedStaticDtorDeclaration sdd = new SharedStaticDtorDeclaration(loc, endloc);
      return FuncDeclaration.syntaxCopy(sdd);
   }

   void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (!hgs.hdrgen)
      {
         buf.put("shared ");
         StaticDtorDeclaration.toCBuffer(buf, hgs);
      }
   }

   SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return this; }
}

class UnitTestDeclaration : FuncDeclaration
{
   this(Loc loc, Loc endloc)
   {
      super(loc, endloc, unitTestId(), STCundefined, null);
   }

   override Dsymbol syntaxCopy(Dsymbol s)
   {
      UnitTestDeclaration utd;

      assert(!s);
      utd = new UnitTestDeclaration(loc, endloc);

      return FuncDeclaration.syntaxCopy(utd);
   }


   override AggregateDeclaration isThis()
   {
      return null;
   }

   override bool isVirtual()
   {
      return false;
   }

   override bool addPreInvariant()
   {
      return false;
   }

   override bool addPostInvariant()
   {
      return false;
   }

   override void toCBuffer(ref Appender!(char[]) buf, ref HdrGenState hgs)
   {
      if (hgs.hdrgen)
         return;
      buf.put("unittest");
      buf.put(hgs.nL);
      bodyToCBuffer(buf, hgs);
      buf.put(hgs.nL);
   }

   override UnitTestDeclaration isUnitTestDeclaration() { return this; }
}
