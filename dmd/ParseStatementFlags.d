module dmd.ParseStatementFlags;

alias int ParseStatementFlags;
enum 
{
    PSsemi = 1,		// empty ';' statements are allowed
    PSscope = 2,	// start a new scope
    PScurly = 4,	// { } statement is required
    PScurlyscope = 8,	// { } starts a new scope
}
