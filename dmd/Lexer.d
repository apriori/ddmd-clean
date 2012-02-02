module dmd.Lexer;

import dmd.Global;
import dmd.Token; // Now contains: struct Token, Keyword, static initializers
import dmd.Module;
import dmd.Identifier;

import std.stdio; // : writeln;
import std.ascii; // : isAlphaNum, isDigit, ascii.isAlpha; 
import std.uni; // : uni.isAlpha, lineSep, paraSep;
import std.conv;
import std.encoding;
import std.utf; // toUTF8... see decodeUTF();
import std.array; // array.appender actually seems to do what dmd's OutBuffer does
    
version (unittest)
{
    import std.file;
    import std.variant;
    Lexer lex;
    alias lex luthor;
    Variant lois;
    alias lois lane; // Gotta have a little fun I guess
}

class Lexer
{
    Loc loc;			// for error messages

    char[] srcbuf;	// I think the array holds the endoffset too
    char* p;		// current character
    Token token;
    Module mod;
    int doDocComment;		// collect doc comment information
    int anyToken;		// !=0 means seen at least one token
    int commentToken;		// !=0 means comments are TOKcomment's

    // static, that means globally stored
    static Token* freelist;
    // I'm going to define stringtable in dmd.Identifier 
    //static Identifier[string] stringtable; 
    static Appender!(char[]) stringbuffer;
    

    this(Module mod, char[] srcbuf, uint begoffset, int doDocComment, int commentToken)
	{
		loc = Loc(mod, 1);

		this.srcbuf = srcbuf;
		//this.end  = srcbuf.ptr + srcbuf.length;
		p = srcbuf.ptr + begoffset;
		this.mod = mod;
		this.doDocComment = doDocComment;
		this.anyToken = 0;
		this.commentToken = commentToken;
      // for some reason this function also gets 
      // called in dmd.types.Type.Type.init() TODO figure this out

      /* If first line starts with '#!', ignore the line
       */

		if (p[0] == '#' && p[1] =='!')
		{
			p += 2;
			while (true)
			{
				char c = *p;
				switch (c)
				{
				case '\n':
					p++;
					break;

				case '\r':
					p++;
					if (*p == '\n')
					p++;
					break;

				case 0:
				case 0x1A:
					break;

				default:
					if (c & 0x80)
					{
						uint u = decodeUTF(); 
						if (u == paraSep || u == lineSep)
							break;
					}
					p++;
					continue;
				}
				break;
			}
			loc.linnum = 2;
		}
	}
      
    unittest
    {
        Module m;
        char[] testfil;
        try { testfil = readText!(char[])("./dmd/Lexer.d"); }
        catch { writeln("Problem reading file in unittest"); }
        
        lex = new Lexer( m, testfil, 0, 0, /+comments:yes+/ 1 );
        auto eatIt = appender!(Token[])();
        auto spitIt = appender!(char[])();
        with (lex)
        {
            nextToken(); 
            // We're only doing a thousand now
            for( int i =0; i<1000; i++)
            { 
                eatIt.put(token);
                nextToken(); 
                if ( token.value == TOKeof ) 
                    break;
            }
        }
            // We have an array, now let's put them out to a buffer
            foreach ( tokIt; eatIt.data )
            {
                spitIt.put( tokIt.toChars() ~ " ");
                static int perLine = 0;
                if ( perLine > 9 )
                {
                    spitIt.put("\n");
                    perLine = 0;
                }
                perLine++;
            }
            // Write to a file
            File outbuf = File("ddmdtrashfile.d","w");
            outbuf.write( spitIt.data );
            outbuf.close();
            // Now run it to see if the damn thing worked!
            // struct File is easier than I thought I ain't no C programmer!
    }

    // function bool isKeyword() is in Token
    // I'm not sure who uses it, but it seems useful

    pure nothrow @safe bool isIdChar(char c)
    { 
        return ( std.ascii.isAlphaNum(c) || c == '_' );
    }

    TOK nextToken()
    {
        if (token.next)
        {
            Token *t = token.next;

            token = *t; // No .dup for struct Token
            token.next = freelist; // set pointer
            freelist = t; // recycle original token
        }
        else
        {
            scan(&token);
        }

        //token.print();
        return token.value;
    }

    /***********************
     * Look ahead at next token's value.
     */
    TOK peekNext()
    {
      return peek(&token).value;
    }

    /***********************
     * Look 2 tokens ahead at value.
     */
    TOK peekNext2()
    {
      Token* t = peek(&token);
      return peek(t).value;
    }

    void scan( Token* t)
    {
        uint lastLine = loc.linnum;
        uint linnum;

        t.blockComment = null;
        t.lineComment = null;
        while (true)
        {
            t.pointer = p;
            //printf("p = %p, *p = '%c'\n",p,*p);
            switch (*p)
            {
                case 0:
                case 0x1A:
                    t.value = TOKeof;			// end of file
                    return;

                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    p++;
                    continue;			// skip white space

                case '\r':
                    p++;
                    if (*p != '\n')			// if CR stands by itself
                        loc.linnum++;
                    continue;			// skip white space

                case '\n':
                    p++;
                    loc.linnum++;
                    continue;			// skip white space

                case '0':  	case '1':   case '2':   case '3':   case '4':
                case '5':  	case '6':   case '7':   case '8':   case '9':
                    t.value = number(t);
                    return;

                case '\'':
                    t.value = charConstant(t,0);
                    return;

                case 'r':
                    if (p[1] != '"')
                        goto case_ident;
                    p++;
                case '`':
                    t.value = wysiwygStringConstant(t, *p);
                    return;

                case 'x':
                    if (p[1] != '"')
                        goto case_ident;
                    p++;
                    t.value = hexStringConstant(t);
                    return;

                case 'q':
                    if (p[1] == '"')
                    {
                        p++;
                        t.value = delimitedStringConstant(t);
                        return;
                    }
                    else if (p[1] == '{')
                    {
                        p++;
                        t.value = tokenStringConstant(t);
                        return;
                    }
                    else
                        goto case_ident;

                case '"':
                    t.value = escapeStringConstant(t,0);
                    return;     
                case '\\':			// escaped string literal
                {    
                    uint c;
                    char* pstart = p;

                    stringbuffer.clear();
                    do
                    {
                        p++;
                        switch (*p)
                        {
                            case 'u':
                            case 'U':
                            case '&':
                                c = escapeSequence();
                                stringbuffer.put( to!char(c) );
                                break;

                            default:
                                c = escapeSequence();
                                stringbuffer.put( to!char(c) );
                                break;
                        }
                    } while (*p == '\\');

                    stringbuffer.put('\0');
                    t.ustring = stringbuffer.data.idup;
                    
                    t.postfix = 0;
                    t.value = TOKstring;
                    
                    if (!global.params.useDeprecated)
                        error("Escape String literal %.*s is deprecated, use double quoted string literal \"%.*s\" instead", p - pstart, pstart, p - pstart, pstart);
                    return;
                }
                case 'l':
                case 'L':
                case 'a':  case 'b':   case 'c':   case 'd':   case 'e':
                case 'f':  case 'g':   case 'h':   case 'i':   case 'j':
                case 'k':  case 'm':   case 'n':   case 'o':
                case 'p': 	/*case 'q': case 'r':*/ case 's':   case 't':
                case 'u': 	case 'v':   case 'w': /*case 'x':*/ case 'y':
                case 'z':
                case 'A': 	case 'B':   case 'C':   case 'D':   case 'E':
                case 'F': 	case 'G':   case 'H':   case 'I':   case 'J':
                case 'K':  case 'M':   case 'N':   case 'O':
                case 'P': 	case 'Q':   case 'R':   case 'S':   case 'T':
                case 'U': 	case 'V':   case 'W':   case 'X':   case 'Y':
                case 'Z':  
                case '_': 

                case_ident:
                {
                    char c;

                    while (true)
                    {
                        c = *++p;
                        if (isIdChar(c))
                            continue;
                        else if (c & 0x80)
                        {
                            char *s = p;
                            uint u = decodeUTF();
                            if (std.uni.isAlpha(u))
                                continue;
                            error("char 0x%04x not allowed in identifier", u);
                            p = s;
                        }
                        break;
                    }

                    auto s = cast(string)(t.pointer[0.. p - t.pointer]);
                        
                    Identifier id = dmd.Identifier.stringtable.get( s, null );
                    if (id is null)
                    {
                        id = new Identifier( s, TOKidentifier );
                        dmd.Identifier.stringtable[s] = id;
                    }

                    t.ident = id;
                    t.value = id.value;
                    anyToken = 1;
                    if (*t.pointer == '_')	// if special identifier token
                    {
                        if (id == Id.DATE)
                        {
                            t.ustring = global.date.idup;
                            goto Lstr;
                        }
                        else if (id == Id.TIME)
                        {
                            t.ustring = global.time.idup;
                            goto Lstr;
                        }
                        else if (id == Id.VENDOR)
                        {
                            t.ustring = "Digital Mars D";
                            goto Lstr;
                        }
                        else if (id == Id.TIMESTAMP)
                        {
                            t.ustring = global.timestamp.idup;
                Lstr:
                            t.value = TOKstring;
                Llen:
                            t.postfix = 0;
                        }
                        else if (id == Id.VERSIONX)
                        {
                            uint major = 0;
                            uint minor = 0;

                            foreach (char cc; global.version_[1..$])
                            {
                                if (std.ascii.isDigit(cc))
                                    minor = minor * 10 + cc - '0';
                                else if (cc == '.')
                                {
                                    major = minor;
                                    minor = 0;
                                }
                                else
                                    break;
                            }
                            t.value = TOKint64v;
                            t.uns64value = major * 1000 + minor;
                        }

                        else if (id == Id.EOFX)
                        {
                            t.value = TOKeof;
                            // Advance scanner to end of file
                            while (!(*p == 0 || *p == 0x1A))
                                p++;
                        }
                    }
                    //printf("t.value = %d\n",t.value);
                    return;
                }

                case '/':
                p++;
                switch (*p)
                {
                    case '=':
                        p++;
                        t.value = TOKdivass;
                        return;

                    case '*':
                        p++;
                        linnum = loc.linnum;
                        while (true)
                        {
                            while (true)
                            {
                                char c = *p;
                                switch (c)
                                {
                                    case '/':
                                        break;

                                    case '\n':
                                        loc.linnum++;
                                        p++;
                                        continue;

                                    case '\r':
                                        p++;
                                        if (*p != '\n')
                                            loc.linnum++;
                                        continue;

                                    case 0:
                                    case 0x1A:
                                        error("unterminated /* */ comment");
                                        p = srcbuf.ptr + srcbuf.length;
                                        t.value = TOKeof;
                                        return;

                                    default:
                                        if (c & 0x80)
                                        {   uint u = decodeUTF();
                                            if (u == paraSep || u == lineSep)
                                                loc.linnum++;
                                        }
                                        p++;
                                        continue;
                                }
                                break;
                            }
                            p++;
                            if (p[-2] == '*' && p - 3 != t.pointer)
                                break;
                        }
                        if (commentToken)
                        {
                            t.value = TOKcomment;
                            return;
                        }
                        else if (doDocComment && t.pointer[2] == '*' && p - 4 != t.pointer)
                        {   // if /** but not /**/
                            getDocComment(t, lastLine == linnum);
                        }
                        continue;

                    case '/':		// do // style comments
                        linnum = loc.linnum;
                        while (true)
                        {   char c = *++p;
                            switch (c)
                            {
                                case '\n':
                                    break;

                                case '\r':
                                    if (p[1] == '\n')
                                        p++;
                                    break;

                                case 0:
                                case 0x1A:
                                    if (commentToken)
                                    {
                                        p = srcbuf.ptr + srcbuf.length;
                                        t.value = TOKcomment;
                                        return;
                                    }
                                    if (doDocComment && t.pointer[2] == '/' || t.pointer[2] == '!') // '///' or '//!'
                                        getDocComment(t, lastLine == linnum);
                                    p = srcbuf.ptr + srcbuf.length;
                                    t.value = TOKeof;
                                    return;

                                default:
                                    if (c & 0x80)
                                    {   uint u = decodeUTF();
                                        if (u == paraSep || u == lineSep)
                                            break;
                                    }
                                    continue;
                            }
                            break;
                        }

                        if (commentToken)
                        {
                            p++;
                            loc.linnum++;
                            t.value = TOKcomment;
                            return;
                        }
                        if (doDocComment && t.pointer[2] == '/' || t.pointer[2] == '!') // '///' or '//!'
                            getDocComment(t, lastLine == linnum);

                        p++;
                        loc.linnum++;
                        continue;

                    case '+':
                        {
                            int nest;

                            linnum = loc.linnum;
                            p++;
                            nest = 1;
                            while (true)
                            {   char c = *p;
                                switch (c)
                                {
                                    case '/':
                                        p++;
                                        if (*p == '+')
                                        {
                                            p++;
                                            nest++;
                                        }
                                        continue;

                                    case '+':
                                        p++;
                                        if (*p == '/')
                                        {
                                            p++;
                                            if (--nest == 0)
                                                break;
                                        }
                                        continue;

                                    case '\r':
                                        p++;
                                        if (*p != '\n')
                                            loc.linnum++;
                                        continue;

                                    case '\n':
                                        loc.linnum++;
                                        p++;
                                        continue;

                                    case 0:
                                    case 0x1A:
                                        error("unterminated /+ +/ comment");
                                        p = srcbuf.ptr + srcbuf.length;
                                        t.value = TOKeof;
                                        return;

                                    default:
                                        if (c & 0x80)
                                        {   uint u = decodeUTF();
                                            if (u == paraSep || u == lineSep)
                                                loc.linnum++;
                                        }
                                        p++;
                                        continue;
                                }
                                break;
                            }
                            if (commentToken)
                            {
                                t.value = TOKcomment;
                                return;
                            }
                            if (doDocComment && t.pointer[2] == '+' && p - 4 != t.pointer)
                            {   // if /++ but not /++/
                                getDocComment(t, lastLine == linnum);
                            }
                            continue;
                        }

                    default:
                        break;	///
                }
                t.value = TOKdiv;
                return;

                case '.':
                p++;
                if (std.ascii.isDigit(*p))
                {   /* Note that we don't allow ._1 and ._ as being
                     * valid floating point numbers.
                     */
                    p--;
                    t.value = inreal(t);
                }
                else if (p[0] == '.')
                {
                    if (p[1] == '.')
                    {   p += 2;
                        t.value = TOKdotdotdot;
                    }
                    else
                    {   p++;
                        t.value = TOKslice;
                    }
                }
                else
                    t.value = TOKdot;
                return;

                case '&':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKandass;
                }
                else if (*p == '&')
                {   p++;
                    t.value = TOKandand;
                }
                else
                    t.value = TOKand;
                return;

                case '|':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKorass;
                }
                else if (*p == '|')
                {   p++;
                    t.value = TOKoror;
                }
                else
                    t.value = TOKor;
                return;

                case '-':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKminass;
                }
                ///		#if 0
                ///				else if (*p == '>')
                ///				{   p++;
                ///					t.value = TOKarrow;
                ///				}
                ///		#endif
                else if (*p == '-')
                {   p++;
                    t.value = TOKminusminus;
                }
                else
                    t.value = TOKmin;
                return;

                case '+':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKaddass;
                }
                else if (*p == '+')
                {   p++;
                    t.value = TOKplusplus;
                }
                else
                    t.value = TOKadd;
                return;

                case '<':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKle;			// <=
                }
                else if (*p == '<')
                {   p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOKshlass;		// <<=
                    }
                    else
                        t.value = TOKshl;		// <<
                }
                else if (*p == '>')
                {   p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOKleg;		// <>=
                    }
                    else
                        t.value = TOKlg;		// <>
                }
                else
                    t.value = TOKlt;			// <
                return;

                case '>':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKge;			// >=
                }
                else if (*p == '>')
                {   p++;
                    if (*p == '=')
                    {   p++;
                        t.value = TOKshrass;		// >>=
                    }
                    else if (*p == '>')
                    {	p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOKushrass;	// >>>=
                        }
                        else
                            t.value = TOKushr;		// >>>
                    }
                    else
                        t.value = TOKshr;		// >>
                }
                else
                    t.value = TOKgt;			// >
                return;

                case '!':
                p++;
                if (*p == '=')
                {   p++;
                    if (*p == '=' && global.params.Dversion == 1)
                    {	p++;
                        t.value = TOKnotidentity;	// !==
                    }
                    else
                        t.value = TOKnotequal;		// !=
                }
                else if (*p == '<')
                {   p++;
                    if (*p == '>')
                    {	p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOKunord; // !<>=
                        }
                        else
                            t.value = TOKue;	// !<>
                    }
                    else if (*p == '=')
                    {	p++;
                        t.value = TOKug;	// !<=
                    }
                    else
                        t.value = TOKuge;	// !<
                }
                else if (*p == '>')
                {   p++;
                    if (*p == '=')
                    {	p++;
                        t.value = TOKul;	// !>=
                    }
                    else
                        t.value = TOKule;	// !>
                }
                else
                    t.value = TOKnot;		// !
                return;

                case '=':
                p++;
                if (*p == '=')
                {   p++;
                    if (*p == '=' && global.params.Dversion == 1)
                    {	p++;
                        t.value = TOKidentity;		// ===
                    }
                    else
                        t.value = TOKequal;		// ==
                }
                else
                    t.value = TOKassign;		// =
                return;

                case '~':
                p++;
                if (*p == '=')
                {   p++;
                    t.value = TOKcatass;		// ~=
                }
                else
                    t.value = TOKtilde;		// ~
                return;

                case '^':
                    p++;
                    if (*p == '^')
                    {   p++;
                        if (*p == '=')
                        {   p++;
                            t.value = TOKpowass;  // ^^=
                        }
                        else
                            t.value = TOKpow;     // ^^
                    }
                    else if (*p == '=')
                    {   p++;
                        t.value = TOKxorass;    // ^=
                    }
                    else
                        t.value = TOKxor;       // ^
                    return;

                case '(': p++; t.value = TOKlparen; return;
                case ')': p++; t.value = TOKrparen; return;
                case '[': p++; t.value = TOKlbracket; return;
                case ']': p++; t.value = TOKrbracket; return;
                case '{': p++; t.value = TOKlcurly; return;
                case '}': p++; t.value = TOKrcurly; return;
                case '?': p++; t.value = TOKquestion; return;
                case ',': p++; t.value = TOKcomma; return;
                case ';': p++; t.value = TOKsemicolon; return;
                case ':': p++; t.value = TOKcolon; return;
                case '$': p++; t.value = TOKdollar; return;
                case '@': p++; t.value = TOKat; return;

                case '*':
                    p++;
                    if (*p == '=')
                    {
                        p++;
                        t.value = TOKmulass;
                    } else
                        t.value = TOKmul;
                    return;

                case '%':
                    p++;
                    if (*p == '=') {
                        p++;
                        t.value = TOKmodass;
                    } else {
                        t.value = TOKmod;
                    }
                    return;
                
                case '#':
                    p++;
                    pragma_();
                    continue;

                default:
                    {	uint c = *p;

                        if (c & 0x80)
                        {   c = decodeUTF();

                            // Check for start of unicode identifier
                            if (std.uni.isAlpha(c))
                                goto case_ident;

                            if (c == paraSep || c == lineSep)
                            {
                                loc.linnum++;
                                p++;
                                continue;
                            }
                        }
                        if (c < 0x80 && std.ascii.isPrintable(c))
                            error("unsupported char '%c'", c);
                        else
                            error("unsupported char 0x%02x", c);
                        p++;
                        continue;
                    }
            }
        }
    }

    Token* peek( Token* ct)
    {
        if (ct.next)
            return ct.next;

        Token* t = newToken();
        scan(t);
        t.next = null;
        ct.next = t;
        return t;
    }

    // operator new is overloaded in dmd. this is my replacement
    Token* newToken()
    {
        Token* t;
        if ( freelist ) 
        {
            t = freelist;
            freelist = t.next;
        }
        else t = new Token;
        return t;
    }

    Token* peekPastParen( Token* tk )
    {
        //printf("peekPastParen()\n");
        int parens = 1;
        int curlynest = 0;
        while (true)
        {
            tk = peek(tk);
            //tk.print();
            switch (tk.value)
            {
                case TOKlparen:
                    parens++;
                    continue;

                case TOKrparen:
                    --parens;
                    if (parens)
                        continue;
                    tk = peek(tk);
                    break;

                case TOKlcurly:
                    curlynest++;
                    continue;

                case TOKrcurly:
                    if (--curlynest >= 0)
                        continue;
                    break;

                case TOKsemicolon:
                    if (curlynest)
                        continue;
                    break;

                case TOKeof:
                    break;

                default:
                    continue;
            }
            return tk;
        }
    }

    /*******************************************
     * Parse escape sequence.
     */
    uint escapeSequence()
    {
        uint c = *p;
        ///??? char c = *p;

        int n;
        int ndigits;

        switch (c)
        {
            case '\'':
            case '"':
            case '?':
            case '\\':
        Lconsume:
                p++;
                break;

            case 'a':	c = 7;	goto Lconsume;
            case 'b':	c = 8;	goto Lconsume;
            case 'f':	c = 12;		goto Lconsume;
            case 'n':   c = 10;		goto Lconsume;
            case 'r':	c = 13;		goto Lconsume;
            case 't':	c = 9;		goto Lconsume;
            case 'v':   c = 11;     goto Lconsume;
            case 'u':
                ndigits = 4;
                goto Lhex;
            case 'U':
                ndigits = 8; goto Lhex;
            case 'x':
                ndigits = 2;
        Lhex:
                p++;
                c = *p;
                if (std.ascii.isHexDigit(c))
                {
                    uint v;

                    n = 0;
                    v = 0;
                    while (true)
                    {
                        if (std.ascii.isDigit(c))
                            c -= '0';
                        else if (std.ascii.isLower(c))
                            c -= 'a' - 10;
                        else
                            c -= 'A' - 10;
                        v = v * 16 + c;
                        c = *++p;
                        if (++n == ndigits)
                            break;
                        if (!std.ascii.isHexDigit( c ))
                        {   error("escape hex sequence has %d hex digits instead of %d", n, ndigits);
                            break;
                        }
                    }
                    if (ndigits != 2 && !std.utf.isValidDchar(v))
                    {	error("invalid UTF character \\U%08x", v);
                        v = '?';	// recover with valid UTF character
                    }
                    c = v;
                }
                else
                    error("undefined escape hex sequence \\%c\n",c);
                break;

            case '&':			// named character entity
            {
                // My try at this code
                // I don't have a test for it yet. TODO write test
                char* id = p;
                while (true)
                {
                    p++; 
                    if ( *p == ';' )
                    {
                        switch (id[0..p - id]) 
                        {  
                            case "&amp":
                                c = '&'; break;
                            case "&lt": 
                                c = '<'; break;
                            case "&gt":
                                c = '>'; break;
                            case "&apos":
                                c = '\''; break;
                            case "&quot":
                                c = '"'; break;
                            default:
                                error( "unnamed character entity %s;", id );
                                c = ' '; break;
                        }
                        p++;
                        break;
                    } 
                    else
                    {
                        if (std.ascii.isAlpha(*p) ||
                                (p != id + 2 && std.ascii.isDigit(*p)))
                            continue;
                        error("unterminated named entity");
                    }
                    break;
                }
                break;
                /+ // The original
                for (char* idstart = ++p; true; p++)
                {
                    switch (*p)
                    {
                        case ';':
                            c = HtmlNamedEntity(idstart, p - idstart);
                            if (c == ~0)
                            {
                                error("unnamed character entity &%s;", idstart[0..(p - idstart)]);
                                c = ' ';
                            }
                            p++;
                            break;

                        default:
                            if (std.ascii.isAlpha(*p) ||
                                    (p != idstart + 1 && std.ascii.isDigit(*p)))
                                continue;
                            error("unterminated named entity");
                            break;
                    }
                    break;
                }
                +/
            }
                break;

            case 0:
            case 0x1A:			// end of file
                c = '\\';
                break;

            default:
                if (std.ascii.isOctalDigit( c ))
                {
                    uint v;

                    n = 0;
                    v = 0;
                    do
                    {
                        v = v * 8 + (c - '0');
                        c = *++p;
                    } while (++n < 3 && std.ascii.isOctalDigit( c ));
                    c = v;
                    if (c > 0xFF)
                        error("0%03o is larger than a byte", c);
                }
                else
                    error("undefined escape sequence \\%c\n",c);
                break;
        }
        return c;
    }

    TOK wysiwygStringConstant( Token* t, int tc)
    {
        char c;
        Loc start = loc;

        p++;
        stringbuffer.clear();
        while (true)
        {
            c = *p++;
            switch (c)
            {
                case '\n':
                    loc.linnum++;
                    break;

                case '\r':
                    if (*p == '\n')
                        continue;	// ignore
                    c = '\n';	// treat EndOfLine as \n character
                    loc.linnum++;
                    break;

                case 0:
                case 0x1A:
                    error("unterminated string constant starting at %s", start.toChars());
                    t.ustring = "";
                    t.postfix = 0;
                    return TOKstring;

                case '"':
                case '`':
                    if (c == tc)
                    {
                        stringbuffer.put('\0');
                        t.ustring = stringbuffer.data.idup;
                        stringPostfix(t);
                        return TOKstring;
                    }
                    break;

                default:
                    if (c & 0x80)
                    {   p--;
                        uint u = decodeUTF();
                        p++;
                        if (u == paraSep || u == lineSep)
                            loc.linnum++;
                        stringbuffer.put( to!char(u) );
                        continue;
                    }
                    break;
            }
            stringbuffer.put( c );
        }

        assert(false);
    }

    /**************************************
     * Lex hex strings:
     *	x"0A ae 34FE BD"
     */
    TOK hexStringConstant(Token* t)
    {
        uint c;
        Loc start = loc;
        uint n = 0;
        uint v;

        p++;
        stringbuffer.clear();
        while (true)
        {
            c = *p++;
            switch (c)
            {
                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    continue;			// skip white space

                case '\r':
                    if (*p == '\n')
                        continue;			// ignore
                    // Treat isolated '\r' as if it were a '\n'
                case '\n':
                    loc.linnum++;
                    continue;

                case 0:
                case 0x1A:
                    error("unterminated string constant starting at %s", start.toChars());
                    t.ustring = "";
                    t.postfix = 0;
                    return TOKstring;

                case '"':
                    if (n & 1)
                    {
                        error("odd number (%d) of hex characters in hex string", n);
                        stringbuffer.put( to!char(v) );
                    }
                    
                    stringbuffer.put('\0');
                    t.ustring = stringbuffer.data.idup;
                    stringPostfix(t);
                    return TOKstring;

                default:
                    if (c >= '0' && c <= '9')
                        c -= '0';
                    else if (c >= 'a' && c <= 'f')
                        c -= 'a' - 10;
                    else if (c >= 'A' && c <= 'F')
                        c -= 'A' - 10;
                    else if (c & 0x80)
                    {   p--;
                        uint u = decodeUTF();
                        p++;
                        if (u == paraSep || u == lineSep)
                            loc.linnum++;
                        else
                            error("non-hex character \\u%04x", u);
                    }
                    else
                        error("non-hex character '%c'", c);
                    if (n & 1)
                    {   v = (v << 4) | c;
                        stringbuffer.put( to!char(v) );
                    }
                    else
                        v = c;
                    n++;
                    break;
            }
        }
    }

    /**************************************
     * Lex delimited strings:
     *	q"(foo(xxx))"   // "foo(xxx)"
     *	q"[foo(]"       // "foo("
     *	q"/foo]/"       // "foo]"
     *	q"HERE
     *	foo
     *	HERE"		// "foo\n"
     * Input:
     *	p is on the "
     */
    TOK delimitedStringConstant(Token* t)
    {
        uint c;
        Loc start = loc;
        uint delimleft = 0;
        uint delimright = 0;
        uint nest = 1;
        uint nestcount;
        Identifier hereid = null;
        uint blankrol = 0;
        uint startline = 0;

        p++;
        stringbuffer.clear();
        while (true)
        {
            c = *p++;
            //printf("c = '%c'\n", c);
            switch (c)
            {
                case '\n':
Lnextline:
                    loc.linnum++;
                    startline = 1;
                    if (blankrol)
                    {   blankrol = 0;
                        continue;
                    }
                    if (hereid)
                    {
                        stringbuffer.put( to!char(c) );
                        continue;
                    }
                    break;

                case '\r':
                    if (*p == '\n')
                        continue;	// ignore
                    c = '\n';	// treat EndOfLine as \n character
                    goto Lnextline;

                case 0:
                case 0x1A:
                    goto Lerror;

                default:
                    if (c & 0x80)
                    {   p--;
                        c = decodeUTF();
                        p++;
                        if (c == paraSep || c == lineSep)
                            goto Lnextline;
                    }
                    break;
            }
            if (delimleft == 0)
            {
                delimleft = c;
                nest = 1;
                nestcount = 1;
                if (c == '(')
                    delimright = ')';
                else if (c == '{')
                    delimright = '}';
                else if (c == '[')
                    delimright = ']';
                else if (c == '<')
                    delimright = '>';
                else if (std.ascii.isAlpha(c) || c == '_' || (c >= 0x80 && std.uni.isAlpha(c)))
                {
                    // Start of identifier; must be a heredoc
                    Token* t2;
                    p--;
                    scan(t2);		// read in heredoc identifier
                    if (t2.value != TOKidentifier)
                    {
                        error("identifier expected for heredoc, not %s", t2.toChars());
                        delimright = c;
                    }
                    else
                    {
                        hereid = t2.ident;
                        //printf("hereid = '%s'\n", hereid.toChars());
                        blankrol = 1;
                    }
                    nest = 0;
                }
                else
                {
                    delimright = c;
                    nest = 0;
                    if (isSpace(c))
                        error("delimiter cannot be whitespace");
                }
            }
            else
            {
                if (blankrol)
                {
                    error("heredoc rest of line should be blank");
                    blankrol = 0;
                    continue;
                }
                if (nest == 1)
                {
                    if (c == delimleft)
                        nestcount++;
                    else if (c == delimright)
                    {   nestcount--;
                        if (nestcount == 0)
                            goto Ldone;
                    }
                }
                else if (c == delimright)
                    goto Ldone;
                if (startline && std.ascii.isAlpha(c) && hereid)
                {
                    Token* t2;
                    char* psave = p;
                    p--;
                    scan(t2);		// read in possible heredoc identifier
                    //printf("endid = '%s'\n", t2.ident.toChars());
                    if (t2.value == TOKidentifier && (t2.ident == hereid))
                    {
                        /* should check that rest of line is blank
                         */
                        goto Ldone;
                    }
                    p = psave;
                }
                stringbuffer.put( to!char(c) );
                startline = 0;
            }
        }

Ldone:
        if (*p == '"')
            p++;
        else
            error("delimited string must end in %c\"", delimright);
        stringbuffer.put( '\0' );
        t.ustring = stringbuffer.data.idup;
        stringPostfix(t);
        return TOKstring;

Lerror:
        error("unterminated string constant starting at %s", start.toChars());
        t.ustring = "";
        t.postfix = 0;
        return TOKstring;
    }

    /**************************************
     * Lex delimited strings: VIM confuses lbrace, so {
     *	q{ foo(xxx) } // " foo(xxx) "
     *	q{foo(}       // "foo("
     *	q{{foo}"}"}   // "{foo}"}""
     * Input:
     *	p is on the q
     */
    TOK tokenStringConstant(Token* t)
    {
        uint nest = 1;
        Loc start = loc;
        char* pstart = ++p;

        while (true)
        {
            Token* tok;

            scan(tok);
            switch (tok.value)
            {
                case TOKlcurly:
                    nest++;
                    continue;

                case TOKrcurly:
                    if (--nest == 0)
                        goto Ldone;
                    continue;

                case TOKeof:
                    goto Lerror;

                default:
                    continue;
            }
        }

Ldone:
        //TODO test off by one here
        t.ustring = pstart[0..p - pstart].idup;
        stringPostfix(t);
        return TOKstring;

Lerror:
        error("unterminated token string constant starting at %s", start.toChars());
        t.ustring = "";
        t.postfix = 0;
        return TOKstring;
    }

    TOK escapeStringConstant(Token* t, int wide)
    {
        uint c;
        Loc start = loc;

        p++;
        stringbuffer.clear();
        while (true)
        {
            c = *p++;
            switch (c)
            {
                case '\\':
                    switch (*p)
                    {
                        case 'u':
                        case 'U':
                        case '&':
                            c = escapeSequence();
                            stringbuffer.put( to!char(c) );
                            continue;

                        default:
                            c = escapeSequence();
                            break;
                    }
                    break;
                case '\n':
                loc.linnum++;
                break;

                case '\r':
                if (*p == '\n')
                    continue;	// ignore
                c = '\n';	// treat EndOfLine as \n character
                loc.linnum++;
                break;

                case '"':
                stringbuffer.put( '\0' );
                t.ustring = stringbuffer.data.idup;
                stringPostfix(t);
                return TOKstring;

                case 0:
                case 0x1A:
                p--;
                error("unterminated string constant starting at %s", start.toChars());
                t.ustring = "";
                t.postfix = 0;
                return TOKstring;

                default:
                if (c & 0x80)
                {
                    p--;
                    //c = std.utf.decode( p[0..dchar.sizeof] ); // TODO what's this sposed t obe?
                    if (to!dchar(c) == lineSep || to!dchar(c) == paraSep)
                    {	c = '\n';
                        loc.linnum++;
                    }
                    p++;
                    stringbuffer.put( to!char(c) );
                    continue;
                }
                break;
            }
            stringbuffer.put( to!char(c) );
        }

        assert(false);
    }

    TOK charConstant(Token* t, int wide)
    {
        uint c;
        TOK tk = TOKcharv;

        //printf("Lexer.charConstant\n");
        p++;
        c = *p++;
        switch (c)
        {
            case '\\':
                switch (*p)
                {
                    case 'u':
                        t.uns64value = escapeSequence();
                        tk = TOKwcharv;
                        break;

                    case 'U':
                    case '&':
                        t.uns64value = escapeSequence();
                        tk = TOKdcharv;
                        break;

                    default:
                        t.uns64value = escapeSequence();
                        break;
                }
                break;
            case '\n':
L1:
            loc.linnum++;
            case '\r':
            case 0:
            case 0x1A:
            case '\'':
            error("unterminated character constant");
            return tk;

            default:
            if (c & 0x80)
            {
                p--;
                c = decodeUTF();
                p++;
                if (c == lineSep || c == paraSep)
                    goto L1;
                if (c < 0xD800 || (c >= 0xE000 && c < 0xFFFE))
                    tk = TOKwcharv;
                else
                    tk = TOKdcharv;
            }
            t.uns64value = c;
            break;
        }

        if (*p != '\'')
        {
            error("unterminated character constant");
            return tk;
        }
        p++;
        return tk;
    }

    /+++++++++++++++++++++++++++++++++++++++
     + Get postfix of string literal.
     +/
    void stringPostfix( Token* t)
    {
        switch (*p)
        {
            case 'c':
            case 'w':
            case 'd':
                t.postfix = *p;
                p++;
                break;

            default:
                t.postfix = 0;
                break;
        }
    }

    uint wchar_(uint u)
    {
        assert(false);
    }

    /**************************************
     * Read in a number.
     * If it's an integer, store it in tok.TKutok.Vlong.
     *	integers can be decimal, octal or hex
     *	Handle the suffixes U, UL, LU, L, etc.
     * If it's double, store it in tok.TKutok.Vdouble.
     * Returns:
     *	TKnum
     *	TKdouble,...
     */

    TOK number( Token* t)
    {
        // We use a state machine to collect numbers
        alias int STATE;
        enum { STATE_initial, STATE_0, STATE_decimal, STATE_octal, STATE_octale,
            STATE_hex, STATE_binary, STATE_hex0, STATE_binary0,
            STATE_hexh, STATE_error }
        STATE state;

        alias int FLAGS;
        enum 
        {
            FLAGS_undefined = 0,
            FLAGS_decimal  = 1,		// decimal
            FLAGS_unsigned = 2,		// u or U suffix
            FLAGS_long     = 4,		// l or L suffix
        }

        FLAGS flags = FLAGS_decimal;

        int i;
        int base;
        uint c;
        char *start;
        TOK result;

        //printf("Lexer.number()\n");
        state = STATE_initial;
        base = 0;
        stringbuffer.clear();
        start = p;
        while (true)
        {
            c = *p;
            switch (state)
            {
                case STATE_initial:		// opening state
                    if (c == '0')
                        state = STATE_0;
                    else
                        state = STATE_decimal;
                    break;

                case STATE_0:
                    flags = (flags & ~FLAGS_decimal);
                    switch (c)
                    {
                        version (ZEROH) {}
                        case 'X':
                        case 'x':
                        state = STATE_hex0;
                        break;

                        case '.':
                        if (p[1] == '.')	// .. is a separate token
                            goto done;
                        case 'i':
                        case 'f':
                        case 'F':
                        goto real_;
                        version (ZEROH) {}
                        case 'B':
                        case 'b':
                        state = STATE_binary0;
                        break;

                        case '0': case '1': case '2': case '3':
                        case '4': case '5': case '6': case '7':
                        state = STATE_octal;
                        break;

                        version (ZEROH) {}
                        case '_':
                        state = STATE_octal;
                        p++;
                        continue;

                        case 'L':
                        if (p[1] == 'i')
                            goto real_;
                        goto done;

                        default:
                        goto done;
                    }
                    break;

                case STATE_decimal:		// reading decimal number
                    if (!std.ascii.isDigit(c))
                    {
                        version (ZEROH) {}
                        if (c == '_')		// ignore embedded _
                        {	p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                            goto real_;
                        else if (c == 'i' || c == 'f' || c == 'F' ||
                                c == 'e' || c == 'E')
                        {
real_:	// It's a real number. Back up and rescan as a real
                            p = start;
                            return inreal(t);
                        }
                        else if (c == 'L' && p[1] == 'i')
                            goto real_;
                        goto done;
                    }
                    break;

                case STATE_hex0:		// reading hex number
                case STATE_hex:
                    if (! std.ascii.isHexDigit(cast(char)c))
                    {
                        if (c == '_')		// ignore embedded _
                        {	p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                            goto real_;
                        if (c == 'P' || c == 'p' || c == 'i')
                            goto real_;
                        if (state == STATE_hex0)
                            error("Hex digit expected, not '%c'", c);
                        goto done;
                    }
                    state = STATE_hex;
                    break;

                    version (ZEROH) {} // Deprecated I think...

                case STATE_octal:		// reading octal number
                case STATE_octale:		// reading octal number with non-octal digits
                    if (!std.ascii.isOctalDigit(cast(char)c))
                    {
                        version (ZEROH) {}
                        if (c == '_')		// ignore embedded _
                        {	p++;
                            continue;
                        }
                        if (c == '.' && p[1] != '.')
                            goto real_;
                        if (c == 'i')
                            goto real_;
                        if (std.ascii.isDigit(c))
                        {
                            state = STATE_octale;
                        }
                        else
                            goto done;
                    }
                    break;

                case STATE_binary0:		// starting binary number
                case STATE_binary:		// reading binary number
                    if (c != '0' && c != '1')
                    {
                        version (ZEROH) {}
                        if (c == '_')		// ignore embedded _
                        {	p++;
                            continue;
                        }
                        if (state == STATE_binary0)
                        {	error("binary digit expected");
                            state = STATE_error;
                            break;
                        }
                        else
                            goto done;
                    }
                    state = STATE_binary;
                    break;

                case STATE_error:		// for error recovery
                    if (!std.ascii.isDigit(c))	// scan until non-digit
                        goto done;
                    break;

                default:
                    assert(0);
            }
            stringbuffer.put( to!char(c) );
            p++;
        }
done:
        stringbuffer.put( '\0' );		// terminate string
        if (state == STATE_octale)
            error("Octal digit expected");

        ulong n;			// unsigned >=64 bit integer type

        if ( stringbuffer.data.length == 2
             && (state == STATE_decimal || state == STATE_0)
            )
            n = stringbuffer.data[0] - '0'; // this calculates a single digit number
        else
        {
            try { n = to!ulong( stringbuffer.data ); }
            catch ( ConvException ) { error("integer overflow"); }
        }

        // Parse trailing 'u', 'U', 'l' or 'L' in any combination
        while (true)
        {   FLAGS f;

            switch (*p)
            {   case 'U':
                case 'u':
                    f = FLAGS_unsigned;
                    goto L1;

                case 'l':
                    if (1 || !global.params.useDeprecated)
                        error("'l' suffix is deprecated, use 'L' instead");
                case 'L':
                    f = FLAGS_long;
L1:
                    p++;
                    if (flags & f)
                        error("unrecognized token");
                    flags = (flags | f);
                    continue;
                default:
                    break;
            }
            break;
        }

        switch (flags)
        {
            case FLAGS_undefined:
                /* Octal or Hexadecimal constant.
                 * First that fits: int, uint, long, ulong
                 */
                if (n & 0x8000000000000000)
                    result = TOKuns64v;
                else if (n & 0xFFFFFFFF00000000)
                    result = TOKint64v;
                else if (n & 0x80000000)
                    result = TOKuns32v;
                else
                    result = TOKint32v;
                break;

            case FLAGS_decimal:
                /* First that fits: int, long, long long
                 */
                if (n & 0x8000000000000000)
                {	    error("signed integer overflow");
                    result = TOKuns64v;
                }
                else if (n & 0xFFFFFFFF80000000)
                    result = TOKint64v;
                else
                    result = TOKint32v;
                break;

            case FLAGS_unsigned:
            case FLAGS_decimal | FLAGS_unsigned:
                /* First that fits: uint, ulong
                 */
                if (n & 0xFFFFFFFF00000000)
                    result = TOKuns64v;
                else
                    result = TOKuns32v;
                break;

            case FLAGS_decimal | FLAGS_long:
                if (n & 0x8000000000000000)
                {	    error("signed integer overflow");
                    result = TOKuns64v;
                }
                else
                    result = TOKint64v;
                break;

            case FLAGS_long:
                if (n & 0x8000000000000000)
                    result = TOKuns64v;
                else
                    result = TOKint64v;
                break;

            case FLAGS_unsigned | FLAGS_long:
            case FLAGS_decimal | FLAGS_unsigned | FLAGS_long:
                result = TOKuns64v;
                break;

            default:
                debug {
                    printf("%x\n",flags);
                }
                assert(0);
        }
        t.uns64value = n;
        return result;
    }

    /**************************************
     * Read in characters, converting them to real.
     * Bugs:
     *	Exponent overflow not detected.
     *	Too much requested precision is not detected.
     */
    TOK inreal( Token* t)
    in { assert(*p == '.' || std.ascii.isDigit(*p)); }
    out (result)
    {
        switch (result)
        {
            case TOKfloat32v:
            case TOKfloat64v:
            case TOKfloat80v:
            case TOKimaginary32v:
            case TOKimaginary64v:
            case TOKimaginary80v:
                break;

            default:
                assert(0);
        }
    }
    body
    {
        int dblstate;
        uint c;
        char hex;			// is this a hexadecimal-floating-constant?
        TOK result;

        //printf("Lexer.inreal()\n");
        stringbuffer.clear();
        dblstate = 0;
        hex = 0;
Lnext:
        while (true)
        {
            // Get next char from input
            c = *p++;
            //printf("dblstate = %d, c = '%c'\n", dblstate, c);
            while (true)
            {
                switch (dblstate)
                {
                    case 0:			// opening state
                        if (c == '0')
                            dblstate = 9;
                        else if (c == '.')
                            dblstate = 3;
                        else
                            dblstate = 1;
                        break;

                    case 9:
                        dblstate = 1;
                        if (c == 'X' || c == 'x')
                        {
                            hex++;
                            break;
                        }
                    case 1:			// digits to left of .
                    case 3:			// digits to right of .
                    case 7:			// continuing exponent digits
                        if (!std.ascii.isDigit(c) && !(hex && std.ascii.isHexDigit(c)))
                        {
                            if (c == '_')
                                goto Lnext;	// ignore embedded '_'
                            dblstate++;
                            continue;
                        }
                        break;

                    case 2:			// no more digits to left of .
                        if (c == '.')
                        {
                            dblstate++;
                            break;
                        }
                    case 4:			// no more digits to right of .
                        if ((c == 'E' || c == 'e') ||
                                hex && (c == 'P' || c == 'p'))
                        {
                            dblstate = 5;
                            hex = 0;	// exponent is always decimal
                            break;
                        }
                        if (hex)
                            error("binary-exponent-part required");
                        goto done;

                    case 5:			// looking immediately to right of E
                        dblstate++;
                        if (c == '-' || c == '+')
                            break;
                    case 6:			// 1st exponent digit expected
                        if (!std.ascii.isDigit(c))
                            error("exponent expected");
                        dblstate++;
                        break;

                    case 8:			// past end of exponent digits
                        goto done;

                    default:
                        assert(0, "inreal.dblstate has unexpected value");
                }
                break;
            }
            stringbuffer.put( to!char(c) );
        }
done:
        p--;

        // TODO unittest
        try 
        {
            t.float80value = to!double( stringbuffer.data );
        }
        catch ( ConvException ) 
        { 
            writefln("zd Lexer failed to convert: %s to a useable flaot80value", stringbuffer.data);
        }

        //errno = 0; // I use try blocks instead of errno
        switch (*p)
        {
            case 'F':
            case 'f':
                // check for error
                try { to!float( stringbuffer.data ); }
                catch ( ConvException ) { error("number is not representable"); }
                result = TOKfloat32v;
                p++;
                break;

            default:
                // check for error
                try { to!double(stringbuffer.data); }
                catch ( ConvException ) { error("number is not representable"); }
                result = TOKfloat64v;
                break;

            case 'l':
                if (!global.params.useDeprecated)
                    error("'l' suffix is deprecated, use 'L' instead");
            case 'L':
                result = TOKfloat80v;
                p++;
                break;
        }
        if (*p == 'i' || *p == 'I')
        {
            if (!global.params.useDeprecated && *p == 'I')
                error("'I' suffix is deprecated, use 'i' instead");
            p++;
            switch (result)
            {
                case TOKfloat32v:
                    result = TOKimaginary32v;
                    break;
                case TOKfloat64v:
                    result = TOKimaginary64v;
                    break;
                case TOKfloat80v:
                    result = TOKimaginary80v;
                    break;
                default:
            }
        }

        //if (errno == /+what's ERANGE ? +/)

          //TODO ERANGE what's the replacement for ERANGE??
          //error("number is not representable");
        return result;
    }

    void error(T...)(string format, T t)
    {
        error(this.loc, format, t);
    }
    void error(T...)(Loc loc, string format, T t)
    {
        if (mod && !global.gag)
        {
            string p = loc.toChars();
            if ( p )
                writef("%s: ", p);

            writefln(format, t);

            if (global.errors >= 20)	// moderate blizzard of cascading messages
                fatal();          // zd and it's a good thing too!
        }

        global.errors++;
    }

    /*********************************************
     * Do pragma.
     * Currently, the only pragma supported is:
     *	#line linnum [filespec]
     */
    void pragma_()
    {
        Token* tok;
        int linnum;
        string filespec = null;
        Loc loc = this.loc;

        scan(tok);
        if (tok.value != TOKidentifier || tok.ident != Id.line)
            goto Lerr;

        scan(tok);
        if (tok.value == TOKint32v || tok.value == TOKint64v)
            linnum = to!int(tok.uns64value - 1); ///
        else
            goto Lerr;

        while (true)
        {
            switch (*p)
            {
                case 0:
                case 0x1A:
                case '\n':
Lnewline:
                    this.loc.linnum = linnum;
                    if (filespec != null)
                        this.loc.filename = filespec;
                    return;

                case '\r':
                    p++;
                    if (*p != '\n')
                    {   p--;
                        goto Lnewline;
                    }
                    continue;

                case ' ':
                case '\t':
                case '\v':
                case '\f':
                    p++;
                    continue;			// skip white space

                case '_':
                    if (mod && p[0..8] == "__FILE__")
                    {
                        version (unittest) { lois = TOKfile; }
                        p += 8;
                        filespec = (loc.filename ? loc.filename : mod.ident.toChars());
                    }
                    continue;

                case '"':
                    if (filespec)
                        goto Lerr;
                    stringbuffer.clear();
                    p++;
                    while (true)
                    {
                        uint c;

                        c = *p;
                        switch (c)
                        {
                            case '\n':
                            case '\r':
                            case 0:
                            case 0x1A:
                                goto Lerr;

                            case '"':
                                stringbuffer.put( '\0' );
                                filespec = stringbuffer.data.idup;	
                                p++;
                                break;

                            default:
                                if (c & 0x80)
                                {
                                    uint u = decodeUTF();
                                    if (u == paraSep || u == lineSep)
                                        goto Lerr;
                                }
                                stringbuffer.put( to!char(c) );
                                p++;
                                continue;
                        }
                        break;
                    }
                    continue;

                default:
                    if (*p & 0x80)
                    {
                        uint u = decodeUTF(); 
                        if (u == paraSep || u == lineSep)
                            goto Lnewline;
                    }
                    goto Lerr;
            }
        }
Lerr:
        error(loc, "#line integer [\"filespec\"]\\n expected");
    }
     
    
    unittest //TODO unittest these unittests ( :-)
    { 
        auto txt = "   __FILE_", txt2 = " __FILE__"; 
        lois = 0;

        //lexToken( txt );
        //assert ( utest != TOKfile );
        //lexToken( txt2 );
        //assert ( utest == TOKfile );
    }

    /********************************************
     * Decode UTF character.
     * Issue error messages for invalid sequences.
     * Return decoded character, advance p to last character in UTF sequence.
     */
     // BUG: fail, I couldn't figure out which routines in the library to use
     // std.encoding? std.utf? std.conv.to? Too many routines.
     // The following may or may not work... feel free to fix it!
    uint decodeUTF()
    {
        char[] c;
        c = p[0..6];
        uint len = 0;

        assert(c[0] & 0x80);

        // Check length of remaining string up to 6 UTF-8 characters
        while ( len < 6 && c[ len ] != 0 ) 
            len++;

        // TODO fail I simply don't understand UTF!
        return std.encoding.decode( c );
    }

    /***************************************************
     * Parse doc comment embedded between t.pointer and p.
     * Remove trailing blanks and tabs from lines.
     * Replace all newlines with \n.
     * Remove leading comment character from each line.
     * Decide if it's a lineComment or a blockComment.
     * Append to previous one for this token.
     */
    
	void getDocComment(Token* t, uint lineComment)
	{
   /+ I think phobos could make this whole thing easier +/
   /+ So I'm waiting until I get other stuff working +/
   /+ 
		/* ct tells us which kind of comment it is: '!', '/', '*', or '+'
		 */
		char ct = t.pointer[2];

		/* Start of comment text skips over / * *, / + +, or / / /
		 */
		char* q = t.pointer + 3;	  // start of comment text

		char* qend = p;
		if (ct == '*' || ct == '+')
			qend -= 2;

		/* Scan over initial row of ****'s or ++++'s or ////'s
		 */
		for (; q < qend; q++)
		{
			if (*q != ct)
				break;
		}

		/* Remove trailing row of ****'s or ++++'s
		 */
		if (ct != '/' && ct != '!')
		{
			for (; q < qend; qend--)
			{
				if (qend[-1] != ct)
					break;
			}
		}

		/* Comment is now [q .. qend].
		 * Canonicalize it into buf[].
		 */
		Appender!(char[]) buf;
		int linestart = 0;

		for (; q < qend; q++)
		{
			char c = *q;

			switch (c)
			{
				case '*':
				case '+':
					if (linestart && c == ct)
					{   linestart = 0;
						/* Trim preceding whitespace up to preceding \n
						 */
						while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
							buf.offset--;
						continue;
					}
					break;

				case ' ':
				case '\t':
					break;

				case '\r':
					if (q[1] == '\n')
						continue;		   // skip the \r
					goto Lnewline;

				default:
					if (c == 226)
					{
						// If LS or PS
						if (q[1] == 128 &&
							(q[2] == 168 || q[2] == 169))
						{
							q += 2;
							goto Lnewline;
						}
					}
					linestart = 0;
					break;

				Lnewline:
					c = '\n';			   // replace all newlines with \n
				case '\n':
					linestart = 1;

					/* Trim trailing whitespace
					 */
					while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
						buf.offset--;

					break;
			}
			buf.put(c);
		}

		// Always end with a newline
		if (!buf.offset || buf.data[buf.offset - 1] != '\n')
			buf.writeByte('\n');

		buf.writeByte(0);

		// It's a line comment if the start of the doc comment comes
		// after other non-whitespace on the same line.
		string* dc = (lineComment && anyToken)
							 ? &t.lineComment
							 : &t.blockComment;

		// Combine with previous doc comment, if any
		if (*dc)
			*dc = combineComments(*dc, cast(string) buf.data[0 .. buf.size]); // TODO: utf decode etc?
		else
		{
			*dc = buf.data;
		}
     +/
	}


    /********************************************
     * Combine two document comments into one,
     * separated by a newline.
     */
     // Save DocComments for later
    static string combineComments(string c1, string c2) { assert(false,"zd cut"); }

    // I think phobos can do this better, I think!!
    static bool isValidIdentifier(string p)
   {
        assert (false);
   } 
    // Writing software is easy. Just erase anything you don't like!
}
