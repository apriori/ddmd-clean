module dmd.parser;

import dmd.lexer;

import dmd.global;
import dmd.attribDeclaration;
import dmd.declaration;
import dmd.varDeclaration;
import dmd.expression;
import dmd.unaExp;
import dmd.binExp;
import dmd.funcDeclaration;
import dmd.Module;
import dmd.templateParameter;
import dmd.scopeDsymbol;
import dmd.statement;
import dmd.condition;
import dmd.baseClass;
import dmd.Catch;
import dmd.parameter;
import dmd.dsymbol;
import dmd.identifier;
import dmd.initializer;
import dmd.type;
import dmd.token;

import std.exception;
import std.conv; 
import std.array;

alias int ParseStatementFlags;
enum 
{
    PSsemi = 1,		// empty ';' statements are allowed
    PSscope = 2,	// start a new scope
    PScurly = 4,	// { } statement is required
    PScurlyscope = 8,	// { } starts a new scope
}

version (unittest)
{
    import std.file, std.stdio;
    import std.variant;
    Lexer lex;
    alias lex luthor;
    Variant lois;
    alias lois lane; // Gotta have a little fun I guess
    Parser pete;
    alias pete parker;
    static int hits = 0;
}

unittest
{
   version(none)
   {
      Module m = new Module("YuppiesName", new Identifier("YuppiesIdent",TOKidentifier), 0, 0);

      auto srcfilebuf = readText!(char[])("./zddmd/dmd/Parser.d");
      //auto srcfilebuf = readText!(char[])("../test.d");
      //char[] srcfilebuf = ` `.dup;

      pete = new Parser( m, srcfilebuf, /+comments:yes+/ 1 );
      /+ /
         writeln("Input: \"", srcfilebuf,"\", Token: ", pete.token.toChars(), " Line: ", __LINE__);

      auto steve = pete.parseStatement(0);
      writeln("Result: \"", "steve was a", steve, "\"" ); 
      writeln("Result: \"", steve.toChars(),"\"" ); 
      // +/
      m.members = pete.parseModule();
      m.md = pete.md;
      auto spitIt = m.toChars();

      auto outbuf = File("ParserTrashyTrashyTrash.d","w");
      outbuf.write( spitIt );
      outbuf.close();
   }
}

class Parser : Lexer
{
   ModuleDeclaration md;
   Module mod;
   LINK linkage;
   Loc endloc;			// set to location of last right curly
   int inBrackets;		// inside [] of array index or slice

   this( in char[] srcbuf )
   {
      mod = new Module("DParser", new Identifier("DParser",TOKidentifier), false/+doDocComment+/, false/+doHdrGen+/);
      super("DParser", srcbuf, 0/+start offset+/, false/+doDocComment+/, 
            0/+commentToken+/
            );
   }

   this(Module module_, in char[] srcbuf, bool doDocComment)
   {
      super(module_.srcfilename, srcbuf, 0/+start offset+/, 
            false/+doDocComment+/, 0/+commentToken+/
            );
      linkage = LINKd;
      this.mod = module_;
   }

   // I'll probably need to add some location info to this function
   void setModule( Module m )
   {
      this.mod = m;
   }

   // In dmd it returns Dsymbol[], but I wanted to make
   // it logically consistent with itself!
   Module parseModule()
   {
      // Right now the program is ascii only
      // but here's where you would convert other formats
      // to ascii e.g.:
      version(none)
      {
         testAndConvertBOMtoAscii( srcbuf );
      }
      // Handle the hashbang situation
      mod.hashBang = scanForHashBang();
      nextToken();

      // ModuleDeclaration leads off
      if (token.value == TOKmodule)
      {
         string comment = token.blockComment;
         bool safe = false;

         nextToken();
         // I think you can erase this
         version(none) 
         { 
            if (token.value == TOKlparen)
            {
               nextToken();
               if (token.value != TOKidentifier)
               {
                  error("module (system) identifier expected");
                  goto Lerr;
               }
               Identifier id = token.ident;

               if (id is Id.system)
                  safe = true;
               else
                  error("(safe) expected, not %s", id.toChars());
               nextToken();
               check(TOKrparen);
            }
         }

         if (token.value != TOKidentifier)
         {
            error("Identifier expected following module");
            goto Lerr;
         }
         else
         {
            Identifier[] a;
            Identifier id = token.ident;
            while (nextToken() == TOKdot)
            {
               a ~= (id);
               nextToken();
               if (token.value != TOKidentifier)
               {   error("Identifier expected following package");
                  goto Lerr;
               }
               id = token.ident;
            }

            md = new ModuleDeclaration(a, id, safe);

            if (token.value != TOKsemicolon)
               error("';' expected following module declaration instead of %s", token.toChars());

            nextToken();
            addComment(mod, comment);
         }
      }

      Dsymbol[] decldefs = parseDeclDefs(0);
      
      if (token.value != TOKeof)
      {
         error("unrecognized declaration");
         goto Lerr;
      }

      mod.md = this.md;
      mod.members = decldefs;
      return mod;

   Lerr:
      while (token.value != TOKsemicolon && token.value != TOKeof)
         nextToken();

      nextToken();
      return null;
   }

   Dsymbol[] parseDeclDefs(int once)
   {
      Dsymbol s;
      Dsymbol[] decldefs;
      Dsymbol[] a;
      Dsymbol[] aelse;
      PROT prot;
      StorageClass stc;
      StorageClass storageClass;
      Condition  condition;
      string comment;

      //printf("Parser.parseDeclDefs()\n");
      do
      {
         comment = token.blockComment;
         storageClass = STCundefined;
         switch (token.value)
         {
            case TOKenum:
               {	/* Determine if this is a manifest constant declaration,
                   * or a conventional enum.
                   */
                  Token* t = peek(&token);
                  if (t.value == TOKlcurly || t.value == TOKcolon)
                     s = parseEnum();
                  else if (t.value != TOKidentifier)
                     goto Ldeclaration;
                  else
                  {
                     t = peek(t);
                     if (t.value == TOKlcurly || t.value == TOKcolon ||
                           t.value == TOKsemicolon)
                        s = parseEnum();
                     else
                        goto Ldeclaration;
                  }
                  break;
               }

            case TOKstruct:
            case TOKunion:
            case TOKclass:
            case TOKinterface:
               s = parseAggregate();
               break;

            case TOKimport:
               s = parseImport(decldefs, 0);
               break;

            case TOKtemplate:
               s = cast(Dsymbol)parseTemplateDeclaration();
               break;

            case TOKmixin:
               {	
                  Loc loc = this.loc;
                  if (peek(&token).value == TOKlparen)
                  {   // mixin(string)
                     nextToken();
                     check(TOKlparen, "mixin");
                     Expression e = parseAssignExp();
                     check(TOKrparen);
                     check(TOKsemicolon);
                     s = new CompileDeclaration(loc, e);
                     break;
                  }
                  s = parseMixin();
                  break;
               }

            case TOKwchar: case TOKdchar:
            case TOKbit: case TOKbool: case TOKchar:
            case TOKint8: case TOKuns8:
            case TOKint16: case TOKuns16:
            case TOKint32: case TOKuns32:
            case TOKint64: case TOKuns64:
            case TOKfloat32: case TOKfloat64: case TOKfloat80:
            case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:
            case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:
            case TOKvoid:
            case TOKalias:
            case TOKtypedef:
            case TOKidentifier:
            case TOKtypeof:
            case TOKdot:
Ldeclaration:
               a = parseDeclarations(STCundefined);
               decldefs ~= a;
               continue;

            case TOKthis:
               s = parseCtor();
               break;

               static if (false) { // dead end, use this(this){} instead
                  case TOKassign:
                     s = parsePostBlit();
                     break;
               }
            case TOKtilde:
               s = parseDtor();
               break;

            case TOKinvariant:
               {	Token* t;
                  t = peek(&token);
                  if (t.value == TOKlparen)
                  {
                     if (peek(t).value == TOKrparen)
                        // invariant() forms start of class invariant
                        s = parseInvariant();
                     else
                        // invariant(type)
                        goto Ldeclaration;
                  }
                  else
                  {
                     stc = STCimmutable;
                     goto Lstc;
                  }
                  break;
               }

            case TOKunittest:
               s = parseUnitTest();
               break;

            case TOKnew:
               s = parseNew();
               break;

            case TOKdelete:
               s = parseDelete();
               break;

            case TOKeof:
            case TOKrcurly:
               return decldefs;

            case TOKstatic:
               nextToken();
               if (token.value == TOKthis)
                  s = parseStaticCtor();
               else if (token.value == TOKtilde)
                  s = parseStaticDtor();
               else if (token.value == TOKassert)
                  s = parseStaticAssert();
               else if (token.value == TOKif)
               {   
                  condition = parseStaticIfCondition();
                  a = parseBlock();
                  aelse = null;
                  if (token.value == TOKelse)
                  {   nextToken();
                     aelse = parseBlock();
                  }
                  s = new StaticIfDeclaration(condition, a, aelse);
                  break;
               }
               else if (token.value == TOKimport)
               {
                  s = parseImport(decldefs, 1);
               }
               else
               {   stc = STCstatic;
                  goto Lstc2;
               }
               break;

            case TOKconst:
               if (peekNext() == TOKlparen)
                  goto Ldeclaration;
               stc = STCconst;
               goto Lstc;

            case TOKimmutable:
               if (peekNext() == TOKlparen)
                  goto Ldeclaration;
               stc = STCimmutable;
               goto Lstc;

            case TOKshared:
               {
                  TOK next = peekNext();
                  if (next == TOKlparen)
                     goto Ldeclaration;
                  if (next == TOKstatic)
                  {   
                     TOK next2 = peekNext2();
                     if (next2 == TOKthis)
                     {	
                        s = parseSharedStaticCtor();
                        break;
                     }
                     if (next2 == TOKtilde)
                     {	
                        s = parseSharedStaticDtor();
                        break;
                     }
                    }
                    stc = STCshared;
                    goto Lstc;
                }

            case TOKwild:
                if (peekNext() == TOKlparen)
                    goto Ldeclaration;
                stc = STCwild;
                goto Lstc;

            case TOKfinal:	  stc = STCfinal;	 goto Lstc;
            case TOKauto:	  stc = STCauto;	 goto Lstc;
            case TOKscope:	  stc = STCscope;	 goto Lstc;
            case TOKoverride:	  stc = STCoverride;	 goto Lstc;
            case TOKabstract:	  stc = STCabstract;	 goto Lstc;
            case TOKsynchronized: stc = STCsynchronized; goto Lstc;
            case TOKdeprecated:   stc = STCdeprecated;	 goto Lstc;
            case TOKnothrow:      stc = STCnothrow;	 goto Lstc;
            case TOKpure:         stc = STCpure;	 goto Lstc;
            case TOKref:          stc = STCref;          goto Lstc;
            case TOKtls:          stc = STCtls;		 goto Lstc;
            case TOKgshared:      stc = STCgshared;	 goto Lstc;
			   //case TOKmanifest:	  stc = STCmanifest;	 goto Lstc;
            case TOKat:           stc = parseAttribute(); goto Lstc;

         Lstc:
			   if (storageClass & stc)
                error("redundant storage class %s", Token.toChars(token.value));
			   composeStorageClass(storageClass | stc);
            nextToken();
			Lstc2:
            storageClass |= stc;
            switch (token.value)
            {
                case TOKconst:
                case TOKinvariant:
                case TOKimmutable:
                case TOKshared:
                case TOKwild:
                    // If followed by a (, it is not a storage class
                    if (peek(&token).value == TOKlparen)
                        break;
                    if (token.value == TOKconst)
                        stc = STCconst;
                    else if (token.value == TOKshared)
                        stc = STCshared;
                    else if (token.value == TOKwild)
                        stc = STCwild;
                    else
                        stc = STCimmutable;
                    goto Lstc;
                case TOKfinal:	  stc = STCfinal;	 goto Lstc;
                case TOKauto:	  stc = STCauto;	 goto Lstc;
                case TOKscope:	  stc = STCscope;	 goto Lstc;
                case TOKoverride:	  stc = STCoverride;	 goto Lstc;
                case TOKabstract:	  stc = STCabstract;	 goto Lstc;
                case TOKsynchronized: stc = STCsynchronized; goto Lstc;
                case TOKdeprecated:   stc = STCdeprecated;	 goto Lstc;
                case TOKnothrow:      stc = STCnothrow;	 goto Lstc;
                case TOKpure:         stc = STCpure;	 goto Lstc;
                case TOKref:          stc = STCref;          goto Lstc;
                case TOKtls:          stc = STCtls;		 goto Lstc;
                case TOKgshared:      stc = STCgshared;	 goto Lstc;
                case TOKat:           stc = parseAttribute(); goto Lstc;
                default:
				        break;
            }

            /* Look for auto initializers:
             *	storage_class identifier = initializer;
             */
            if (token.value == TOKidentifier &&
				peek(&token).value == TOKassign)
            {
                a = parseAutoDeclarations(storageClass, comment);
                decldefs ~= (a);
                continue;
            }

            /* Look for return type inference for template functions.
             */
            Token* tk;
            if (
                token.value == TOKidentifier &&
                ( tk = peek(&token) ).value == TOKlparen &&
                skipParens(tk) &&
                ((tk = peek(tk)), 1) &&
                skipAttributes(tk) &&
                (tk.value == TOKlparen ||
                 tk.value == TOKlcurly)
               )
            {
                a = parseDeclarations(storageClass);
                decldefs ~= (a);
                continue;
            }
            a = parseBlock();
            s = new StorageClassDeclaration(storageClass, a);
            break;

            case TOKextern:
            if (peek(&token).value != TOKlparen)
            {   
                stc = STCextern;
                goto Lstc;
				}

				{
                LINK linksave = linkage;
                linkage = parseLinkage();
                a = parseBlock();
                s = new LinkDeclaration(linkage, a);
                linkage = linksave;
                break;
				}

            case TOKprivate:	prot = PROTprivate;	goto Lprot;
            case TOKpackage:	prot = PROTpackage;	goto Lprot;
            case TOKprotected:	prot = PROTprotected;	goto Lprot;
            case TOKpublic:		prot = PROTpublic;		goto Lprot;
            case TOKexport:		prot = PROTexport;		goto Lprot;
        Lprot:
				nextToken();
				switch (token.value)
				{
                case TOKprivate:
                case TOKpackage:
                case TOKprotected:
                case TOKpublic:
                case TOKexport:
                    error("redundant protection attribute");
                    break;
                default:
                    break;
            }
            a = parseBlock();
            s = new ProtDeclaration(prot, a);
            break;

            case TOKalign:
            {	
                uint n;
                s = null;
                nextToken();
                if (token.value == TOKlparen)
                {
                    nextToken();
                    if (token.value == TOKint32v)
                        n = cast(uint)token.uns64value;
                    else
                    {	error("integer expected, not %s", token.toChars());
                        n = 1;
                    }
                    nextToken();
                    check(TOKrparen);
                }
                else
                    n = global.structalign;		// default

                a = parseBlock();
                s = new AlignDeclaration(n, a);
                break;
            }

            case TOKpragma:
            {	
                Identifier ident;
                Expression[] args;

                nextToken();
                check(TOKlparen);
                if (token.value != TOKidentifier)
                {   error("pragma(identifier expected");
                    goto Lerror;
                }
                ident = token.ident;
                nextToken();
                if (token.value == TOKcomma && peekNext() != TOKrparen)
                    args = parseArguments();	// pragma(identifier, args...)
                else
                    check(TOKrparen);		// pragma(identifier)

                if (token.value == TOKsemicolon)
                    a = null;
                else
                    a = parseBlock();
                s = new PragmaDeclaration(loc, ident, args, a);
                break;
            }

            case TOKdebug:
            nextToken();
            if (token.value == TOKassign)
            {
                nextToken();
                if (token.value == TOKidentifier)
                    s = new DebugSymbol(loc, token.ident);
                else if (token.value == TOKint32v)
                    s = new DebugSymbol(loc, cast(uint)token.uns64value);
                else
                {	error("identifier or integer expected, not %s", token.toChars());
                    s = null;
                }
                nextToken();
                if (token.value != TOKsemicolon)
                    error("semicolon expected");
                nextToken();
                break;
            }

            condition = parseDebugCondition();
            goto Lcondition;

            case TOKversion:
            nextToken();
            if (token.value == TOKassign)
            {
                nextToken();
                if (token.value == TOKidentifier)
                    s = new VersionSymbol(loc, token.ident);
                else if (token.value == TOKint32v)
                    s = new VersionSymbol(loc, cast(uint)token.uns64value);
                else
                {	error("identifier or integer expected, not %s", token.toChars());
                    s = null;
                }
                nextToken();
                if (token.value != TOKsemicolon)
                    error("semicolon expected");
                nextToken();
                break;
            }
            condition = parseVersionCondition();
            goto Lcondition;

        Lcondition:
            a = parseBlock();
            aelse = null;
            if (token.value == TOKelse)
            {   nextToken();
                aelse = parseBlock();
            }
            s = new ConditionalDeclaration(condition, a, aelse);
            break;

            case TOKsemicolon:		// empty declaration
            nextToken();
            continue;

            default:
            error("Declaration expected, not '%s'",token.toChars());
        Lerror:
            while (token.value != TOKsemicolon && token.value != TOKeof)
                nextToken();
            nextToken();
            s = null;
            continue;
         }

         if (s)
         {   
            decldefs ~= (s);
            addComment(s, comment);
         }

         // end of main loop
      } while (!once);
      return decldefs;
   }

   /*****************************************
    * Parse auto declarations of the form:
    *   storageClass ident = init, ident = init, ... ;
    * and return the array of them.
    * Starts with token on the first ident.
    * Ends with scanner past closing ';'
    */
   Dsymbol[] parseAutoDeclarations(StorageClass storageClass, string comment)
   {
      Dsymbol[] a;

      while (true)
      {
         Identifier ident = token.ident;
         nextToken();		// skip over ident
         assert(token.value == TOKassign);
            nextToken();		// skip over '='
            Initializer init = parseInitializer();
            auto v = new VarDeclaration(loc, null, ident, init);
            v.storage_class = storageClass;
            a ~= (v);
            if (token.value == TOKsemicolon)
            {
                nextToken();
                addComment(v, comment);
            }
            else if (token.value == TOKcomma)
            {
                nextToken();
                if (token.value == TOKidentifier &&
                        peek(&token).value == TOKassign)
                {
                    addComment(v, comment);
                    continue;
                }
                else
                    error("Identifier expected following comma");
            }
            else
                error("semicolon expected following auto declaration, not '%s'", token.toChars());
            break;
        }
        return a;
    }
    /********************************************
     * Parse declarations after an align, protection, or extern decl.
     */
    Dsymbol[] parseBlock()
    {
        Dsymbol[] a = null;
        Dsymbol ss;

        //printf("parseBlock()\n");
		switch (token.value)
		{
		case TOKsemicolon:
			error("declaration expected following attribute, not ';'");
			nextToken();
			break;

		case TOKeof:
			error("declaration expected following attribute, not EOF");
			break;

		case TOKlcurly:
			nextToken();
			a = parseDeclDefs(0);
			if (token.value != TOKrcurly)
			{   /*  */
				error("matching '}' expected, not %s", token.toChars());
			}
			else
				nextToken();
			break;

		case TOKcolon:
			nextToken();
			a = parseDeclDefs(0);	// grab declarations up to closing curly bracket
			break;

		default:
			a = parseDeclDefs(1);
			break;
		}
		return a;
	}

    void composeStorageClass(StorageClass stc)
	{
		StorageClass u = stc;
		u &= STCconst | STCimmutable | STCmanifest;
		if (u & (u - 1))
			error("conflicting storage class %s", Token.toChars(token.value));

		u = stc;
		u &= STCgshared | STCshared | STCtls;
		if (u & (u - 1))
			error("conflicting storage class %s", Token.toChars(token.value));
        u = stc;
        u &= STCsafe | STCsystem | STCtrusted;
        if (u & (u - 1))
	        error("conflicting attribute @%s", token.toChars());
	}
    
/***********************************************
 * Parse storage class, lexer is on '@'
 */

    StorageClass parseAttribute()
    {
        nextToken();
        StorageClass stc = STCundefined;
        if (token.value != TOKidentifier)
        {
	        error("identifier expected after @, not %s", token.toChars());
        }
        else if (token.ident == Id.property)
	        stc = STCproperty;
        else if (token.ident == Id.safe)
	        stc = STCsafe;
        else if (token.ident == Id.trusted)
	        stc = STCtrusted;
        else if (token.ident == Id.system)
	        stc = STCsystem;
        else if (token.ident == Id.disable)
			stc = STCdisable;
		else
			error("valid attribute identifiers are @property, @safe, @trusted, @system, @disable not @%s", token.toChars());

        return stc;
    }
	/**************************************
	 * Parse constraint.
	 * Constraint is of the form:
	 *	if ( ConstraintExpression )
	 */
    Expression parseConstraint()
	{
		Expression e = null;

		if (token.value == TOKif)
		{
			nextToken();	// skip over 'if'
			check(TOKlparen);
			e = parseExpression();
			check(TOKrparen);
		}
		return e;
	}
	/**************************************
	 * Parse a TemplateDeclaration.
	 */
    TemplateDeclaration parseTemplateDeclaration()
	{
		TemplateDeclaration tempdecl;
		Identifier id;
		TemplateParameter[] tpl;
		Dsymbol[] decldefs;
		Expression constraint = null;
		Loc loc = this.loc;

		nextToken();
		if (token.value != TOKidentifier)
		{   
			error("TemplateIdentifier expected following template");
			goto Lerr;
		}
		id = token.ident;
		nextToken();
		tpl = parseTemplateParameterList();
		if (!tpl)
			goto Lerr;

		constraint = parseConstraint();

		if (token.value != TOKlcurly)
		{	
			error("members of template declaration expected");
			goto Lerr;
		}
		else
		{
			nextToken();
			decldefs = parseDeclDefs(0);
			if (token.value != TOKrcurly)
			{   
				error("template member expected");
				goto Lerr;
			}
			nextToken();
		}

		tempdecl = new TemplateDeclaration(loc, id, tpl, constraint, decldefs);
		return tempdecl;

	Lerr:
		return null;
	}
	
	/******************************************
	 * Parse template parameter list.
	 * Input:
	 *	flag	0: parsing "( list )"
	 *		1: parsing non-empty "list )"
	 */
    TemplateParameter[] parseTemplateParameterList(int flag = 0)
	{
		TemplateParameter[] tpl = [];

		if (!flag && token.value != TOKlparen)
		{   
			error("parenthesized TemplateParameterList expected following TemplateIdentifier");
			goto Lerr;
		}
		nextToken();

		// Get array of TemplateParameters
		if (flag || token.value != TOKrparen)
		{	
			int isvariadic = 0;

			while (true)
			{   
				TemplateParameter tp;
				Identifier tp_ident = null;
				Type tp_spectype = null;
				Type tp_valtype = null;
				Type tp_defaulttype = null;
				Expression tp_specvalue = null;
				Expression tp_defaultvalue = null;
				Token* t;

				// Get TemplateParameter

				// First, look ahead to see if it is a TypeParameter or a ValueParameter
				t = peek(&token);
				if (token.value == TOKalias)
				{	
					// AliasParameter
					nextToken();
					Type spectype = null;
					if (isDeclaration(&token, 2, TOKreserved, false))
					{
						spectype = parseType(&tp_ident);
					}
					else
					{
						if (token.value != TOKidentifier)
						{
							error("identifier expected for template alias parameter");
							goto Lerr;
						}
						tp_ident = token.ident;
						nextToken();
					}
					Dobject spec = null;
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						if (isDeclaration(&token, 0, TOKreserved, false))
							spec = parseType();
						else
						spec = parseCondExp();
					}
					Dobject def = null;
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						if (isDeclaration(&token, 0, TOKreserved, false))
							def = parseType();
						else
							def = parseCondExp();
					}
					tp = new TemplateAliasParameter(loc, tp_ident, spectype, spec, def);
				}
				else if (t.value == TOKcolon || t.value == TOKassign ||
					 t.value == TOKcomma || t.value == TOKrparen)
				{	// TypeParameter
					if (token.value != TOKidentifier)
					{   error("identifier expected for template type parameter");
						goto Lerr;
					}
					tp_ident = token.ident;
					nextToken();
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						tp_spectype = parseType();
					}
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						tp_defaulttype = parseType();
					}
					tp = new TemplateTypeParameter(loc, tp_ident, tp_spectype, tp_defaulttype);
				}
				else if (token.value == TOKidentifier && t.value == TOKdotdotdot)
				{	// ident...
					if (isvariadic)
						error("variadic template parameter must be last");
					isvariadic = 1;
					tp_ident = token.ident;
					nextToken();
					nextToken();
					tp = new TemplateTupleParameter(loc, tp_ident);
				}

				else if (token.value == TOKthis)
				{	// ThisParameter
					nextToken();
					if (token.value != TOKidentifier)
					{   error("identifier expected for template this parameter");
						goto Lerr;
					}
					tp_ident = token.ident;
					nextToken();
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						tp_spectype = parseType();
					}
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						tp_defaulttype = parseType();
					}
					tp = new TemplateThisParameter(loc, tp_ident, tp_spectype, tp_defaulttype);
				}
				else
				{	// ValueParameter
					tp_valtype = parseType(&tp_ident);
					if (!tp_ident)
					{
						error("identifier expected for template value parameter");
						tp_ident = new Identifier("error", TOKidentifier);
					}
					if (token.value == TOKcolon)	// : CondExpression
					{
						nextToken();
						tp_specvalue = parseCondExp();
					}
					if (token.value == TOKassign)	// = CondExpression
					{
						nextToken();
						tp_defaultvalue = parseDefaultInitExp();
					}
					tp = new TemplateValueParameter(loc, tp_ident, tp_valtype, tp_specvalue, tp_defaultvalue);
				}
				tpl ~= (tp);
				if (token.value != TOKcomma)
					break;
				nextToken();
			}
		}
		check(TOKrparen);

	Lerr:
		return tpl;
	}

/******************************************
 * Parse template mixin.
 *	mixin Foo;
 *	mixin Foo!(args);
 *	mixin a.b.c!(args).Foo!(args);
 *	mixin Foo!(args) identifier;
 *	mixin typeof(expr).identifier!(args);
 */

    Dsymbol parseMixin()
	{
		TemplateMixin tm;
		Identifier id;
		Type tqual;
		Dobject[] tiargs;
		Identifier[] idents;

		//printf("parseMixin()\n");
		nextToken();
		tqual = null;
		if (token.value == TOKdot)
		{
			id = Id.empty;
		}
		else
		{
			if (token.value == TOKtypeof)
			{
				tqual = parseTypeof();
				check(TOKdot);
			}
			if (token.value != TOKidentifier)
			{
				error("identifier expected, not %s", token.toChars());
				id = Id.empty;
			}
			else
				id = token.ident;
			nextToken();
		}

		while (1)
		{
			tiargs = null;
			if (token.value == TOKnot)
			{
				nextToken();
				if (token.value == TOKlparen)
					tiargs = parseTemplateArgumentList();
				else
					tiargs = parseTemplateArgument();
			}
			if (token.value != TOKdot)
				break;
			if (tiargs)
			{   
				TemplateInstance tempinst = new TemplateInstance(loc, id);
				tempinst.tiargs = tiargs;
				id = tempinst.ident;
				tiargs = null;
			}
			idents ~= id;
			nextToken();
			if (token.value != TOKidentifier)
			{   
				error("identifier expected following '.' instead of '%s'", token.toChars());
				break;
			}
			id = token.ident;
			nextToken();
		}
		idents ~= id;
		if (token.value == TOKidentifier)
		{
			id = token.ident;
			nextToken();
		}
		else
			id = null;

		tm = new TemplateMixin(loc, id, tqual, idents, tiargs);
		if (token.value != TOKsemicolon)
			error("';' expected after mixin");
		nextToken();
		return tm;
	}
	
	/******************************************
	 * Parse template argument list.
	 * Input:
	 * 	current token is opening '('
	 * Output:
	 *	current token is one after closing ')'
	 */
    Dobject[] parseTemplateArgumentList()
	{
		//printf("Parser.parseTemplateArgumentList()\n");
		if (token.value != TOKlparen && token.value != TOKlcurly)
		{   
			error("!(TemplateArgumentList) expected following TemplateIdentifier");
			return null;
		}
		return parseTemplateArgumentList2();
	}
	
    Dobject[] parseTemplateArgumentList2()
	{
		//printf("Parser.parseTemplateArgumentList2()\n");
		Dobject[] tiargs;
		TOK endtok = TOKrparen;
		nextToken();

		// Get TemplateArgumentList
		if (token.value != endtok)
		{
			while (1)
			{
				// See if it is an Expression or a Type
				if (isDeclaration(&token, 0, TOKreserved, false))
				{	// Template argument is a type
					Type ta = parseType();
					tiargs ~= (ta);
				}
				else
				{	// Template argument is an expression
					Expression ea = parseAssignExp();

					if (ea.op == TOKfunction)
					{   
						FuncLiteralDeclaration fd = (cast(FuncExp)ea).fd;
						if (fd.type.ty == Tfunction)
						{
							TypeFunction tf = cast(TypeFunction)fd.type;
							/* If there are parameters that consist of only an identifier,
							 * rather than assuming the identifier is a type, as we would
							 * for regular function declarations, assume the identifier
							 * is the parameter name, and we're building a template with
							 * a deduced type.
							 */
							TemplateParameter[] tpl;
							foreach (param; tf.parameters)
							{   
								if (param.ident is null &&
									param.type &&
									param.type.ty == Tident &&
									(cast(TypeIdentifier)param.type).idents.length == 0
								   )
								{
									/* Switch parameter type to parameter identifier,
									 * parameterize with template type parameter _T
									 */
									auto pt = cast(TypeIdentifier)param.type;
									param.ident = pt.ident;
									Identifier id = Identifier.uniqueId("__T");
									param.type = new TypeIdentifier(pt.loc, id);
									auto tp = new TemplateTypeParameter(fd.loc, id, null, null);
									tpl ~= (tp);
								}
							}

							if (tpl)
							{   
								// Wrap a template around function fd
								Dsymbol[] decldefs;
								decldefs ~= (fd);
								auto tempdecl = new TemplateDeclaration(fd.loc, fd.ident, tpl, null, decldefs);
								tempdecl.literal = 1;	// it's a template 'literal'
								tiargs ~= (tempdecl);
								goto L1;
							}
						}
					}

					tiargs ~= (ea);
				}
			 L1:
				if (token.value != TOKcomma)
					break;
				nextToken();
			}
		}
		check(endtok, "template argument list");
		return tiargs;
	}
	
	/*****************************
	 * Parse single template argument, to support the syntax:
	 *	foo!arg
	 * Input:
	 *	current token is the arg
	 */
    Dobject[] parseTemplateArgument()
	{
		//printf("parseTemplateArgument()\n");
		Dobject[] tiargs;
		Type ta;
		switch (token.value)
		{
			case TOKidentifier:
				ta = new TypeIdentifier(loc, token.ident);
				goto LabelX;

			case TOKvoid:	 ta = Type.tvoid;  goto LabelX;
			case TOKint8:	 ta = Type.tint8;  goto LabelX;
			case TOKuns8:	 ta = Type.tuns8;  goto LabelX;
			case TOKint16:	 ta = Type.tint16; goto LabelX;
			case TOKuns16:	 ta = Type.tuns16; goto LabelX;
			case TOKint32:	 ta = Type.tint32; goto LabelX;
			case TOKuns32:	 ta = Type.tuns32; goto LabelX;
			case TOKint64:	 ta = Type.tint64; goto LabelX;
			case TOKuns64:	 ta = Type.tuns64; goto LabelX;
			case TOKfloat32: ta = Type.tfloat32; goto LabelX;
			case TOKfloat64: ta = Type.tfloat64; goto LabelX;
			case TOKfloat80: ta = Type.tfloat80; goto LabelX;
			case TOKimaginary32: ta = Type.timaginary32; goto LabelX;
			case TOKimaginary64: ta = Type.timaginary64; goto LabelX;
			case TOKimaginary80: ta = Type.timaginary80; goto LabelX;
			case TOKcomplex32: ta = Type.tcomplex32; goto LabelX;
			case TOKcomplex64: ta = Type.tcomplex64; goto LabelX;
			case TOKcomplex80: ta = Type.tcomplex80; goto LabelX;
			case TOKbit:	 ta = Type.tbit;     goto LabelX;
			case TOKbool:	 ta = Type.tbool;    goto LabelX;
			case TOKchar:	 ta = Type.tchar;    goto LabelX;
			case TOKwchar:	 ta = Type.twchar; goto LabelX;
			case TOKdchar:	 ta = Type.tdchar; goto LabelX;
			LabelX:
				tiargs ~= (ta);
				nextToken();
				break;

			case TOKint32v:
			case TOKuns32v:
			case TOKint64v:
			case TOKuns64v:
			case TOKfloat32v:
			case TOKfloat64v:
			case TOKfloat80v:
			case TOKimaginary32v:
			case TOKimaginary64v:
			case TOKimaginary80v:
			case TOKnull:
			case TOKtrue:
			case TOKfalse:
			case TOKcharv:
			case TOKwcharv:
			case TOKdcharv:
			case TOKstring:
			case TOKfile:
			case TOKline:
			{   
				// Template argument is an expression
				Expression ea = parsePrimaryExp();
				tiargs ~= (ea);
				break;
			}

			default:
				error("template argument expected following !");
				break;
		}

		if (token.value == TOKnot)
			error("multiple ! arguments are not allowed");
		return tiargs;
	}
	
	/**********************************
	 * Parse a static assertion.
	 */
    StaticAssert parseStaticAssert()
	{
		Loc loc = this.loc;
		Expression exp;
		Expression msg = null;

		//printf("parseStaticAssert()\n");
		nextToken();
		check(TOKlparen);
		exp = parseAssignExp();
		if (token.value == TOKcomma)
		{	
			nextToken();
			msg = parseAssignExp();
		}

		check(TOKrparen);
		check(TOKsemicolon);
	
		return new StaticAssert(loc, exp, msg);
	}
	
    TypeQualified parseTypeof()
	{
		TypeQualified t;
		Loc loc = this.loc;

		nextToken();
		check(TOKlparen);
		if (token.value == TOKreturn)	// typeof(return)
		{
			nextToken();
			t = new TypeReturn(loc);
		}
		else
		{	
			Expression exp = parseExpression();	// typeof(expression)
			t = new TypeTypeof(loc, exp);
		}
		check(TOKrparen);
		return t;
	}
	
	/***********************************
	 * Parse extern (linkage)
	 * The parser is on the 'extern' token.
	 */
    LINK parseLinkage()
	{
		LINK link = LINKdefault;
		nextToken();
		assert(token.value == TOKlparen);
		nextToken();
		if (token.value == TOKidentifier)
		{   
			Identifier id = token.ident;

			nextToken();
			if (id == Id.Windows)
				link = LINKwindows;
			else if (id == Id.Pascal)
				link = LINKpascal;
			else if (id == Id.D)
				link = LINKd;
			else if (id == Id.C)
			{
				link = LINKc;
				if (token.value == TOKplusplus)
				{   
					link = LINKcpp;
					nextToken();
				}
			}
			else if (id == Id.System)
			{
             version (Windows) link = LINKwindows;
             else link = LINKc;
			}
			else
			{
				error("valid linkage identifiers are D, C, C++, Pascal, Windows, System");
				link = LINKd;
			}
		}
		else
		{
			link = LINKd;		// default
		}
		check(TOKrparen);

		return link;
	}


	/**************************************
	 * Parse a debug conditional
	 */	
    Condition parseDebugCondition()
	{
		Condition c;

		if (token.value == TOKlparen)
		{
			nextToken();
			uint level = 1;
			Identifier id = null;

			if (token.value == TOKidentifier)
				id = token.ident;
			else if (token.value == TOKint32v)
				level = cast(uint)token.uns64value;
			else
				error("identifier or integer expected, not %s", token.toChars());

			nextToken();
			check(TOKrparen);

			c = new DebugCondition(mod, level, id);
		}
		else
			c = new DebugCondition(mod, 1, null);

		return c;
	}
	
	/**************************************
	 * Parse a version conditional
	 */
    Condition parseVersionCondition()
	{
		Condition c;
		uint level = 1;
		Identifier id = null;

		if (token.value == TOKlparen)
		{
			nextToken();
			if (token.value == TOKidentifier)
				id = token.ident;
			else if (token.value == TOKint32v)
				level = to!uint(token.uns64value);
			else {
				/* Allow:
				 *    version (unittest)
				 * even though unittest is a keyword
				 */
				if (token.value == TOKunittest)
					id = Identifier.idPool(Token.toChars(TOKunittest));
				else
					error("identifier or integer expected, not %s", token.toChars());
			}
			nextToken();
			check(TOKrparen);
		}
		else
		   error("(condition) expected following version");

		c = new VersionCondition(mod, level, id);

		return c;
	}

	/***********************************************
	 *	static if (expression)
	 *	    body
	 *	else
	 *	    body
	 */
    Condition parseStaticIfCondition()
	{
		Expression exp;
		Condition condition;
		//???? Array aif;
		//???? Array aelse;
		Loc loc = this.loc;

		nextToken();
		if (token.value == TOKlparen)
		{
			nextToken();
			exp = parseAssignExp();
			check(TOKrparen);
		}
		else
		{   
			error("(expression) expected following static if");
			exp = null;
		}
		condition = new StaticIfCondition(loc, exp);
		return condition;
	}
	
	/*****************************************
	 * Parse a constructor definition:
	 *	this(parameters) { body }
	 * or postblit:
	 *	this(this) { body }
	 * or constructor template:
	 *	this(templateparameters)(parameters) { body }
	 * Current token is 'this'.
	 */
	
    Dsymbol parseCtor()
	{
		Loc loc = this.loc;

		nextToken();
		if (token.value == TOKlparen && peek(&token).value == TOKthis)
		{	// this(this) { ... }
			nextToken();
			nextToken();
			check(TOKrparen);
			auto f = new PostBlitDeclaration(loc, Loc(0));
			parseContracts(f);
			return f;
		}

		/* Look ahead to see if:
		 *   this(...)(...)
		 * which is a constructor template
       */
      TemplateParameter[] tpl;
      if (token.value == TOKlparen && peekPastParen(&token).value == TOKlparen)
      {	
         tpl = parseTemplateParameterList();

         int varargs;
         auto arguments = parseParameters(varargs);

         Expression constraint = null;
         if (tpl)
            constraint = parseConstraint();

         CtorDeclaration f = new CtorDeclaration(loc, Loc(0), arguments, varargs);
         parseContracts(f);

         // Wrap a template around it
         Dsymbol[] decldefs;
         decldefs ~= (f);
         auto tempdecl =	new TemplateDeclaration(loc, f.ident, tpl, constraint, decldefs);
         return tempdecl;
      }

      /* Just a regular constructor
       */
      int varargs;
      auto arguments = parseParameters(varargs);
      CtorDeclaration f = new CtorDeclaration(loc, Loc(0), arguments, varargs);
      parseContracts(f);
      return f;
   }

    PostBlitDeclaration parsePostBlit()
    {
       assert(false);
    }

    /*****************************************
     * Parse a destructor definition:
     *	~this() { body }
     * Current token is '~'.
     */
    DtorDeclaration parseDtor()
    {
       DtorDeclaration f;
       Loc loc = this.loc;

       nextToken();
       check(TOKthis);
       check(TOKlparen);
       check(TOKrparen);

       f = new DtorDeclaration(loc, Loc(0));
       parseContracts(f);
       return f;
    }

    /*****************************************
     * Parse a static constructor definition:
     *	static this() { body }
     * Current token is 'this'.
     */
    StaticCtorDeclaration parseStaticCtor()
    {
       Loc loc = this.loc;

       nextToken();
       check(TOKlparen);
       check(TOKrparen);

       StaticCtorDeclaration f = new StaticCtorDeclaration(loc, Loc(0));
       parseContracts(f);
       return f;
    }

    /*****************************************
     * Parse a static destructor definition:
     *	static ~this() { body }
     * Current token is '~'.
     */
    StaticDtorDeclaration parseStaticDtor()
    {
       Loc loc = this.loc;

       nextToken();
       check(TOKthis);
       check(TOKlparen);
       check(TOKrparen);

       StaticDtorDeclaration f = new StaticDtorDeclaration(loc, Loc(0));
       parseContracts(f);
       return f;

    }

    /*****************************************
     * Parse a shared static constructor definition:
     *	shared static this() { body }
     * Current token is 'shared'.
     */
    SharedStaticCtorDeclaration parseSharedStaticCtor()
    {
       Loc loc = this.loc;

       nextToken();
       nextToken();
       nextToken();
       check(TOKlparen);
       check(TOKrparen);

       SharedStaticCtorDeclaration f = new SharedStaticCtorDeclaration(loc, Loc(0));
       parseContracts(f);
       return f;
    }

    /*****************************************
     * Parse a shared static destructor definition:
     *	shared static ~this() { body }
     * Current token is 'shared'.
     */
    SharedStaticDtorDeclaration parseSharedStaticDtor()
    {
       Loc loc = this.loc;

       nextToken();
       nextToken();
       nextToken();
       check(TOKthis);
       check(TOKlparen);
       check(TOKrparen);

       SharedStaticDtorDeclaration f = new SharedStaticDtorDeclaration(loc, Loc(0));
       parseContracts(f);
       return f;
    }

    /*****************************************
     * Parse an invariant definition:
     *	invariant() { body }
     * Current token is 'invariant'.
     */
    InvariantDeclaration parseInvariant()
    {
       InvariantDeclaration f;
       Loc loc = this.loc;

       nextToken();
       if (token.value == TOKlparen)	// optional ()
       {
          nextToken();
          check(TOKrparen);
       }

       f = new InvariantDeclaration(loc, Loc(0));
       f.fbody = parseStatement(PScurly);
       return f;
    }

    /*****************************************
     * Parse a unittest definition:
     *	unittest { body }
     * Current token is 'unittest'.
     */
    UnitTestDeclaration parseUnitTest()
    {
       Loc loc = this.loc;

       nextToken();

       UnitTestDeclaration f = new UnitTestDeclaration(loc, this.loc);

       f.fbody = parseStatement(PScurly);

       return f;
    }

    /*****************************************
     * Parse a new definition:
     *	new(arguments) { body }
     * Current token is 'new'.
     */
    NewDeclaration parseNew()
    {
       NewDeclaration f;
       Parameter[] arguments;
       int varargs;
       Loc loc = this.loc;

       nextToken();
       arguments = parseParameters(varargs);
       f = new NewDeclaration(loc, Loc(0), arguments, varargs);
       parseContracts(f);
       return f;
    }

    /*****************************************
     * Parse a delete definition:
     *	delete(arguments) { body }
     * Current token is 'delete'.
     */
    DeleteDeclaration parseDelete()
	{
		DeleteDeclaration f;
		Parameter[] arguments;
		int varargs;
		Loc loc = this.loc;

		nextToken();
		arguments = parseParameters(varargs);
		if (varargs)
			error("... not allowed in delete function parameter list");
		f = new DeleteDeclaration(loc, Loc(0), arguments);
		parseContracts(f);
		return f;
	}
	
    Parameter[] parseParameters(ref int pvarargs)
	{
		Parameter[] arguments;
		int varargs = 0;
		int hasdefault = 0;

		check(TOKlparen);
		while (1)
		{   Type *tb;
		Identifier ai = null;
		Type at;
		Parameter a;
		StorageClass storageClass = STCundefined;
		StorageClass stc;
		Expression ae;

		for ( ;1; nextToken())
		{
			switch (token.value)
			{
			case TOKrparen:
				break;

			case TOKdotdotdot:
				varargs = 1;
				nextToken();
				break;

			case TOKconst:
				if (peek(&token).value == TOKlparen)
				goto Ldefault;
				stc = STCconst;
				goto L2;

			case TOKinvariant:
			case TOKimmutable:
				if (peek(&token).value == TOKlparen)
				goto Ldefault;
				stc = STCimmutable;
				goto L2;

			case TOKshared:
				if (peek(&token).value == TOKlparen)
				goto Ldefault;
				stc = STCshared;
				goto L2;
                
		    case TOKwild:
		        if (peek(&token).value == TOKlparen)
			    goto Ldefault;
		        stc = STCwild;
		        goto L2;

			case TOKin:	   stc = STCin;		goto L2;
			case TOKout:	   stc = STCout;	goto L2;
			case TOKref:	   stc = STCref;	goto L2;
			case TOKlazy:	   stc = STClazy;	goto L2;
			case TOKscope:	   stc = STCscope;	goto L2;
			case TOKfinal:	   stc = STCfinal;	goto L2;
		    case TOKauto:	   stc = STCauto;	    goto L2;
			L2:
				if (storageClass & stc ||
				(storageClass & STCin && stc & (STCconst | STCscope)) ||
				(stc & STCin && storageClass & (STCconst | STCscope))
				   )
				error("redundant storage class %s", Token.toChars(token.value));
				storageClass |= stc;
				composeStorageClass(storageClass);
				continue;

static if (false) {
			case TOKstatic:	   stc = STCstatic;		goto L2;
			case TOKauto:   storageClass = STCauto;		goto L4;
			case TOKalias:  storageClass = STCalias;	goto L4;
			L4:
				nextToken();
				if (token.value == TOKidentifier)
				{	ai = token.ident;
				nextToken();
				}
				else
				ai = null;
				at = null;		// no type
				ae = null;		// no default argument
				if (token.value == TOKassign)	// = defaultArg
				{   nextToken();
				ae = parseDefaultInitExp();
				hasdefault = 1;
				}
				else
				{   if (hasdefault)
					error("default argument expected for alias %s",
						ai ? ai.toChars() : "");
				}
				goto L3;
}

			default:
			Ldefault:
            stc = (storageClass & (STCin | STCout | STCref | STClazy));
				if (stc & (stc - 1))	// if stc is not a power of 2
				   error("incompatible parameter storage classes");
				if ((storageClass & (STCconst | STCout)) == (STCconst | STCout))
				   error("out cannot be const");
				if ((storageClass & (STCimmutable | STCout)) == (STCimmutable | STCout))
				   error("out cannot be immutable");
				if ((storageClass & STCscope) &&
				      (storageClass & (STCref | STCout)))
				   error("scope cannot be ref or out");
				at = parseType(&ai);
				ae = null;
				if (token.value == TOKassign)	// = defaultArg
				{   nextToken();
				   ae = parseDefaultInitExp();
				   hasdefault = 1;
				}
				else
				{   if (hasdefault)
					 error("default argument expected for %s",
						   ai ? ai.toChars() : at.toChars());
				}
				if (token.value == TOKdotdotdot)
				{   /* This is:
                 *	at ai ...
                 */

               if (storageClass & (STCout | STCref))
                  error("variadic argument cannot be out or ref");
               varargs = 2;
               a = new Parameter(storageClass, at, ai, ae);
               arguments ~= (a);
               nextToken();
               break;
            }
         L3:
				a = new Parameter(storageClass, at, ai, ae);
				arguments ~= (a);
				if (token.value == TOKcomma)
				{   nextToken();
				goto L1;
				}
				break;
			}
			break;
		}
		break;

		L1:	;
		}
		check(TOKrparen);
		pvarargs = varargs;
		return arguments;
	}
	
    EnumDeclaration parseEnum()
	{
		EnumDeclaration e;
		Identifier id;
		Type memtype;
		Loc loc = this.loc;

		//printf("Parser.parseEnum()\n");
		nextToken();
		if (token.value == TOKidentifier)
		{
			id = token.ident;
			nextToken();
		}
		else
			id = null;

		if (token.value == TOKcolon)
		{
			nextToken();
			memtype = parseBasicType();
			memtype = parseDeclarator(memtype, null, null);
		}
		else
			memtype = null;

		e = new EnumDeclaration(loc, id, memtype);
		if (token.value == TOKsemicolon && id)
			nextToken();
		else if (token.value == TOKlcurly)
		{
			//printf("enum definition\n");
			nextToken();
			string comment = token.blockComment;
			while (token.value != TOKrcurly)
			{
				/* Can take the following forms:
				 *	1. ident
				 *	2. ident = value
				 *	3. type ident = value
				 */

				loc = this.loc;

				Type type = null;
				Identifier ident;
				Token* tp = peek(&token);
				if (token.value == TOKidentifier &&
					(tp.value == TOKassign || tp.value == TOKcomma || tp.value == TOKrcurly))
				{
					ident = token.ident;
					type = null;
					nextToken();
				}
				else
				{
					type = parseType(&ident, null);
					if (id || memtype)
						error("type only allowed if anonymous enum and no enum type");
				}

				Expression value;
				if (token.value == TOKassign)
				{
					nextToken();
					value = parseAssignExp();
				}
				else
				{	
					value = null;
					if (type)
						error("if type, there must be an initializer");
				}

				auto em = new EnumMember(loc, ident, value, type);
				e.members ~= (em);

				if (token.value == TOKrcurly) {
					;
				} else {
					addComment(em, comment);
					comment = null;
					check(TOKcomma);
				}
				addComment(em, comment);
				comment = token.blockComment;
			}
			nextToken();
		}
		else
			error("enum declaration is invalid");

		//printf("-parseEnum() %s\n", e.toChars());
		return e;
	}
	
    Dsymbol parseAggregate()
	{
		AggregateDeclaration a = null;
		int anon = 0;
		TOK tok;
		Identifier id;
		TemplateParameter[] tpl;
		Expression constraint = null;

		//printf("Parser.parseAggregate()\n");
		tok = token.value;
		nextToken();
		if (token.value != TOKidentifier)
		{
			id = null;
		}
		else
		{
			id = token.ident;
			nextToken();

			if (token.value == TOKlparen)
			{   
				// Class template declaration.

				// Gather template parameter list
				tpl = parseTemplateParameterList();
				constraint = parseConstraint();
			}
		}

		Loc loc = this.loc;
		switch (tok)
		{	
      case TOKclass:
		case TOKinterface:
		{
          if (!id)
              error("anonymous classes not allowed");

          // Collect base class(es)
          BaseClass[] baseclasses = null;
          if (token.value == TOKcolon)
          {
              nextToken();
              baseclasses = parseBaseClasses();

              if (token.value != TOKlcurly)
                  error("members expected");
          }

          if (tok == TOKclass)
              a = new ClassDeclaration(loc, id, baseclasses);
          else
              a = new InterfaceDeclaration(loc, id, baseclasses);
          break;
      }

      case TOKstruct:
      if (id)
      a = new StructDeclaration(loc, id);
      else
          anon = 1;
      break;

      case TOKunion:
      if (id)
          a = new UnionDeclaration(loc, id);
			else
			anon = 2;
			break;

		default:
			assert(0);
			break;
		}
		if (a && token.value == TOKsemicolon)
		{ 	nextToken();
		}
		else if (token.value == TOKlcurly)
		{
		//printf("aggregate definition\n");
		nextToken();
		auto decl = parseDeclDefs(0);
		if (token.value != TOKrcurly)
			error("} expected following member declarations in aggregate");
		nextToken();
		if (anon)
		{
			/* Anonymous structs/unions are more like attributes.
			 */
			return new AnonDeclaration(loc, anon - 1, decl);
		}
		else
			a.members = decl;
		}
		else
		{
		error("{ } expected following aggregate declaration");
		a = new StructDeclaration(loc, null);
		}

		if (tpl)
		{	// Wrap a template around the aggregate declaration

		Dsymbol[] decldefs;
		decldefs ~= (a);
		auto tempdecl =	new TemplateDeclaration(loc, id, tpl, constraint, decldefs);
		return tempdecl;
		}

		return a;
	}
	
    BaseClass[] parseBaseClasses()
	 {
        BaseClass[] baseclasses;

        for (; 1; nextToken())
        {
            PROT protection = PROTpublic;
            switch (token.value)
            {
                case TOKprivate:
                    protection = PROTprivate;
                    nextToken();
                    break;
                case TOKpackage:
                    protection = PROTpackage;
                    nextToken();
                    break;
                case TOKprotected:
                    protection = PROTprotected;
                    nextToken();
                    break;
                case TOKpublic:
                    protection = PROTpublic;
                    nextToken();
                    break;
                default:
                    break;	///
            }
            if (token.value == TOKidentifier)
            {
                auto b = new BaseClass(parseBasicType(), protection);
                baseclasses ~= (b);
                if (token.value != TOKcomma)
                    break;
            }
            else
            {
                error("base classes expected instead of %s", token.toChars());
                return null;
            }
        }
        return baseclasses;
    }
	
    Import parseImport(ref Dsymbol[] decldefs, int isstatic)
	{
		Import s;
		Identifier id;
		Identifier aliasid = null;
		Identifier[] a;
		Loc loc;

		do
		{
		 L1:
			nextToken();
			if (token.value != TOKidentifier)
			{   
				error("Identifier expected following import");
				break;
			}

			loc = this.loc;
			id = token.ident;
         a = null;
			nextToken();
			if (!aliasid && token.value == TOKassign)
			{
				aliasid = id;
				goto L1;
			}
			while (token.value == TOKdot)
			{
				a ~= id;
				nextToken();
				if (token.value != TOKidentifier)
				{   
					error("identifier expected following package");
					break;
				}
				id = token.ident;
				nextToken();
			}

			s = new Import(loc, a, id, aliasid, isstatic);
			decldefs ~= (s);

			/* Look for
			 *	: alias=name, alias=name;
			 * syntax.
			 */
			if (token.value == TOKcolon)
			{
				do
				{	
					Identifier name;

					nextToken();
					if (token.value != TOKidentifier)
					{   
						error("Identifier expected following :");
						break;
					}
					Identifier alias_ = token.ident;
					nextToken();
					if (token.value == TOKassign)
					{
						nextToken();
						if (token.value != TOKidentifier)
						{   
							error("Identifier expected following %s=", alias_.toChars());
							break;
						}
						name = token.ident;
						nextToken();
					}
					else
					{   
						name = alias_;
						alias_ = null;
					}
					s.addAlias(name, alias_);
				} while (token.value == TOKcomma);

				break;	// no comma-separated imports of this form
			}

			aliasid = null;

		} while (token.value == TOKcomma);

		if (token.value == TOKsemicolon)
			nextToken();
		else
		{
			error("';' expected");
			nextToken();
		}
		return null;
	}
	
    Type parseType( Identifier* pident = null, TemplateParameter[] tpl = [] )
	{
		Type t;

		/* Take care of the storage class prefixes that
		 * serve as type attributes:
		 *  const shared, shared const, const, invariant, shared
		 */
		if (token.value == TOKconst && peekNext() == TOKshared && peekNext2() != TOKlparen ||
			token.value == TOKshared && peekNext() == TOKconst && peekNext2() != TOKlparen)
		{
			nextToken();
			nextToken();
			/* shared const type
			 */
			t = parseType(pident, tpl);
			t = t.makeSharedConst();
			return t;
		}
        else if (token.value == TOKwild && peekNext() == TOKshared && peekNext2() != TOKlparen ||
	             token.value == TOKshared && peekNext() == TOKwild && peekNext2() != TOKlparen)
        {
	        nextToken();
	        nextToken();
	        /* shared wild type
	         */
	        t = parseType(pident, tpl);
	        t = t.makeSharedWild();
	        return t;
        }
		else if (token.value == TOKconst && peekNext() != TOKlparen)
		{
			nextToken();
			/* const type
			 */
			t = parseType(pident, tpl);
			t = t.makeConst();
			return t;
		}
		else if ((token.value == TOKinvariant || token.value == TOKimmutable) &&
				 peekNext() != TOKlparen)
		{
			nextToken();
			/* invariant type
			 */
			t = parseType(pident, tpl);
			t = t.makeInvariant();
			return t;
		}
		else if (token.value == TOKshared && peekNext() != TOKlparen)
		{
			nextToken();
			/* shared type
			 */
			t = parseType(pident, tpl);
			t = t.makeShared();
			return t;
		}
        else if (token.value == TOKwild && peekNext() != TOKlparen)
        {
	        nextToken();
	        /* wild type
	         */
	        t = parseType(pident, tpl);
	        t = t.makeWild();
	        return t;
        }
		else
			t = parseBasicType();	
		t = parseDeclarator(t, pident, tpl);
		return t;
	}
	
    Type parseBasicType()
	{
		Type t;
		Identifier id;
		TypeQualified tid;

		switch (token.value)
		{
			case TOKvoid:	 t = Type.tvoid;  goto LabelX;
			case TOKint8:	 t = Type.tint8;  goto LabelX;
			case TOKuns8:	 t = Type.tuns8;  goto LabelX;
			case TOKint16:	 t = Type.tint16; goto LabelX;
			case TOKuns16:	 t = Type.tuns16; goto LabelX;
			case TOKint32:	 t = Type.tint32; goto LabelX;
			case TOKuns32:	 t = Type.tuns32; goto LabelX;
			case TOKint64:	 t = Type.tint64; goto LabelX;
			case TOKuns64:	 t = Type.tuns64; goto LabelX;
			case TOKfloat32: t = Type.tfloat32; goto LabelX;
			case TOKfloat64: t = Type.tfloat64; goto LabelX;
			case TOKfloat80: t = Type.tfloat80; goto LabelX;
			case TOKimaginary32: t = Type.timaginary32; goto LabelX;
			case TOKimaginary64: t = Type.timaginary64; goto LabelX;
			case TOKimaginary80: t = Type.timaginary80; goto LabelX;
			case TOKcomplex32: t = Type.tcomplex32; goto LabelX;
			case TOKcomplex64: t = Type.tcomplex64; goto LabelX;
			case TOKcomplex80: t = Type.tcomplex80; goto LabelX;
			case TOKbit:	 t = Type.tbit;     goto LabelX;
			case TOKbool:	 t = Type.tbool;    goto LabelX;
			case TOKchar:	 t = Type.tchar;    goto LabelX;
			case TOKwchar:	 t = Type.twchar; goto LabelX;
			case TOKdchar:	 t = Type.tdchar; goto LabelX;
			LabelX:
				nextToken();
				break;

		case TOKidentifier:
			id = token.ident;
			nextToken();
			if (token.value == TOKnot)
         {	// ident!(template_arguments)
            TemplateInstance tempinst = new TemplateInstance(loc, id);
            nextToken();
            if (token.value == TOKlparen)
               // ident!(template_arguments)
               tempinst.tiargs = parseTemplateArgumentList();
            else
               // ident!template_argument
               tempinst.tiargs = parseTemplateArgument();
            tid = new TypeInstance(loc, tempinst);
            goto Lident2;
         }
		Lident:
			tid = new TypeIdentifier(loc, id);
		Lident2:
			while (token.value == TOKdot)
			{	
            nextToken();
			   if (token.value != TOKidentifier)
			   {   error("identifier expected following '.' instead of '%s'", token.toChars());
               break;
            }
            id = token.ident;
            nextToken();
            if (token.value == TOKnot)
            {
               TemplateInstance tempinst = new TemplateInstance(loc, id);
               nextToken();
               if (token.value == TOKlparen)
                  // ident!(template_arguments)
                  tempinst.tiargs = parseTemplateArgumentList();
               else
                  // ident!template_argument
                  tempinst.tiargs = parseTemplateArgument();
               tid.addIdent(tempinst.ident);
            }
            else
               tid.addIdent(id);
         }
         t = tid;
         break;

      case TOKdot:
			// Leading . as in .foo
			id = Id.empty;
			goto Lident;

		case TOKtypeof:
			// typeof(expression)
			tid = parseTypeof();
			goto Lident2;

		case TOKconst:
			// const(type)
			nextToken();
			check(TOKlparen);
			t = parseType();
			check(TOKrparen);
			if (t.isShared())
			t = t.makeSharedConst();
			else
			t = t.makeConst();
			break;

		case TOKinvariant:
		case TOKimmutable:
			// invariant(type)
			nextToken();
			check(TOKlparen);
			t = parseType();
			check(TOKrparen);
			t = t.makeInvariant();
			break;

		case TOKshared:
			// shared(type)
			nextToken();
			check(TOKlparen);
			t = parseType();
			check(TOKrparen);
			if (t.isConst())
			t = t.makeSharedConst();
	        else if (t.isWild())
		    t = t.makeSharedWild();
			else
			t = t.makeShared();
			break;

	    case TOKwild:
	        // wild(type)
	        nextToken();
	        check(TOKlparen);
	        t = parseType();
	        check(TOKrparen);
	        if (t.isShared())
		    t = t.makeSharedWild();
	        else
		    t = t.makeWild();
	        break;
            
		default:
			error("basic type expected, not %s", token.toChars());
			t = Type.tint32;
			break;
		}
		return t;
	}
	
    Type parseBasicType2(Type t)
	{
		//writef("parseBasicType2()\n");
		while (1)
		{
			switch (token.value)
			{
				case TOKmul:
				t = new TypePointer(t);
				nextToken();
				continue;
	
				case TOKlbracket:
				// Handle []. Make sure things like
				//     int[3][1] a;
				// is (array[1] of array[3] of int)
				nextToken();
				if (token.value == TOKrbracket)
				{
					t = new TypeDArray(t);			// []
					nextToken();
				}
				else if (token.value == TOKnew && peekNext() == TOKrbracket)
				{
					t = new TypeNewArray(t);			// [new]
					nextToken();
					nextToken();
				}
				else if (isDeclaration(&token, 0, TOKrbracket, false))
				{   // It's an associative array declaration
	
					//printf("it's an associative array\n");
					Type index = parseType();		// [ type ]
					t = new TypeAArray(t, index);
					check(TOKrbracket);
				}
				else
				{
					//printf("it's type[expression]\n");
					inBrackets++;
					Expression e = parseAssignExp();		// [ expression ]
					if (token.value == TOKslice)
					{
					nextToken();
					Expression e2 = parseAssignExp();	// [ exp .. exp ]
					t = new TypeSlice(t, e, e2);
					}
					else
					t = new TypeSArray(t,e);
					inBrackets--;
					check(TOKrbracket);
				}
				continue;
	
				case TOKdelegate:
				case TOKfunction:
				{	// Handle delegate declaration:
				//	t delegate(parameter list) nothrow pure
				//	t function(parameter list) nothrow pure
				Parameter[] arguments;
				int varargs;
				bool ispure = false;
				bool isnothrow = false;
		        bool isproperty = false;
				TOK save = token.value;
		        TRUST trust = TRUSTdefault;
	
				nextToken();
				arguments = parseParameters(varargs);
				while (1)
				{   // Postfixes
					if (token.value == TOKpure)
					    ispure = true;
					else if (token.value == TOKnothrow)
					    isnothrow = true;
		            else if (token.value == TOKat)
		            {	StorageClass stc = parseAttribute();
			            switch (stc >> 32)
			            {   case STCproperty >> 32:
				                isproperty = true;
				                break;
			                case STCsafe >> 32:
				                trust = TRUSTsafe;
				                break;
			                case STCsystem >> 32:
				                trust = TRUSTsystem;
				                break;
			                case STCtrusted >> 32:
				                trust = TRUSTtrusted;
				                break;
			                case 0:
				                break;
			                default:
    				            assert(0);
			            }
		            }
					else
					    break;
					nextToken();
				}
				TypeFunction tf = new TypeFunction(arguments, t, varargs, linkage);
				tf.ispure = ispure;
				tf.isnothrow = isnothrow;
		        tf.isproperty = isproperty;
		        tf.trust = trust;
				if (save == TOKdelegate)
					t = new TypeDelegate(tf);
				else
					t = new TypePointer(tf);	// pointer to function
				continue;
				}
	
				default:
				return t;
			}
			assert(0);
		}
		assert(0);
		return null;
	}
    
    /+ ++++++++++++++++++++++++++++++++++++++++++++++++++++++/
    /+ TODO This has a different signature in the C++ dmd
        It is :
Type *Parser::parseDeclarator(Type *t, Identifier **pident, TemplateParameters **tpl, StorageClass storage_class, int* pdisable)
    /+ A chore for a diligent worker! +/
    /+ ++++++++++++++++++++++++++++++++++++++++++++++++++++++/
    +/

    Type parseDeclarator(Type t, Identifier* pident, TemplateParameter[] tpl = null,)
	{
		Type ts;
		t = parseBasicType2(t);
		switch (token.value)
		{
		case TOKidentifier:
         if (pident)
            *pident = token.ident;
         else
            error("unexpected identifier '%s' in declarator", token.ident.toChars());
         ts = t;

         nextToken();

         break;

		case TOKlparen:
			/* Parse things with parentheses around the identifier, like:
			 *	int (*ident[3])[]
			 * although the D style would be:
			 *	int[]*[3] ident
			 */
			nextToken();
			ts = parseDeclarator(t, pident);
			check(TOKrparen);
			break;

		default:
			ts = t;
			break;
		}

      // parse DeclaratorSuffixes
      while (1)
      {
         switch (token.value)
         {
            version (CARRAYDECL) 
            {
               /* Support C style array syntax:
                *   int ident[]
                * as opposed to D-style:
                *   int[] ident
                */
               case TOKlbracket:
               {	// This is the old C-style post [] syntax.
                   TypeNext ta;
                   nextToken();
                   if (token.value == TOKrbracket)
                   {   // It's a dynamic array
                      ta = new TypeDArray(t);		// []
                      nextToken();
                   }
                   else if (token.value == TOKnew && peekNext() == TOKrbracket)
                   {
                      t = new TypeNewArray(t);		// [new]
                      nextToken();
                      nextToken();
                   }
                   else if (isDeclaration(&token, 0, TOKrbracket, false))
                   {   
                      // It's an associative array
                      Type index = parseType();		// [ type ]
                      check(TOKrbracket);
                      ta = new TypeAArray(t, index);
                   }
                   else
                   {
                      //printf("It's a static array\n");
                      Expression e = parseAssignExp();	// [ expression ]
                      ta = new TypeSArray(t, e);
                      check(TOKrbracket);
                   }

                   /* Insert ta into
                    *   ts . ... . t
                    * so that
                    *   ts . ... . ta . t
                    */
                   Type* pt;
                   for (pt = &ts; *pt !is t; pt = &(cast(TypeNext)*pt).next) {
                      ;
                   }
                   *pt = ta;
                   continue;
               }
            }
            case TOKlparen:
            {
               if (tpl)
                    /* Look ahead to see if this is (...)(...),
                     * i.e. a function template declaration
                     */
                    if (peekPastParen(&token).value == TOKlparen)
                        //printf("function template declaration\n");
                        // Gather template parameter list
                        tpl = parseTemplateParameterList();

                int varargs;
                auto arguments = parseParameters(varargs);
                Type tf = new TypeFunction(arguments, t, varargs, linkage);

                /* Parse const/invariant/nothrow/pure postfix
                 */
                while (1)
                {
                    switch (token.value)
                    {
                        case TOKconst:
                            if (tf.isShared())
                                tf = tf.makeSharedConst();
                            else
                                tf = tf.makeConst();
                            nextToken();
                            continue;

                        case TOKinvariant:
                        case TOKimmutable:
                            tf = tf.makeInvariant();
                            nextToken();
                            continue;

                        case TOKshared:
                            if (tf.isConst())
                                tf = tf.makeSharedConst();
                            else
                                tf = tf.makeShared();
                            nextToken();
                            continue;

                        case TOKwild:
                            if (tf.isShared())
                                tf = tf.makeSharedWild();
                            else
                                tf = tf.makeWild();
                            nextToken();
                            continue;

                        case TOKnothrow:
                            (cast(TypeFunction)tf).isnothrow = 1;
                            nextToken();
                            continue;

                        case TOKpure:
                            (cast(TypeFunction)tf).ispure = 1;
                            nextToken();
                            continue;

                        case TOKat:
                            {
                                StorageClass stc = parseAttribute();
                                auto tfunc = cast(TypeFunction)tf;
                                switch (stc >> 32)
                                {
                                    case STCproperty >> 32:
                                        tfunc.isproperty = 1;
                                        break;
                                    case STCsafe >> 32:
                                        tfunc.trust = TRUSTsafe;
                                        break;
                                    case STCsystem >> 32:
                                        tfunc.trust = TRUSTsystem;
                                        break;
                                    case STCtrusted >> 32:
                                        tfunc.trust = TRUSTtrusted;
                                        break;
                                    case 0:
                                        break;
                                    default:
                                        assert(0);
                                }
                                nextToken();
                                continue;
                            }
                        default:
                            break;	///
                    }
                    break;
                }

                /* Insert tf into
                 *   ts . ... . t
                 * so that
                 *   ts . ... . tf . t
                 */
                Type* pt;
                for (pt = &ts; *pt !is t; pt = &(cast(TypeNext)*pt).next) {
                    ;
                }
                *pt = tf;
                break;
            }

            default:
            break;	///
        }
        break;
        }

        return ts;
   }

    Dsymbol[] parseDeclarations(StorageClass storage_class)
    {
        StorageClass stc;
        Type ts;
        Type t;
        Type tfirst;
        Identifier ident;
        Dsymbol[] a;
        TOK tok = TOKreserved;
        string comment = token.blockComment;
        LINK link = linkage;

        if (storage_class)
        {	ts = null;		// infer type
            goto L2;
        }

        switch (token.value)
        {
        case TOKalias:
            /* Look for:
             *   alias identifier this;
             */
            tok = token.value;
            nextToken();
            if (token.value == TOKidentifier && peek(&token).value == TOKthis)
            {
                AliasThis s = new AliasThis(this.loc, token.ident);
                nextToken();
                check(TOKthis);
                check(TOKsemicolon);
                a ~= (s);
                addComment(s, comment);
                return a;
            }
            break;
        case TOKtypedef:
            tok = token.value;
            nextToken();
            break;
        default:
                break;
        }

        storage_class = STCundefined;
      while (1)
      {
		  switch (token.value)
        {
		  case TOKconst:
            if (peek(&token).value == TOKlparen)
                break;		// const as type constructor
            stc = STCconst;		// const as storage class
            goto L1;

        case TOKinvariant:
        case TOKimmutable:
            if (peek(&token).value == TOKlparen)
                break;
            stc = STCimmutable;
            goto L1;

        case TOKshared:
            if (peek(&token).value == TOKlparen)
                break;
            stc = STCshared;
            goto L1;

        case TOKwild:
            if (peek(&token).value == TOKlparen)
                break;
            stc = STCwild;
            goto L1;

        case TOKstatic:	stc = STCstatic;	 goto L1;
        case TOKfinal:	stc = STCfinal;		 goto L1;
        case TOKauto:	stc = STCauto;		 goto L1;
        case TOKscope:	stc = STCscope;		 goto L1;
        case TOKoverride:	stc = STCoverride;	 goto L1;
        case TOKabstract:	stc = STCabstract;	 goto L1;
        case TOKsynchronized: stc = STCsynchronized; goto L1;
        case TOKdeprecated: stc = STCdeprecated;	 goto L1;
        case TOKnothrow:    stc = STCnothrow;	 goto L1;
        case TOKpure:       stc = STCpure;		 goto L1;
        case TOKref:        stc = STCref;            goto L1;
        case TOKtls:        stc = STCtls;		 goto L1;
        case TOKgshared:    stc = STCgshared;	 goto L1;
        case TOKenum:	stc = STCmanifest;	 goto L1;
        case TOKat:         stc = parseAttribute();  goto L1;
	 L1:
		  if (storage_class & stc)
				error("redundant storage class '%s'", token.toChars());
		  storage_class = (storage_class | stc);
        composeStorageClass(storage_class);
        nextToken();
        continue;

		  case TOKextern:
            if (peek(&token).value != TOKlparen)
            {   stc = STCextern;
                goto L1;
            }

            link = parseLinkage();
            continue;

        default:
            break;
        } // end switch (token.value)
        break;
        } //end while(1)

        /* Look for auto initializers:
         *	storage_class identifier = initializer;
         */
        if (storage_class &&
                token.value == TOKidentifier &&
                peek(&token).value == TOKassign)
        {
            return parseAutoDeclarations(storage_class, comment);
        }

        if (token.value == TOKclass)
        {
            
            AggregateDeclaration s = cast(AggregateDeclaration)parseAggregate();
            s.storage_class |= storage_class;
            a ~= (s);
            addComment(s, comment);
            return a;
        }

		/* Look for return type inference for template functions.
		 */
		{
          Token* tk;
          if (storage_class &&
                token.value == TOKidentifier &&
                ( tk = peek(&token) ).value == TOKlparen &&
                skipParens(tk) &&
                ((tk = peek(tk)), 1) &&
                skipAttributes(tk) &&
                (tk.value == TOKlparen ||
                 tk.value == TOKlcurly)
             )
          {
              ts = null;
          }
          else
          {
              ts = parseBasicType();
              ts = parseBasicType2(ts);
          }
      }
    L2:
      tfirst = null;

		while (1)
		{
          Loc loc = this.loc;
          TemplateParameter[] tpl = null;

          ident = null;

          t = parseDeclarator(ts, &ident, tpl);
          assert(t);

          if (!tfirst)
              tfirst = t;
          else if (t != tfirst)
              error("multiple declarations must have the same type, not %s and %s",
                      tfirst.toChars(), t.toChars());
          if (!ident)
              error("no identifier for declarator %s", t.toChars());

          if (tok == TOKtypedef || tok == TOKalias)
          {   
              Declaration v;
              Initializer init = null;

              if (token.value == TOKassign)
              {
                  nextToken();
                  init = parseInitializer();
              }
              if (tok == TOKtypedef)
                  v = new TypedefDeclaration(loc, ident, t, init);
              else
              {	if (init)
                  error("alias cannot have initializer");
                  v = new AliasDeclaration(loc, ident, t);
              }
              v.storage_class = storage_class;
              if (link == linkage)
                  a ~= (v);
              else
              {
                  Dsymbol[] ax;
                  ax ~= (v);
                  Dsymbol s = new LinkDeclaration(link, ax);
                  a ~= (s);
              }
              switch (token.value)
              {   case TOKsemicolon:
                  nextToken();
                  addComment(v, comment);
                  break;

                  case TOKcomma:
                  nextToken();
                  addComment(v, comment);
                  continue;

                  default:
                  error("semicolon expected to close %s declaration", Token.toChars(tok));
                  break;
              }
          }
          else if (t.ty == Tfunction)
          {
              Expression constraint = null;
              version(none) 
              {
                 auto tf = cast(TypeFunction)t;
                 if (Parameter.isTPL(tf.parameters))
                 {
                    if (!tpl)
                       tpl = new TemplateParameter[];
                 }
              }
              FuncDeclaration f =
                  new FuncDeclaration(loc, Loc(0), ident, storage_class, t);
              addComment(f, comment);
              if (tpl)
                  constraint = parseConstraint();
              parseContracts(f);
              addComment(f, null);
              Dsymbol s;
              if (link == linkage)
              {
                  s = f;
              }
              else
              {
                  Dsymbol[] ax;
                  ax ~= f;
                  s = new LinkDeclaration(link, ax);
              }
              /* A template parameter list means it's a function template
               */
              if (tpl)
              {
                  // Wrap a template around the function declaration
                  Dsymbol[] decldefs;
                  decldefs ~= s;
                  auto tempdecl =
                      new TemplateDeclaration(loc, s.ident, tpl, constraint, decldefs);
                  s = tempdecl;
              }
              addComment(s, comment);
              a ~= (s);
          }
          else
          {
              Initializer init = null;
              if (token.value == TOKassign)
              {
                  nextToken();
                  init = parseInitializer();
              }

              VarDeclaration v = new VarDeclaration(loc, t, ident, init);
              v.storage_class = storage_class;
              if (link == linkage)
                  a ~= (v);
              else
              {
                  Dsymbol[] ax;
                  ax ~= (v);
                  auto s = new LinkDeclaration(link, ax);
                  a ~= (s);
              }
              switch (token.value)
              {   case TOKsemicolon:
                  nextToken();
                  addComment(v, comment);
                  break;

                  case TOKcomma:
                  nextToken();
                  addComment(v, comment);
                  continue;

                  default:
                  error("semicolon expected, not '%s'", token.toChars());
                  break;
              }
          }
          break;
      }
      return a;
    }

    void parseContracts(FuncDeclaration f)
    {
        LINK linksave = linkage;

        // The following is irrelevant, as it is overridden by sc.linkage in
        // TypeFunction.semantic
        linkage = LINKd;		// nested functions have D linkage
L1:
        switch (token.value)
        {
            case TOKlcurly:
                if (f.frequire || f.fensure)
                    error("missing body { ... } after in or out");
                f.fbody = parseStatement(PSsemi);
                f.endloc = endloc;
                break;

            case TOKbody:
                nextToken();
                f.fbody = parseStatement(PScurly);
                f.endloc = endloc;
                break;

            case TOKsemicolon:
                if (f.frequire || f.fensure)
                    error("missing body { ... } after in or out");
                nextToken();
                break;

                static if (false) {	// Do we want this for function declarations, so we can do:
                    // int x, y, foo(), z;
                    case TOKcomma:
                        nextToken();
                        continue;
                }

            case TOKin:
                nextToken();
                if (f.frequire)
                    error("redundant 'in' statement");
                f.frequire = parseStatement(PScurly | PSscope);
                goto L1;

            case TOKout:
                // parse: out (identifier) { statement }
                nextToken();
                if (token.value != TOKlcurly)
                {
                    check(TOKlparen);
                    if (token.value != TOKidentifier)	   
                        error("(identifier) following 'out' expected, not %s", token.toChars());
                    f.outId = token.ident;
                    nextToken();
                    check(TOKrparen);
                }
                if (f.fensure)
                    error("redundant 'out' statement");
                f.fensure = parseStatement(PScurly | PSscope);
                goto L1;

            default:
                error("semicolon expected following function declaration");
                break;
        }
        linkage = linksave;
    }

   Statement parseStatement(ParseStatementFlags flags)
   {
      Statement s;
      Token* t;
      Condition condition;
      Statement ifbody;
      Statement elsebody;
      bool isfinal;
      Loc loc = this.loc;

      //printf("parseStatement()\n");

      if (flags & PScurly && token.value != TOKlcurly)
         error("statement expected to be { }, not %s", token.toChars());
      
      switch (token.value)
		{
		case TOKidentifier:
			/* A leading identifier can be a declaration, label, or expression.
			 * The easiest case to check first is label:
			 */
			t = peek(&token);
         if (t.value == TOKcolon)
         {	// It's a label

             Identifier ident = token.ident;
             nextToken();
             nextToken();
             s = parseStatement(PSsemi);
             s = new LabelStatement(loc, ident, s);
             break;
         }
         goto case TOKdot; 
      case TOKdot:
		case TOKtypeof:
			if (isDeclaration(&token, 2, TOKreserved, false))
         {
            goto Ldeclaration;
			}
         else
         {
			   goto Lexp;
         }
         break;

		case TOKassert:
		case TOKthis:
		case TOKsuper:
		case TOKint32v:
		case TOKuns32v:
		case TOKint64v:
		case TOKuns64v:
		case TOKfloat32v:
		case TOKfloat64v:
		case TOKfloat80v:
		case TOKimaginary32v:
		case TOKimaginary64v:
		case TOKimaginary80v:
		case TOKcharv:
		case TOKwcharv:
		case TOKdcharv:
		case TOKnull:
		case TOKtrue:
		case TOKfalse:
		case TOKstring:
		case TOKlparen:
		case TOKcast:
		case TOKmul:
		case TOKmin:
		case TOKadd:
		case TOKplusplus:
		case TOKminusminus:
		case TOKnew:
		case TOKdelete:
		case TOKdelegate:
		case TOKfunction:
		case TOKtypeid:
		case TOKis:
		case TOKlbracket:
		case TOKtraits:
		case TOKfile:
		case TOKline:
		Lexp:
		{
			auto exp = parseExpression();
			check(TOKsemicolon, "statement");
			s = new ExpStatement(loc, exp);
			break;
		}

		case TOKstatic:
		{   // Look ahead to see if it's static assert() or static if()
          Token* tt;

          tt = peek(&token);
          if (tt.value == TOKassert)
          {
              nextToken();
              s = new StaticAssertStatement(parseStaticAssert());
              break;
          }
          if (tt.value == TOKif)
          {
              nextToken();
              condition = parseStaticIfCondition();
              goto Lcondition;
          }
          if (tt.value == TOKstruct || tt.value == TOKunion || tt.value == TOKclass)
          {
              nextToken();
              auto a = parseBlock();
              Dsymbol d = new StorageClassDeclaration(STCstatic, a);
              s = new DeclarationStatement(loc, d);
              if (flags & PSscope)
                  s = new ScopeStatement(loc, s);
              break;
          }
          goto Ldeclaration;
		}

		case TOKfinal:
			if (peekNext() == TOKswitch)
			{
			nextToken();
			isfinal = true;
			goto Lswitch;
			}
			goto Ldeclaration;

		case TOKwchar: case TOKdchar:
		case TOKbit: case TOKbool: case TOKchar:
		case TOKint8: case TOKuns8:
		case TOKint16: case TOKuns16:
		case TOKint32: case TOKuns32:
		case TOKint64: case TOKuns64:
		case TOKfloat32: case TOKfloat64: case TOKfloat80:
		case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:
		case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:
		case TOKvoid:
		case TOKtypedef:
		case TOKalias:
		case TOKconst:
		case TOKauto:
		case TOKextern:
		case TOKinvariant:
		case TOKimmutable:
		case TOKshared:
      case TOKwild:
		case TOKnothrow:
		case TOKpure:
		case TOKtls:
		case TOKgshared:
      case TOKat:
	//	case TOKtypeof:
		Ldeclaration:
		{   Dsymbol[] a;

          a = parseDeclarations(STCundefined);
          if (a.length > 1)
          {
              Statement[] as;
              as.reserve(a.length);
              foreach(Dsymbol d; a)
              {
                  s = new DeclarationStatement(loc, d);
                  as ~= s; 
              }
              s = new CompoundDeclarationStatement(loc, as);
          }
			else if (a.length == 1)
			{
				auto d = a[0];
			s = new DeclarationStatement(loc, d);
			}
			else
			assert(0);
			if (flags & PSscope)
			s = new ScopeStatement(loc, s);
			break;
		}

		case TOKstruct:
		case TOKunion:
		case TOKclass:
		case TOKinterface:
		{   Dsymbol d;

			d = parseAggregate();
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOKenum:
		{   /* Determine if this is a manifest constant declaration,
			 * or a conventional enum.
			 */
			Dsymbol d;
			Token* tt = peek(&token);
			if (tt.value == TOKlcurly || tt.value == TOKcolon)
			d = parseEnum();
			else if (tt.value != TOKidentifier)
			goto Ldeclaration;
			else
			{
			tt = peek(tt);
			if (tt.value == TOKlcurly || tt.value == TOKcolon ||
				tt.value == TOKsemicolon)
				d = parseEnum();
			else
				goto Ldeclaration;
			}
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOKmixin:
		{   t = peek(&token);
			if (t.value == TOKlparen)
			{	// mixin(string)
			nextToken();
			check(TOKlparen, "mixin");
			Expression e = parseAssignExp();
			check(TOKrparen);
			check(TOKsemicolon);
			s = new CompileStatement(loc, e);
			break;
			}
			Dsymbol d = parseMixin();
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOKlcurly:
		{
			nextToken();
			Statement[] statements;
			while (token.value != TOKrcurly && token.value != TOKeof)
			{
			   statements ~= (parseStatement(PSsemi | PScurlyscope));
			}
			endloc = this.loc;
			s = new CompoundStatement(loc, statements);
			if (flags & (PSscope | PScurlyscope))
			s = new ScopeStatement(loc, s);
			nextToken();
			break;
		}

		case TOKwhile:
		{   Expression condition2;
			Statement body_;

			nextToken();
			check(TOKlparen);
			condition2 = parseExpression();
			check(TOKrparen);
			body_ = parseStatement(PSscope);
			s = new WhileStatement(loc, condition2, body_);
			break;
		}

		case TOKsemicolon:
			if (!(flags & PSsemi))
			error("use '{ }' for an empty statement, not a ';'");
			nextToken();
			s = new ExpStatement(loc, null);
			break;

		case TOKdo:
		{   Statement body_;
			Expression condition2;

			nextToken();
			body_ = parseStatement(PSscope);
			check(TOKwhile);
			check(TOKlparen);
			condition2 = parseExpression();
			check(TOKrparen);
			check(TOKsemicolon);
			s = new DoStatement(loc, body_, condition2);
			break;
		}

		case TOKfor:
		{
			Statement init;
			Expression condition2;
			Expression increment;
			Statement body_;

			nextToken();
			check(TOKlparen);
			if (token.value == TOKsemicolon)
			{	init = null;
			nextToken();
			}
			else
			{	init = parseStatement( 0 );
			}
			if (token.value == TOKsemicolon)
			{
			condition2 = null;
			nextToken();
			}
			else
			{
			condition2 = parseExpression();
			check(TOKsemicolon, "for condition");
			}
			if (token.value == TOKrparen)
			{	increment = null;
			nextToken();
			}
			else
			{	increment = parseExpression();
			check(TOKrparen);
			}
			body_ = parseStatement(PSscope);
			s = new ForStatement(loc, init, condition2, increment, body_);
			if (init)
			s = new ScopeStatement(loc, s);
			break;
		}

		case TOKforeach:
		case TOKforeach_reverse:
		{
			TOK op = token.value;

			nextToken();
			check(TOKlparen);

			Parameter[] arguments;

			while (1)
			{
			Identifier ai = null;
			Type at;
			StorageClass storageClass = STCundefined;

		if (token.value == TOKref
//#if D1INOUT
//			|| token.value == TOKinout
//#endif
		   )
			{   storageClass = STCref;
				nextToken();
			}
			if (token.value == TOKidentifier)
			{
				Token* tt = peek(&token);
				if (tt.value == TOKcomma || tt.value == TOKsemicolon)
				{	ai = token.ident;
				at = null;		// infer argument type
				nextToken();
				goto Larg;
				}
			}
			at = parseType(&ai);
			if (!ai)
				error("no identifier for declarator %s", at.toChars());
		  Larg:
			auto a = new Parameter(storageClass, at, ai, null);
			arguments ~= (a);
         if (token.value == TOKcomma)
			{   nextToken();
				continue;
			}
			break;
			}
			check(TOKsemicolon);

			Expression aggr = parseExpression();
			if (token.value == TOKslice && arguments.length == 1)
			{
             auto a = arguments[0];

             nextToken();
             Expression upr = parseExpression();
             check(TOKrparen);
             auto body_ = parseStatement(0);
             s = new ForeachRangeStatement(loc, op, a, aggr, upr, body_);
			}
			else
			{
             check(TOKrparen);
             auto body_ = parseStatement(0);
             s = new ForeachStatement(loc, op, arguments, aggr, body_);
			}
			break;
		}

		case TOKif:
		{   Parameter arg = null;
			Expression condition2;
			Statement ifbody2;
			Statement elsebody2;

			nextToken();
			check(TOKlparen);

			if (token.value == TOKauto)
			{
			nextToken();
			if (token.value == TOKidentifier)
			{
				Token* tt = peek(&token);
				if (tt.value == TOKassign)
				{
					arg = new Parameter(STCundefined, null, token.ident, null);
					nextToken();
					nextToken();
				}
				else
				{   error("= expected following auto identifier");
				goto Lerror;
				}
			}
			else
			{   error("identifier expected following auto");
				goto Lerror;
			}
			}
			else if (isDeclaration(&token, 2, TOKassign, false))
			{
			Type at;
			Identifier ai;

			at = parseType(&ai);
			check(TOKassign);
			arg = new Parameter(STCundefined, at, ai, null);
			}

			// Check for " ident;"
			else if (token.value == TOKidentifier)
			{
			Token* tt = peek(&token);
			if (tt.value == TOKcomma || tt.value == TOKsemicolon)
			{
				arg = new Parameter(STCundefined, null, token.ident, null);
				nextToken();
				nextToken();
				if (1 || !global.params.useDeprecated)
				error("if (v; e) is deprecated, use if (auto v = e)");
			}
			}

			condition2 = parseExpression();
			check(TOKrparen);
			ifbody2 = parseStatement(PSscope);
			if (token.value == TOKelse)
			{
			nextToken();
			elsebody2 = parseStatement(PSscope);
			}
			else
			elsebody2 = null;
			s = new IfStatement(loc, arg, condition2, ifbody2, elsebody2);
			break;
		}

		case TOKscope:
			if (peek(&token).value != TOKlparen)
			goto Ldeclaration;		// scope used as storage class
			nextToken();
			check(TOKlparen);
			if (token.value != TOKidentifier)
			{	error("scope identifier expected");
			goto Lerror;
			}
			else
			{	TOK tt = TOKon_scope_exit;
			Identifier id = token.ident;

			if (id == Id.exit)
				tt = TOKon_scope_exit;
			else if (id == Id.failure)
				tt = TOKon_scope_failure;
			else if (id == Id.success)
				tt = TOKon_scope_success;
			else
				error("valid scope identifiers are exit, failure, or success, not %s", id.toChars());
			nextToken();
			check(TOKrparen);
			Statement st = parseStatement(PScurlyscope);
			s = new OnScopeStatement(loc, tt, st);
			break;
			}

		case TOKdebug:
			nextToken();
			condition = parseDebugCondition();
			goto Lcondition;

		case TOKversion:
			nextToken();
			condition = parseVersionCondition();
			goto Lcondition;

		Lcondition:
         ifbody = parseStatement( 0 /*PSsemi*/);
         elsebody = null;
         if (token.value == TOKelse)
         {
            nextToken();
            elsebody = parseStatement( 0 /*PSsemi*/);
         }
         s = new ConditionalStatement(loc, condition, ifbody, elsebody);
			break;

		case TOKpragma:
		{   Identifier ident;
			Expression[] args;
			Statement body_;

			nextToken();
			check(TOKlparen);
			if (token.value != TOKidentifier)
			{   error("pragma(identifier expected");
			goto Lerror;
			}
			ident = token.ident;
			nextToken();
			if (token.value == TOKcomma && peekNext() != TOKrparen)
			args = parseArguments();	// pragma(identifier, args...);
			else
			check(TOKrparen);		// pragma(identifier);
			if (token.value == TOKsemicolon)
			{	nextToken();
			body_ = null;
			}
			else
			body_ = parseStatement(PSsemi);
			s = new PragmaStatement(loc, ident, args, body_);
			break;
		}

		case TOKswitch:
			isfinal = false;
			goto Lswitch;

		Lswitch:
		{
			nextToken();
			check(TOKlparen);
			Expression condition2 = parseExpression();
			check(TOKrparen);
			Statement body_ = parseStatement(PSscope);
			s = new SwitchStatement(loc, condition2, body_, isfinal);
			break;
		}

		case TOKcase:
		{   Expression exp;
			Statement[] statements;
			Expression[] cases;	// array of Expression's
			Expression last = null;

			while (1)
         {
             nextToken();
             exp = parseAssignExp();
             cases ~= exp;
             if (token.value != TOKcomma)
                 break;
         }
         check(TOKcolon);

         /* case exp: .. case last:
          */
         if (token.value == TOKslice)
         {
             if (cases.length > 1)
                 error("only one case allowed for start of case range");
             nextToken();
             check(TOKcase);
             last = parseAssignExp();
             check(TOKcolon);
         }

         while (token.value != TOKcase &&
                 token.value != TOKdefault &&
			   token.value != TOKeof &&
			   token.value != TOKrcurly)
			{
			statements ~= (parseStatement(PSsemi | PScurlyscope));
			}
			s = new CompoundStatement(loc, statements);
         // Save the conversion to a "ScopeStatement" for semantic analysis
			//s = new ScopeStatement(loc, s);

			if (last)
			{
				s = new CaseRangeStatement(loc, exp, last, s);
			}
			else
			{
				// Keep cases in order by building the case statements backwards
				foreach_reverse ( i; cases )
				{
					exp = i;
					s = new CaseStatement(loc, exp, s);
				}
			}
			break;
		}

		case TOKdefault:
		{
			nextToken();
			check(TOKcolon);

			Statement[] statements;
			while (token.value != TOKcase &&
			   token.value != TOKdefault &&
			   token.value != TOKeof &&
			   token.value != TOKrcurly)
			{
			statements ~= (parseStatement(PSsemi | PScurlyscope));
			}
			s = new CompoundStatement(loc, statements);
			// convert to ScopeStatement when semantic analysis begins
         //s = new ScopeStatement(loc, s);
			s = new DefaultStatement(loc, s);
			break;
		}

		case TOKreturn:
		{   
        Expression exp;

			nextToken();
			if (token.value != TOKsemicolon)
			   exp = parseExpression();
			check(TOKsemicolon, "return statement");
			s = new ReturnStatement(loc, exp);
			break;
		}

		case TOKbreak:
		{   
          Identifier ident;
          nextToken();
          if (token.value == TOKidentifier)
          {	
              ident = token.ident;
              nextToken();
          }

          check(TOKsemicolon, "break statement");
          s = new BreakStatement(loc, ident);
          break;
      }

		case TOKcontinue:
		{   Identifier ident;

			nextToken();
			if (token.value == TOKidentifier)
			{	ident = token.ident;
			nextToken();
			}
			else
			ident = null;
			check(TOKsemicolon, "continue statement");
			s = new ContinueStatement(loc, ident);
			break;
		}

		case TOKgoto:
		{   Identifier ident;

			nextToken();
			if (token.value == TOKdefault)
			{
			nextToken();
			s = new GotoDefaultStatement(loc);
			}
			else if (token.value == TOKcase)
			{
			Expression exp = null;

			nextToken();
			if (token.value != TOKsemicolon)
				exp = parseExpression();
			s = new GotoCaseStatement(loc, exp);
			}
			else
			{
			if (token.value != TOKidentifier)
			{   error("Identifier expected following goto");
				ident = null;
			}
			else
			{   ident = token.ident;
				nextToken();
			}
			s = new GotoStatement(loc, ident);
			}
			check(TOKsemicolon, "goto statement");
			break;
		}

		case TOKsynchronized:
		{   Expression exp;
			Statement body_;

			nextToken();
			if (token.value == TOKlparen)
			{
			nextToken();
			exp = parseExpression();
			check(TOKrparen);
			}
			else
			exp = null;
			body_ = parseStatement(PSscope);
			s = new SynchronizedStatement(loc, exp, body_);
			break;
		}

		case TOKwith:
		{   Expression exp;
			Statement body_;

			nextToken();
			check(TOKlparen);
			exp = parseExpression();
			check(TOKrparen);
			body_ = parseStatement(PSscope);
			s = new WithStatement(loc, exp, body_);
			break;
		}

		case TOKtry:
		{   Statement body_;
			Catch[] catches = null;
			Statement finalbody = null;

			nextToken();
			body_ = parseStatement(PSscope);
			while (token.value == TOKcatch)
			{
				Statement handler;
				Catch c;
				Type tt;
				Identifier id;
				Loc loc2 = this.loc;

				nextToken();
				if (token.value == TOKlcurly)
				{
					tt = null;
					id = null;
				}
				else
				{
					check(TOKlparen);
					id = null;
					tt = parseType(&id);
					check(TOKrparen);
				}
				handler = parseStatement(0);
				c = new Catch(loc2, tt, id, handler);
				if (!catches)
					catches ~= c;
			}

			if (token.value == TOKfinally)
			{	nextToken();
			finalbody = parseStatement(0);
			}

			s = body_;
			if (!catches && !finalbody)
			error("catch or finally expected following try");
			else
			{	if (catches)
				s = new TryCatchStatement(loc, body_, catches);
			if (finalbody)
				s = new TryFinallyStatement(loc, s, finalbody);
			}
			break;
		}

		case TOKthrow:
		{   Expression exp;

			nextToken();
			exp = parseExpression();
			check(TOKsemicolon, "throw statement");
			s = new ThrowStatement(loc, exp);
			break;
		}

		case TOKvolatile:
			nextToken();
			s = parseStatement(PSsemi | PScurlyscope);
			if (!global.params.useDeprecated)
				error("volatile statements deprecated; used synchronized statements instead");
			s = new VolatileStatement(loc, s);
			break;

		case TOKasm:
		{   Statement[] statements;
			Identifier label;
			Loc labelloc;

			// Parse the asm block into a sequence of AsmStatements,
			// each AsmStatement is one instruction.
			// Separate out labels.
			// Defer parsing of AsmStatements until semantic processing.

			nextToken();
			check(TOKlcurly);
			Token*[] toklist;
			while (1)
			{
			switch (token.value)
			{
				case TOKidentifier:
				if (!toklist)
				{
					// Look ahead to see if it is a label
					t = peek(&token);
					if (t.value == TOKcolon)
					{   // It's a label
					label = token.ident;
					labelloc = this.loc;
					nextToken();
					nextToken();
					continue;
					}
				}
				goto Ldefault;

				case TOKrcurly:
				if (toklist || label)
				{
					error("asm statements must end in ';'");
				}
				break;

				case TOKsemicolon:
				s = null;
				if (toklist || label)
				{   // Create AsmStatement from list of tokens we've saved
					s = new AsmStatement(this.loc, toklist);
					toklist = null;
					if (label)
					{   
						s = new LabelStatement(labelloc, label, s);
						label = null;
					}
					statements ~= s;
				}
				nextToken();
				continue;

				case TOKeof:
				/*  */
				error("matching '}' expected, not end of file");
				break;

				default:
				Ldefault:


            Token* tn = newToken();
            *tn = token;
            toklist ~= tn ; 

				nextToken();
				continue;
         }
			break;
			}
			s = new CompoundStatement(loc, statements);
			nextToken();
			break;
		}
        
      case TOKimport:
      {   
         Dsymbol[] imports;
         parseImport(imports, 0);
         s = new ImportStatement(loc, imports);
         break;
      }


      default:
      error("found '%s' instead of statement", token.toChars());
      goto Lerror;

Lerror:
      while (token.value != TOKrcurly &&
            token.value != TOKsemicolon &&
            token.value != TOKeof)
         nextToken();
      if (token.value == TOKsemicolon)
         nextToken();
      s = null;
			break;
		}

		return s;
	 }

	
	/*****************************************
	 * Parse initializer for variable declaration.
	 */
    Initializer parseInitializer()
	{
		StructInitializer is_;
		ArrayInitializer ia;
		ExpInitializer ie;
		Expression e;
		Identifier id;
		Initializer value;
		int comma;
		Loc loc = this.loc;
		Token* t;
		int braces;
		int brackets;

		switch (token.value)
		{
			case TOKlcurly:
				/* Scan ahead to see if it is a struct initializer or
				 * a function literal.
				 * If it contains a ';', it is a function literal.
				 * Treat { } as a struct initializer.
				 */
				braces = 1;
				for (t = peek(&token); 1; t = peek(t))
				{
					switch (t.value)
					{
						case TOKsemicolon:
						case TOKreturn:
							goto Lexpression;

						case TOKlcurly:
							braces++;
							continue;

						case TOKrcurly:
							if (--braces == 0)
								break;
							continue;

						case TOKeof:
							break;

						default:
							continue;
					}
					break;
				}

				is_ = new StructInitializer(loc);
				nextToken();
				comma = 0;
				while (1)
				{
					switch (token.value)
					{
						case TOKidentifier:
							if (comma == 1)
								error("comma expected separating field initializers");
							t = peek(&token);
							if (t.value == TOKcolon)
							{
								id = token.ident;
								nextToken();
								nextToken();	// skip over ':'
							}
							else
							{   
								id = null;
							}
							value = parseInitializer();
							is_.addInit(id, value);
							comma = 1;
							continue;

						case TOKcomma:
							nextToken();
							comma = 2;
							continue;

						case TOKrcurly:		// allow trailing comma's
							nextToken();
							break;

						case TOKeof:
							error("found EOF instead of initializer");
							break;

						default:
							value = parseInitializer();
							is_.addInit(null, value);
							comma = 1;
							continue;
							//error("found '%s' instead of field initializer", token.toChars());
							//break;
					}
					break;
				}
				return is_;

			case TOKlbracket:
				/* Scan ahead to see if it is an array initializer or
				 * an expression.
				 * If it ends with a ';' ',' or '}', it is an array initializer.
				 */
				brackets = 1;
				for (t = peek(&token); 1; t = peek(t))
				{
					switch (t.value)
					{
						case TOKlbracket:
							brackets++;
							continue;

						case TOKrbracket:
							if (--brackets == 0)
							{   
								t = peek(t);
								if (t.value != TOKsemicolon &&
									t.value != TOKcomma &&
								t.value != TOKrcurly)
								goto Lexpression;
								break;
							}
							continue;

						case TOKeof:
							break;

						default:
							continue;
					}
					break;
				}

				ia = new ArrayInitializer(loc);
				nextToken();
				comma = 0;
				while (true)
				{
					switch (token.value)
					{
						default:
							if (comma == 1)
							{   
								error("comma expected separating array initializers, not %s", token.toChars());
								nextToken();
								break;
							}
							e = parseAssignExp();
							if (!e)
								break;
							if (token.value == TOKcolon)
							{
								nextToken();
								value = parseInitializer();
							}
							else
							{   value = new ExpInitializer(e.loc, e);
								e = null;
							}
							ia.addInit(e, value);
							comma = 1;
							continue;

						case TOKlcurly:
						case TOKlbracket:
							if (comma == 1)
								error("comma expected separating array initializers, not %s", token.toChars());
							value = parseInitializer();
							ia.addInit(null, value);
							comma = 1;
							continue;

						case TOKcomma:
							nextToken();
							comma = 2;
							continue;

						case TOKrbracket:		// allow trailing comma's
							nextToken();
							break;

						case TOKeof:
							error("found '%s' instead of array initializer", token.toChars());
							break;
					}
					break;
				}
				return ia;

			case TOKvoid:
				t = peek(&token);
				if (t.value == TOKsemicolon || t.value == TOKcomma)
				{
					nextToken();
					return new VoidInitializer(loc);
				}
				goto Lexpression;

			default:
			Lexpression:
				e = parseAssignExp();
				ie = new ExpInitializer(loc, e);
				return ie;
		}
	}
	
	/*****************************************
	 * Parses default argument initializer expression that is an assign expression,
	 * with special handling for __FILE__ and __LINE__.
	 */
    Expression parseDefaultInitExp()
	{
		if (token.value == TOKfile ||
			token.value == TOKline)
		{
			Token* t = peek(&token);
			if (t.value == TOKcomma || t.value == TOKrparen)
			{   
				Expression e;

				if (token.value == TOKfile)
					e = new FileInitExp(loc);
				else
					e = new LineInitExp(loc);
				nextToken();
				return e;
			}
		}

		Expression e = parseAssignExp();
		return e;
	}
    void check(Loc loc, TOK value)
	{
		if (token.value != value)
			error(loc, "found '%s' when expecting '%s'", token.toChars(), Token.toChars(value));
		nextToken();
	}
	
    void check(TOK value)
	{
		check(loc, value);
	}
	
    void check(TOK value, string string_)
	{
		if (token.value != value) {
			error("found '%s' when expecting '%s' following '%s'", token.toChars(), Token.toChars(value), string_);
		}
		nextToken();
	}
	
	/************************************
	 * Determine if the scanner is sitting on the start of a declaration.
	 * Input:
	 *	needId	0	no identifier
	 *		1	identifier optional
	 *		2	must have identifier
	 * Output:
	 *	if *pt is not null, it is set to the ending token, which would be endtok
	 */

    bool isDeclaration( Token* t, int needId, TOK endtok, bool save)
	{
      Token** ptsave = &t;
		int haveId = 0;

		if ((t.value == TOKconst ||
			t.value == TOKinvariant ||
			t.value == TOKimmutable ||
	        t.value == TOKwild ||
			t.value == TOKshared) &&
			peek(t).value != TOKlparen)
		{
			/* const type
			* immutable type
			* shared type
	        * wild type
			*/
			t = peek(t);
		}

		if (!isBasicType(t))
		{
   //TODO erase writelns writeln("isBasictype  == false!! "," Line: ", __LINE__);
			goto Lisnot;
		}
   //writeln("isBasicType returned true! "," Line: ", __LINE__);
      // This peek(t) wasn't in dmd
      //t = peek(t);
		if (!isDeclarator(t, haveId, endtok))
      {
			goto Lisnot;
      }
		if ( needId == 1 ||
			(needId == 0 && !haveId) ||
			(needId == 2 &&  haveId))
		{	
			if (save)
				*ptsave = t;
			goto Lis;
		}
		else
			goto Lisnot;

	Lis:
		return true;

	Lisnot:
		return false;
	}
	
    bool isBasicType( ref Token* pt)
	{
		// This code parallels parseBasicType()
		Token* t = pt;
		Token* t2;
		int parens;
		int haveId = 0;

		switch (t.value)
		{
          case TOKwchar:
          case TOKdchar:
          case TOKbit:
          case TOKbool:
          case TOKchar:
          case TOKint8:
          case TOKuns8:
          case TOKint16:
          case TOKuns16:
          case TOKint32:
          case TOKuns32:
          case TOKint64:
          case TOKuns64:
          case TOKfloat32:
          case TOKfloat64:
          case TOKfloat80:
          case TOKimaginary32:
          case TOKimaginary64:
          case TOKimaginary80:
          case TOKcomplex32:
          case TOKcomplex64:
          case TOKcomplex80:
          case TOKvoid:
              t = peek(t);
              break;

          case TOKidentifier:
    L5:
              t = peek(t);
			if (t.value == TOKnot)
			{
			goto L4;
			}
			goto L3;
			while (1)
			{
    L2:
			t = peek(t);
		L3:
			if (t.value == TOKdot)
			{
		Ldot:
				t = peek(t);
				if (t.value != TOKidentifier)
				goto Lfalse;
				t = peek(t);
				if (t.value != TOKnot)
				goto L3;
		L4:
				/* Seen a !
				 * Look for:
				 * !( args ), !identifier, etc.
				 */
				t = peek(t);
            switch (t.value)
            {	
                case TOKidentifier:
                    goto L5;
                case TOKlparen:
                    if ( !skipParens(t) )
                        goto Lfalse;
                    break;
				case TOKwchar: case TOKdchar:
				case TOKbit: case TOKbool: case TOKchar:
				case TOKint8: case TOKuns8:
				case TOKint16: case TOKuns16:
				case TOKint32: case TOKuns32:
				case TOKint64: case TOKuns64:
				case TOKfloat32: case TOKfloat64: case TOKfloat80:
				case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:
				case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:
				case TOKvoid:
				case TOKint32v:
				case TOKuns32v:
				case TOKint64v:
				case TOKuns64v:
				case TOKfloat32v:
				case TOKfloat64v:
				case TOKfloat80v:
				case TOKimaginary32v:
				case TOKimaginary64v:
				case TOKimaginary80v:
				case TOKnull:
				case TOKtrue:
				case TOKfalse:
				case TOKcharv:
				case TOKwcharv:
				case TOKdcharv:
				case TOKstring:
				case TOKfile:
				case TOKline:
					goto L2;
				default:
					goto Lfalse;
				}
			}
			else
				break;
			}
			break;

		case TOKdot:
			goto Ldot;

		case TOKtypeof:
			/* typeof(exp).identifier...
			 */
			t = peek(t);
			if (t.value != TOKlparen)
         {
            goto Lfalse;
			}
         if ( !skipParens(t) )
         {
            goto Lfalse;
			}
         goto L2;

		case TOKconst:
		case TOKinvariant:
		case TOKimmutable:
		case TOKshared:
    	case TOKwild:
			// const(type)  or  immutable(type)  or  shared(type)  or  wild(type)
			t = peek(t);
			if (t.value != TOKlparen)
			goto Lfalse;
			t = peek(t);
			if (!isDeclaration(t, 0, TOKrparen, true))
			{
			goto Lfalse;
			}
			t = peek(t);
			break;

		default:
			goto Lfalse;
		}
      
		pt = t;
		//printf("is\n");
		return true;

	Lfalse:
		//printf("is not\n");
		return false;
	}
	
    bool isDeclarator(ref Token* pt, ref int haveId, TOK endtok)
	{
		// This code parallels parseDeclarator()
		Token* t = pt;
		bool parens;

		if (t.value == TOKassign)
			return false;

		while (true)
		{
			parens = false;
			switch (t.value)
			{
				case TOKmul:
				//case TOKand:
					t = peek(t);
					continue;

				case TOKlbracket:
					t = peek(t);
					if (t.value == TOKrbracket)
					{
						t = peek(t);
					}
					else if (t.value == TOKnew && peek(t).value == TOKrbracket)
					{
						t = peek(t);
						t = peek(t);
					}
					else if (isDeclaration(t, 0, TOKrbracket, true))
					{   
						// It's an associative array declaration
						t = peek(t);
					}
					else
					{
						// [ expression ]
						// [ expression .. expression ]
						if (!isExpression(t))
							return false;
						if (t.value == TOKslice)
						{	
							t = peek(t);
							if (!isExpression(t))
								return false;
						}
						if (t.value != TOKrbracket)
							return false;
						t = peek(t);
					}
					continue;

				case TOKidentifier:
					if (haveId)
               {
						return false;
               }
					haveId = true;
					t = peek(t);
					break;

				case TOKlparen:
					t = peek(t);

					if (t.value == TOKrparen)
						return false;		// () is not a declarator

					/* Regard ( identifier ) as not a declarator
					 * BUG: what about ( *identifier ) in
					 *	f(*p)(x);
					 * where f is a class instance with overloaded () ?
					 * Should we just disallow C-style function pointer declarations?
					 */
					if (t.value == TOKidentifier)
					{   
						Token* t2 = peek(t);
						if (t2.value == TOKrparen)
							return false;
					}

					if (!isDeclarator(t, haveId, TOKrparen))
						return false;
					t = peek(t);
					parens = true;
					break;

				case TOKdelegate:
				case TOKfunction:
					t = peek(t);
					if (!isParameters(t))
						return false;
					continue;
				default:
					break;	///
			}
			break;
		}

        while (1)
        {
            switch (t.value)
            {
                version (CARRAYDECL) 
                {
                case TOKlbracket:
                    parens = false;
                    t = peek(t);
                    if (t.value == TOKrbracket)
                    {
                        t = peek(t);
                    }
                    else if (isDeclaration(t, 0, TOKrbracket, true))
                    {   
                        // It's an associative array declaration
                        t = peek(t);
                    }
                    else
                    {
                        // [ expression ]
                        if (!isExpression(t))
                            return false;
                        if (t.value != TOKrbracket)
                            return false;
                        t = peek(t);
                    }
                    continue;
                } //end version (CARRAYDECL)

                case TOKlparen:
                parens = false;
                if (!isParameters(t))
                    return false;
                while (true)
                {
                    switch (t.value)
                    {
                        case TOKconst:
                        case TOKinvariant:
                        case TOKimmutable:
                        case TOKshared:
                        case TOKwild:
                        case TOKpure:
                        case TOKnothrow:
                            t = peek(t);
                            continue;
                        case TOKat:
                            t = peek(t);	// skip '@'
                            t = peek(t);	// skip identifier
                            continue;
                        default:
                            break;
                    }
                    break;
                }
                continue;

                // Valid tokens that follow a declaration
              case TOKrparen:
              case TOKrbracket:
              case TOKassign:
              case TOKcomma:
              case TOKsemicolon:
              case TOKlcurly:
              case TOKin:
              // The !parens is to disallow unnecessary parentheses
              if (!parens && (endtok == TOKreserved || endtok == t.value))
              {   
                  pt = t;
                  return true;
              }
              return false;

              default:
              return false;
          }
      }
   }

    bool isParameters( Token* pt)
    {
        // This code parallels parseParameters()
        Token* t = pt;

        //printf("isParameters()\n");
        if (t.value != TOKlparen)
            return false;

        t = peek(t);
        for (;1; t = peek(t))
        {
L1:
            switch (t.value)
            {
                case TOKrparen:
                    break;

                case TOKdotdotdot:
                    t = peek(t);
                    break;

                case TOKin:
                case TOKout:
                case TOKref:
                case TOKlazy:
                case TOKfinal:
                case TOKauto:
                    continue;

                case TOKconst:
                case TOKinvariant:
                case TOKimmutable:
                case TOKshared:
                case TOKwild:
                    t = peek(t);
                    if (t.value == TOKlparen)
                    {
                        t = peek(t);
                        if (!isDeclaration(t, 0, TOKrparen, true))
                            return false;
                        t = peek(t);	// skip past closing ')'
                        goto L2;
                    }
                    goto L1;

                    static if (false) {
                        case TOKstatic:
                            continue;
                        case TOKauto:
                        case TOKalias:
                            t = peek(t);
                            if (t.value == TOKidentifier)
                                t = peek(t);
                            if (t.value == TOKassign)
                            {   t = peek(t);
                                if (!isExpression(t))
                                    return false;
                            }
                            goto L3;
                    }

                default:
                    {	
                        if (!isBasicType(t))
                            return false;
L2:
                        int tmp = false;
                        if (t.value != TOKdotdotdot &&
                                !isDeclarator(t, tmp, TOKreserved))
                            return false;
                        if (t.value == TOKassign)
                        {
                            t = peek(t);
                            if (!isExpression(t))
                                return false;
                        }
                        if (t.value == TOKdotdotdot)
                        {
                            t = peek(t);
                            break;
                        }
                    }
L3:
                    if (t.value == TOKcomma)
                    {
                        continue;
                    }
                    break;
            }
            break;
        }

        if (t.value != TOKrparen)
            return false;

        t = peek(t);
        pt = t;
        return true;
    }

bool isExpression( Token* pt)
{
    // This is supposed to determine if something is an expression.
    // What it actually does is scan until a closing right bracket
    // is found.

    Token* t = pt;
    int brnest = 0;
    int panest = 0;
    int curlynest = 0;

    for (;; t = peek(t))
    {
        switch (t.value)
        {
            case TOKlbracket:
                brnest++;
                continue;

            case TOKrbracket:
					if (--brnest >= 0)
						continue;
					break;

				case TOKlparen:
					panest++;
					continue;

				case TOKcomma:
					if (brnest || panest)
						continue;
					break;

				case TOKrparen:
					if (--panest >= 0)
						continue;
					break;

				case TOKlcurly:
					curlynest++;
					continue;

				case TOKrcurly:
					if (--curlynest >= 0)
						continue;
					return false;

				case TOKslice:
					if (brnest)
						continue;
					break;

				case TOKsemicolon:
					if (curlynest)
						continue;
					return false;

				case TOKeof:
					return false;

				default:
					continue;
			}
			break;
		}

		pt = t;
		return true;
}
	
    int isTemplateInstance(Token* t, Token* pt)
	{
		assert(false);
	}
	
	/*******************************************
	 * Skip parens, brackets.
	 * Input:
	 *	t is on opening (
	 * Output:
	 *	*pt is set to closing token, which is ')' on success
	 * Returns:
	 *	!=0	successful
	 *	0	some parsing error
	 */
    // the second param has always been called with &firstparam
    // I don't understand why the original had two parameters...?
    bool skipParens( ref Token* t)
	{
		int parens = 0;
      Token** save = &t;
      assert(save, "skipParens.save was false... what a weird routine!");

		while (1)
		{
			switch (t.value)
			{
				case TOKlparen:
					parens++;
					break;

				case TOKrparen:
					parens--;
					if (parens < 0)
						goto Lfalse;
					if (parens == 0)
						goto Ldone;
					break;

				case TOKeof:
				case TOKsemicolon:
					goto Lfalse;

				default:
					break;
			}
			t = peek(t);
		}

	  Ldone:
		return true;

	  Lfalse:
		if (save)
			t = *save;
		return false;
	}
    /+++++++++++++++++++++++++++++++++++++++++++
     + Skip attributes.
     + Input:
     +      t is on a candidate attribute
     + Output:
     +      +pt is set to first non-attribute token on success
     + Returns:
     +      !=0     successful
     +      0       some parsing error
     +/

    int skipAttributes(Token *t)
    {
        Token** save = &t;
        while (1)
        {
            switch (t.value)
            {
                case TOKconst:
                case TOKinvariant:
                case TOKimmutable:
                case TOKshared:
                case TOKwild:
                case TOKfinal:
                case TOKauto:
                case TOKscope:
                case TOKoverride:
                case TOKabstract:
                case TOKsynchronized:
                case TOKdeprecated:
                case TOKnothrow:
                case TOKpure:
                case TOKref:
                case TOKtls:
                case TOKgshared:
                    //case TOKmanifest:
                    break;
                case TOKat:
                    t = peek(t);
                    if (t.value == TOKidentifier)
                        break;
                    goto Lerror;
                default:
                    goto Ldone;
            }
            t = peek(t);
        }

Ldone:
        if (*save)
            *save = t;
        return 1;

Lerror:
        return 0;
    }

   Expression parseExpression()
   {
      Expression e;
      Expression e2;
      Loc loc = this.loc;

      //printf("Parser.parseExpression() loc = %d\n", loc.linnum);
      e = parseAssignExp();
      while (token.value == TOKcomma)
      {
         nextToken();
         e2 = parseAssignExp();
         e = new CommaExp(loc, e, e2);
         loc = this.loc;
      }
      return e;
   }

   Expression parsePrimaryExp()
   {
      Expression e;
      Type t;
      Identifier id;
      TOK save;
      Loc loc = this.loc;

      //printf("parsePrimaryExp(): loc = %d\n", loc.linnum);
      switch (token.value)
      {
         case TOKidentifier:
            id = token.ident;
            nextToken();
            if (token.value == TOKnot && peekNext() != TOKis)
            {	// identifier!(template-argument-list)
               TemplateInstance tempinst;

               tempinst = new TemplateInstance(loc, id);
               nextToken();
               if (token.value == TOKlparen)
                  // ident!(template_arguments)
                  tempinst.tiargs = parseTemplateArgumentList();
                else
                    // ident!template_argument
                    tempinst.tiargs = parseTemplateArgument();
                e = new ScopeExp(loc, tempinst);
            }
            else
                e = new IdentifierExp(loc, id);
            break;

         case TOKdollar:
            if (!inBrackets)
               error("'$' is valid only inside [] of index or slice");
            e = new DollarExp(loc);
            nextToken();
            break;

         case TOKdot:
            // Signal global scope '.' operator with "" identifier
            e = new IdentifierExp(loc, Id.empty);
            break;

         case TOKthis:
            e = new ThisExp(loc);
            nextToken();
            break;

         case TOKsuper:
            e = new SuperExp(loc);
            nextToken();
            break;

         case TOKint32v:
            e = new IntegerExp(loc, token.int32value, Type.tint32);
            nextToken();
            break;

         case TOKuns32v:
            e = new IntegerExp(loc, token.uns32value, Type.tuns32);
            nextToken();
            break;

         case TOKint64v:
            e = new IntegerExp(loc, token.int64value, Type.tint64);
            nextToken();
            break;

         case TOKuns64v:
            e = new IntegerExp(loc, token.uns64value, Type.tuns64);
            nextToken();
            break;

         case TOKfloat32v:
            e = new RealExp(loc, token.float80value, Type.tfloat32);
            nextToken();
            break;

         case TOKfloat64v:
            e = new RealExp(loc, token.float80value, Type.tfloat64);
            nextToken();
            break;

         case TOKfloat80v:
            e = new RealExp(loc, token.float80value, Type.tfloat80);
            nextToken();
            break;

         case TOKimaginary32v:
            e = new RealExp(loc, token.float80value, Type.timaginary32);
            nextToken();
            break;

         case TOKimaginary64v:
            e = new RealExp(loc, token.float80value, Type.timaginary64);
            nextToken();
            break;

         case TOKimaginary80v:
            e = new RealExp(loc, token.float80value, Type.timaginary80);
            nextToken();
            break;

         case TOKnull:
            e = new NullExp(loc);
            nextToken();
            break;

         case TOKfile:
            {
               string s = loc.filename ? loc.filename : mod.ident.toChars();
               e = new StringExp(loc, s, 0);
               nextToken();
               break;
            }

         case TOKline:
            e = new IntegerExp(loc, loc.linnum, Type.tint32);
            nextToken();
            break;

         case TOKtrue:
            e = new IntegerExp(loc, 1, Type.tbool);
            nextToken();
            break;

         case TOKfalse:
            e = new IntegerExp(loc, 0, Type.tbool);
            nextToken();
            break;

         case TOKcharv:
            e = new IntegerExp(loc, token.uns32value, Type.tchar);
            nextToken();
            break;

         case TOKwcharv:
            e = new IntegerExp(loc, token.uns32value, Type.twchar);
            nextToken();
            break;

         case TOKdcharv:
			e = new IntegerExp(loc, token.uns32value, Type.tdchar);
			nextToken();
         break;

         case TOKstring:
         {  
            string s;
            char postfix;

            // cat adjacent strings
            s = token.ustring;
            postfix = token.postfix;
            while (1)
            {
               nextToken();
               if (token.value == TOKstring)
               {   
                  if (token.postfix)
                  {	
                     if (token.postfix != postfix)
                        error("mismatched string literal postfixes '%c' and '%c'", postfix, token.postfix);
                     postfix = token.postfix;
                  }
                  s ~= token.ustring;
               }
               else
                  break;
            }
            e = new StringExp(loc, assumeUnique(s), postfix);
            break;
         }

         case TOKvoid:	 t = Type.tvoid;  goto LabelX;
         case TOKint8:	 t = Type.tint8;  goto LabelX;
         case TOKuns8:	 t = Type.tuns8;  goto LabelX;
         case TOKint16:	 t = Type.tint16; goto LabelX;
         case TOKuns16:	 t = Type.tuns16; goto LabelX;
         case TOKint32:	 t = Type.tint32; goto LabelX;
         case TOKuns32:	 t = Type.tuns32; goto LabelX;
         case TOKint64:	 t = Type.tint64; goto LabelX;
         case TOKuns64:	 t = Type.tuns64; goto LabelX;
         case TOKfloat32: t = Type.tfloat32; goto LabelX;
         case TOKfloat64: t = Type.tfloat64; goto LabelX;
         case TOKfloat80: t = Type.tfloat80; goto LabelX;
         case TOKimaginary32: t = Type.timaginary32; goto LabelX;
         case TOKimaginary64: t = Type.timaginary64; goto LabelX;
         case TOKimaginary80: t = Type.timaginary80; goto LabelX;
         case TOKcomplex32: t = Type.tcomplex32; goto LabelX;
         case TOKcomplex64: t = Type.tcomplex64; goto LabelX;
         case TOKcomplex80: t = Type.tcomplex80; goto LabelX;
         case TOKbit:	 t = Type.tbit;     goto LabelX;
         case TOKbool:	 t = Type.tbool;    goto LabelX;
         case TOKchar:	 t = Type.tchar;    goto LabelX;
         case TOKwchar:	 t = Type.twchar; goto LabelX;
         case TOKdchar:	 t = Type.tdchar; goto LabelX;
		LabelX:
			   nextToken();
		L1:
			   check(TOKdot, t.toChars());
			   if (token.value != TOKidentifier)
			   {   
               error("found '%s' when expecting identifier following '%s.'", token.toChars(), t.toChars());
			      goto Lerr;
			   }
			   e = typeDotIdExp(loc, t, token.ident);
			   nextToken();
			   break;

         case TOKtypeof:
		   {
            t = parseTypeof();
            e = new TypeExp(loc, t);
            break;
         }

		   case TOKtypeid:
		   {
            nextToken();
            check(TOKlparen, "typeid");
            Dobject o;
            if (isDeclaration(&token, 0, TOKreserved, false))
            {	// argument is a type
               o = parseType();
            }
            else
            {	// argument is an expression
               o = parseAssignExp();
            }
            check(TOKrparen);
            e = new TypeidExp(loc, o);
            break;
         }

         case TOKtraits:
         {   /* __traits(identifier, args...)
              */
            Identifier ident;
            Dobject[] args = null;

            nextToken();
            check(TOKlparen);
            if (token.value != TOKidentifier)
            {   
               error("__traits(identifier, args...) expected");
               goto Lerr;
            }
            ident = token.ident;
            nextToken();
            if (token.value == TOKcomma)
               args = parseTemplateArgumentList2();	// __traits(identifier, args...)
            else
               check(TOKrparen);		// __traits(identifier)

            e = new TraitsExp(loc, ident, args);
            break;
         }

         case TOKis:
		   {   
            Type targ;
            Identifier ident = null;
            Type tspec = null;
            TOK tok = TOKreserved;
            TOK tok2 = TOKreserved;
            TemplateParameter[] tpl = null;
            Loc loc2 = this.loc;

            nextToken();
            if (token.value == TOKlparen)
            {
               nextToken();
               targ = parseType(&ident);
               if (token.value == TOKcolon || token.value == TOKequal)
               {
                  tok = token.value;
                  nextToken();
                  if (tok == TOKequal &&
                        (
                         token.value == TOKtypedef ||
                         token.value == TOKstruct ||
                         token.value == TOKunion ||
                         token.value == TOKclass ||
                    token.value == TOKsuper ||
                    token.value == TOKenum ||
                    token.value == TOKinterface ||
                    token.value == TOKconst && peek(&token).value == TOKrparen ||
                    token.value == TOKinvariant && peek(&token).value == TOKrparen ||
                    token.value == TOKimmutable && peek(&token).value == TOKrparen ||
                    token.value == TOKshared && peek(&token).value == TOKrparen ||
                    token.value == TOKwild && peek(&token).value == TOKrparen ||
                    token.value == TOKfunction ||
                    token.value == TOKdelegate ||
                    token.value == TOKreturn))
                {
                    tok2 = token.value;
                    nextToken();
                }
                else
                {
                    tspec = parseType();
                }
            }
            if (ident && tspec)
            {
                if (token.value == TOKcomma)
                    tpl = parseTemplateParameterList(1);
                else
                {	
                    check(TOKrparen);
                }
                TemplateParameter tp = new TemplateTypeParameter(loc2, ident, null, null);
                tpl.insert(0, tp);
            }
            else
                check(TOKrparen);
         }
         else
         {   error("(type identifier : specialization) expected following is");
             goto Lerr;
         }
         e = new IsExp(loc2, targ, ident, tok, tspec, tok2, tpl);
         break;
      }

      case TOKassert:
      {   
          Expression msg = null;

          nextToken();
          check(TOKlparen, "assert");
          e = parseAssignExp();
          if (token.value == TOKcomma)
			{	nextToken();
			msg = parseAssignExp();
			}
			check(TOKrparen);
			e = new AssertExp(loc, e, msg);
			break;
		}

      case TOKmixin:
      {
          nextToken();
          check(TOKlparen, "mixin");
          e = parseAssignExp();
          check(TOKrparen);
          e = new CompileExp(loc, e);
          break;
      }

		case TOKimport:
      {
          nextToken();
          check(TOKlparen, "import");
          e = parseAssignExp();
          check(TOKrparen);
          e = new FileExp(loc, e);
          break;
		}

		case TOKlparen:
			if (peekPastParen(&token).value == TOKlcurly)
			{	// (arguments) { statements... }
			save = TOKdelegate;
			goto case_delegate;
			}
			// ( expression )
			nextToken();
			e = parseExpression();
			check(loc, TOKrparen);
			break;

		case TOKlbracket:
		{   /* Parse array literals and associative array literals:
			 *	[ value, value, value ... ]
			 *	[ key:value, key:value, key:value ... ]
			 */
			Expression[] values;
			Expression[] keys;

			nextToken();
			if (token.value != TOKrbracket)
			{
			while (token.value != TOKeof)
			{
				Expression e2 = parseAssignExp();
				if (token.value == TOKcolon && (keys || values.length == 0))
				{	
					nextToken();
					keys ~= (e2);
					e2 = parseAssignExp();
				}
				else if (keys)
				{	
					error("'key:value' expected for associative array literal");
					//delete keys;
					keys = null;
				}
				values ~= (e2);
				if (token.value == TOKrbracket)
					break;
				check(TOKcomma);
			}
			}
			check(TOKrbracket);

			if (keys)
				e = new AssocArrayLiteralExp(loc, keys, values);
			else
				e = new ArrayLiteralExp(loc, values);
			break;
		}

		case TOKlcurly:
			// { statements... }
			save = TOKdelegate;
			goto case_delegate;

		case TOKfunction:
		case TOKdelegate:
			save = token.value;
			nextToken();
		case_delegate:
        {
			/* function type(parameters) { body } pure nothrow
			 * delegate type(parameters) { body } pure nothrow
			 * (parameters) { body }
			 * { body }
			 */
			Parameter[] arguments;
			int varargs;
			FuncLiteralDeclaration fd;
			Type tt;
			bool isnothrow = false;
			bool ispure = false;
	        bool isproperty = false;
	        TRUST trust = TRUSTdefault;
            
			if (token.value == TOKlcurly)
         {
             tt = null;
             varargs = 0;
         }
			else
         {
             if (token.value == TOKlparen)
                 tt = null;
             else
             {
                 tt = parseBasicType();
                 tt = parseBasicType2(tt);	// function return type
             }
             arguments = parseParameters(varargs);
             while (1)
             {
                 if (token.value == TOKpure)
                     ispure = true;
                 else if (token.value == TOKnothrow)
                     isnothrow = true;
                 else if (token.value == TOKat)
                 {
                     StorageClass stc = parseAttribute();
                     switch (cast(uint)(stc >> 32))
                     {
                         case STCproperty >> 32:
                             isproperty = true;
                             break;
                         case STCsafe >> 32:
                             trust = TRUSTsafe;
                             break;
                         case STCsystem >> 32:
                             trust = TRUSTsystem;
                             break;
                         case STCtrusted >> 32:
                             trust = TRUSTtrusted;
                             break;
                         case 0:
                             break;
                         default:
                             assert(0);
                     }
                 }
                 else
                     break;
                 nextToken();
             }
         }

         TypeFunction tf = new TypeFunction(arguments, tt, varargs, linkage);
         tf.ispure = ispure;
         tf.isnothrow = isnothrow;
         tf.isproperty = isproperty;
         tf.trust = trust;
         fd = new FuncLiteralDeclaration(loc, Loc(0), tf, save, null);
         parseContracts(fd);
         e = new FuncExp(loc, fd);
         break;
    }

      default:
      error("expression expected, not '%s'", token.toChars());
Lerr:
      // Anything for e, as long as it's not null
      e = new IntegerExp(loc, 0, Type.tint32);
      nextToken();
      break;
      }
      return e;
   }

    Expression parseUnaryExp()
    {
        Expression e;
        Loc loc = this.loc;

        switch (token.value)
        {
            case TOKand:
                nextToken();
                e = parseUnaryExp();
                e = new AddrExp(loc, e);
                break;

            case TOKplusplus:
                nextToken();
                e = parseUnaryExp();
                e = new AddAssignExp(loc, e, new IntegerExp(loc, 1, Type.tint32));
                break;

            case TOKminusminus:
                nextToken();
                e = parseUnaryExp();
                e = new MinAssignExp(loc, e, new IntegerExp(loc, 1, Type.tint32));
                break;

            case TOKmul:
                nextToken();
                e = parseUnaryExp();
                e = new PtrExp(loc, e);
                break;

            case TOKmin:
                nextToken();
                e = parseUnaryExp();
                e = new NegExp(loc, e);
                break;

            case TOKadd:
                nextToken();
                e = parseUnaryExp();
                e = new UAddExp(loc, e);
                break;

            case TOKnot:
                nextToken();
                e = parseUnaryExp();
                e = new NotExp(loc, e);
                break;

            case TOKtilde:
                nextToken();
                e = parseUnaryExp();
                e = new ComExp(loc, e);
                break;

            case TOKdelete:
                nextToken();
                e = parseUnaryExp();
                e = new DeleteExp(loc, e);
                break;

            case TOKnew:
                e = parseNewExp(null);
                break;

            case TOKcast:				// cast(type) expression
                {
                    nextToken();
                    check(TOKlparen);
                    /* Look for cast(), cast(const), cast(immutable),
                     * cast(shared), cast(shared const), cast(wild), cast(shared wild)
                     */
                    MOD m;
                    if (token.value == TOKrparen)
                    {
                        m = MODundefined;
                        goto Lmod1;
                    }
                    else if (token.value == TOKconst && peekNext() == TOKrparen)
                    {
                        m = MODconst;
                        goto Lmod2;
                    }
                    else if ((token.value == TOKimmutable || token.value == TOKinvariant) && peekNext() == TOKrparen)
                    {
                        m = MODimmutable;
                        goto Lmod2;
                    }
                    else if (token.value == TOKshared && peekNext() == TOKrparen)
                    {
                        m = MODshared;
                        goto Lmod2;
                    }
                    else if (token.value == TOKwild && peekNext() == TOKrparen)
                    {
                        m = MODwild;
                        goto Lmod2;
                    }
                    else if (token.value == TOKwild && peekNext() == TOKshared && peekNext2() == TOKrparen ||
                            token.value == TOKshared && peekNext() == TOKwild && peekNext2() == TOKrparen)
                    {
                        m = MODshared | MODwild;
                    goto Lmod3;
                }
                else if (token.value == TOKconst && peekNext() == TOKshared && peekNext2() == TOKrparen ||
                        token.value == TOKshared && peekNext() == TOKconst && peekNext2() == TOKrparen)
                {
                    m = MODshared | MODconst;
Lmod3:
                    nextToken();
Lmod2:
                    nextToken();
Lmod1:
                    nextToken();
                    e = parseUnaryExp();
                    e = new CastExp(loc, e, m);
                }
                else
                {
                    Type t = parseType();		// ( type )
                    check(TOKrparen);
                    e = parseUnaryExp();
                    e = new CastExp(loc, e, t);
                }
                break;
            }

            case TOKlparen:
            {   Token* tk;

                tk = peek(&token);
                version (CCASTSYNTAX) 
                {
                    // If cast
                    if (isDeclaration(tk, 0, TOKrparen, true))
                    {
                        tk = peek(tk);		// skip over right parenthesis
                        switch (tk.value)
                        {
                        case TOKnot:
                            tk = peek(tk);
                            if (tk.value == TOKis)	// !is
                                break;
                        case TOKdot:
                        case TOKplusplus:
                        case TOKminusminus:
                        case TOKdelete:
                        case TOKnew:
                        case TOKlparen:
                        case TOKidentifier:
                        case TOKthis:
                        case TOKsuper:
                        case TOKint32v:
                        case TOKuns32v:
                        case TOKint64v:
                        case TOKuns64v:
                        case TOKfloat32v:
                        case TOKfloat64v:
                        case TOKfloat80v:
                        case TOKimaginary32v:
                        case TOKimaginary64v:
                        case TOKimaginary80v:
                        case TOKnull:
                        case TOKtrue:
                        case TOKfalse:
                        case TOKcharv:
                        case TOKwcharv:
                        case TOKdcharv:
                        case TOKstring:
                        static if (false) {
                            case TOKtilde:
                            case TOKand:
                            case TOKmul:
                            case TOKmin:
                            case TOKadd:
                        }
                        case TOKfunction:
                        case TOKdelegate:
                        case TOKtypeof:
                        case TOKfile:
                        case TOKline:
                        case TOKwchar: case TOKdchar:
                        case TOKbit: case TOKbool: case TOKchar:
                        case TOKint8: case TOKuns8:
                        case TOKint16: case TOKuns16:
                        case TOKint32: case TOKuns32:
                        case TOKint64: case TOKuns64:
                        case TOKfloat32: case TOKfloat64: case TOKfloat80:
                        case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:
                        case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:
                        case TOKvoid:		// (type)int.size
                        {	
                            // (type) una_exp
                            nextToken();
                            Type t = parseType();
                            check(TOKrparen);

                            // if .identifier
                            if (token.value == TOKdot)
                            {
                                nextToken();
                                if (token.value != TOKidentifier)
                                {   
                                    error("Identifier expected following (type).");
                                    return null;
                                }
                                e = typeDotIdExp(loc, t, token.ident);
                                nextToken();
                                e = parsePostExp(e);
                            }
                            else
                            {
                                e = parseUnaryExp();
                                e = new CastExp(loc, e, t);
                                error("C style cast illegal, use %s", e.toChars());
                            }
                            return e;
                        }

                        default:
                        break;	///
                        } /+ switch(tk.value) +/
                    } /+ if(isDeclaration) +/
                } /+ version(CCASTSYNTAX) +/
                e = parsePrimaryExp();
                e = parsePostExp(e);
                break;
            }
            default:
            e = parsePrimaryExp();
            e = parsePostExp(e);
            break;
        }
        assert(e);

        // ^^ is right associative and has higher precedence than the unary operators
        while (token.value == TOKpow)
        {
	        nextToken();
	        Expression e2 = parseUnaryExp();
	        e = new PowExp(loc, e, e2);
        }

		return e;
	}
	
    Expression parsePostExp(Expression e)
	{
		Loc loc;

		while (1)
		{
		loc = this.loc;
		switch (token.value)
		{
			case TOKdot:
			nextToken();
			if (token.value == TOKidentifier)
			{   Identifier id = token.ident;

				nextToken();
				if (token.value == TOKnot && peekNext() != TOKis)
				{   // identifier!(template-argument-list)
				TemplateInstance tempinst = new TemplateInstance(loc, id);
			    Dobject[] tiargs;
				nextToken();
				if (token.value == TOKlparen)
					// ident!(template_arguments)
					tiargs = parseTemplateArgumentList();
				else
					// ident!template_argument
					tiargs = parseTemplateArgument();
				e = new DotTemplateInstanceExp(loc, e, id, tiargs);
				}
				else
				e = new DotIdExp(loc, e, id);
				continue;
			}
			else if (token.value == TOKnew)
			{
				e = parseNewExp(e);
				continue;
			}
			else
				error("identifier expected following '.', not '%s'", token.toChars());
			break;

			case TOKplusplus:
			e = new PostExp(TOKplusplus, loc, e);
			break;

			case TOKminusminus:
			e = new PostExp(TOKminusminus, loc, e);
			break;

			case TOKlparen:
			e = new CallExp(loc, e, parseArguments());
			continue;

			case TOKlbracket:
			{	// array dereferences:
			//	array[index]
			//	array[]
			//	array[lwr .. upr]
			Expression index;
			Expression upr;

			inBrackets++;
			nextToken();
			if (token.value == TOKrbracket)
			{   // array[]
				e = new SliceExp(loc, e, null, null);
				nextToken();
			}
			else
			{
				index = parseAssignExp();
				if (token.value == TOKslice)
				{	// array[lwr .. upr]
				nextToken();
				upr = parseAssignExp();
				e = new SliceExp(loc, e, index, upr);
				}
				else
				{	// array[index, i2, i3, i4, ...]
				Expression[] arguments;
				arguments ~= (index);
				if (token.value == TOKcomma)
				{
					nextToken();
					while (1)
					{   Expression arg;

					arg = parseAssignExp();
					arguments ~= (arg);
					if (token.value == TOKrbracket)
						break;
					check(TOKcomma);
					}
				}
				e = new ArrayExp(loc, e, arguments);
				}
				check(TOKrbracket);
				inBrackets--;
			}
			continue;
			}

			default:
			return e;
		}
		nextToken();
		}
		
		assert(false);
	}
	
    Expression parseMulExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseUnaryExp();
		while (1)
		{
			switch (token.value)
			{
				case TOKmul: nextToken(); e2 = parseUnaryExp(); e = new MulExp(loc,e,e2); continue;
	            case TOKdiv: nextToken(); e2 = parseUnaryExp(); e = new DivExp(loc,e,e2); continue;
	            case TOKmod: nextToken(); e2 = parseUnaryExp(); e = new ModExp(loc,e,e2); continue;

				default:
				break;
			}
			break;
		}
		return e;
	}
	
    Expression parseAddExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseMulExp();
		while (1)
		{
			switch (token.value)
			{
				case TOKadd:    nextToken(); e2 = parseMulExp(); e = new AddExp(loc,e,e2); continue;
				case TOKmin:    nextToken(); e2 = parseMulExp(); e = new MinExp(loc,e,e2); continue;
				case TOKtilde:  nextToken(); e2 = parseMulExp(); e = new CatExp(loc,e,e2); continue;

				default:
				break;
			}
			break;
		}
		return e;
	}
	
    Expression parseShiftExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAddExp();
		while (1)
		{
			switch (token.value)
			{
				case TOKshl:  nextToken(); 
                e2 = parseAddExp(); 
                e = new ShlExp(loc,e,e2);  continue;
				case TOKshr:  nextToken(); 
                e2 = parseAddExp(); 
                e = new ShrExp(loc,e,e2);  continue;
				case TOKushr: nextToken(); 
                e2 = parseAddExp(); 
                e = new UshrExp(loc,e,e2); continue;
				default:
                break;
			}
			break;
		}
		return e;
	}
	
    Expression parseRelExp()
	{
		assert(false);
	}
	
    Expression parseEqualExp()
	{
		assert(false);
	}
	
    Expression parseCmpExp()
	{
		Expression e;
		Expression e2;
		Token* t;
		Loc loc = this.loc;

		e = parseShiftExp();
		TOK op = token.value;

		switch (op)
		{
		case TOKequal:
		case TOKnotequal:
			nextToken();
			e2 = parseShiftExp();
			e = new EqualExp(op, loc, e, e2);
			break;

		case TOKis:
			op = TOKidentity;
			goto L1;

		case TOKnot:
			// Attempt to identify '!is'
			t = peek(&token);
			if (t.value != TOKis)
			break;
			nextToken();
			op = TOKnotidentity;
			goto L1;

		L1:
			nextToken();
			e2 = parseShiftExp();
			e = new IdentityExp(op, loc, e, e2);
			break;

		case TOKlt:
		case TOKle:
		case TOKgt:
		case TOKge:
		case TOKunord:
		case TOKlg:
		case TOKleg:
		case TOKule:
		case TOKul:
		case TOKuge:
		case TOKug:
		case TOKue:
			nextToken();
			e2 = parseShiftExp();
			e = new CmpExp(op, loc, e, e2);
			break;

		case TOKin:
			nextToken();
			e2 = parseShiftExp();
			e = new InExp(loc, e, e2);
			break;

		default:
			break;
		}
		return e;
	}
	
    Expression parseAndExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		if (global.params.Dversion == 1)
		{
			e = parseEqualExp();
			while (token.value == TOKand)
			{
				nextToken();
				e2 = parseEqualExp();
				e = new AndExp(loc,e,e2);
				loc = this.loc;
			}
		}
		else
		{
			e = parseCmpExp();
			while (token.value == TOKand)
			{
				nextToken();
				e2 = parseCmpExp();
				e = new AndExp(loc,e,e2);
				loc = this.loc;
			}
		}
		return e;
	}
	
    Expression parseXorExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAndExp();
		while (token.value == TOKxor)
		{
			nextToken();
			e2 = parseAndExp();
			e = new XorExp(loc, e, e2);
		}

		return e;
	}

    Expression parseOrExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseXorExp();
		while (token.value == TOKor)
		{
			nextToken();
			e2 = parseXorExp();
			e = new OrExp(loc, e, e2);
		}
		return e;
	}
	
    Expression parseAndAndExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseOrExp();
		while (token.value == TOKandand)
		{
			nextToken();
			e2 = parseOrExp();
			e = new AndAndExp(loc, e, e2);
		}
		return e;
	}
	
    Expression parseOrOrExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAndAndExp();
		while (token.value == TOKoror)
		{
			nextToken();
			e2 = parseAndAndExp();
			e = new OrOrExp(loc, e, e2);
		}

		return e;
	}
	
    Expression parseCondExp()
	{
		Expression e;
		Expression e1;
		Expression e2;
		Loc loc = this.loc;

		e = parseOrOrExp();
		if (token.value == TOKquestion)
		{
			nextToken();
			e1 = parseExpression();
			check(TOKcolon);
			e2 = parseCondExp();
			e = new CondExp(loc, e, e1, e2);
		}
		return e;
	}
	
    Expression parseAssignExp()
	{
		Expression e;
		Expression e2;
		Loc loc;

		e = parseCondExp();
		while (1)
		{
			loc = this.loc;
			switch (token.value)
			{
				case TOKassign:  nextToken(); e2 = parseAssignExp(); e = new AssignExp(loc,e,e2); continue;
				case TOKaddass:  nextToken(); e2 = parseAssignExp(); e = new AddAssignExp(loc,e,e2); continue;
				case TOKminass:  nextToken(); e2 = parseAssignExp(); e = new MinAssignExp(loc,e,e2); continue;
				case TOKmulass:  nextToken(); e2 = parseAssignExp(); e = new MulAssignExp(loc,e,e2); continue;
				case TOKdivass:  nextToken(); e2 = parseAssignExp(); e = new DivAssignExp(loc,e,e2); continue;
				case TOKmodass:  nextToken(); e2 = parseAssignExp(); e = new ModAssignExp(loc,e,e2); continue;
				case TOKpowass:  nextToken(); e2 = parseAssignExp(); e = new PowAssignExp(loc,e,e2); continue;
				case TOKandass:  nextToken(); e2 = parseAssignExp(); e = new AndAssignExp(loc,e,e2); continue;
				case TOKorass:   nextToken(); e2 = parseAssignExp(); e = new OrAssignExp(loc,e,e2); continue;
				case TOKxorass:  nextToken(); e2 = parseAssignExp(); e = new XorAssignExp(loc,e,e2); continue;
				case TOKshlass:  nextToken(); e2 = parseAssignExp(); e = new ShlAssignExp(loc,e,e2); continue;
				case TOKshrass:  nextToken(); e2 = parseAssignExp(); e = new ShrAssignExp(loc,e,e2); continue;
				case TOKushrass: nextToken(); e2 = parseAssignExp(); e = new UshrAssignExp(loc,e,e2); continue;
				case TOKcatass:  nextToken(); e2 = parseAssignExp(); e = new CatAssignExp(loc,e,e2); continue;
				
				default:
					break;
			}
			break;
		}

		return e;
	}
	
	/*************************
	 * Collect argument list.
	 * Assume current token is ',', '(' or '['.
	 */
    Expression[] parseArguments()
	{
		// function call
		Expression[] arguments;
		Expression arg;
		TOK endtok;
		
		if (token.value == TOKlbracket)
			endtok = TOKrbracket;
		else
			endtok = TOKrparen;

		{
			nextToken();
			if (token.value != endtok)
			{
				while (1)
				{
					arg = parseAssignExp();
					arguments ~= (arg);
					if (token.value == endtok)
						break;
					check(TOKcomma);
				}
			}
			check(endtok);
		}
		return arguments;
	}

    Expression parseNewExp(Expression thisexp)
	{
		Type t;
		Expression[] newargs;
		Expression[] arguments;
		Expression e;
		Loc loc = this.loc;

		nextToken();
		newargs = null;
		if (token.value == TOKlparen)
		{
			newargs = parseArguments();
		}

		// An anonymous nested class starts with "class"
		if (token.value == TOKclass)
		{
			nextToken();
			if (token.value == TOKlparen)
				arguments = parseArguments();

			BaseClass[] baseclasses = null;
			if (token.value != TOKlcurly)
				baseclasses = parseBaseClasses();

			Identifier id = null;
			ClassDeclaration cd = new ClassDeclaration(loc, id, baseclasses);

			if (token.value != TOKlcurly)
			{   
				error("{ members } expected for anonymous class");
				cd.members = null;
			}
			else
			{
				nextToken();
				auto decl = parseDeclDefs(0);
				if (token.value != TOKrcurly)
					error("class member expected");
				nextToken();
				cd.members = decl;
			}

			e = new NewAnonClassExp(loc, thisexp, newargs, cd, arguments);

			return e;
		}

		t = parseBasicType();
		t = parseBasicType2(t);
		if (t.ty == Taarray)
		{	
			TypeAArray taa = cast(TypeAArray)t;
			Type index = taa.index;

			Expression e2 = index.toExpression();
			if (e2)
			{   
				arguments ~= e2;
				t = new TypeDArray(taa.next);
			}
			else
			{
				error("need size of rightmost array, not type %s", index.toChars());
				return new NullExp(loc);
			}
		}
		else if (t.ty == Tsarray)
		{
			TypeSArray tsa = cast(TypeSArray)t;
			Expression ee = tsa.dim;

			arguments ~= ee;
			t = new TypeDArray(tsa.next);
		}
		else if (token.value == TOKlparen)
		{
			arguments = parseArguments();
		}

		e = new NewExp(loc, thisexp, newargs, t, arguments);
		return e;
	}
	
    void addComment(Dsymbol s, string blockComment)
	{
      
		s.addComment(Lexer.combineComments(blockComment, token.lineComment));
		token.lineComment = null;
	}
}
