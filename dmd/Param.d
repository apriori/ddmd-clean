module dmd.Param;

//import std.stdio; // File[] I just guessed that it were accurate..

// Put command line switches in here
struct Param
{
    bool obj;		// write object file
    bool link;		// perform link
    bool lib;		// write library file instead of object file(s)
    bool multiobj;	// break one object file into multiple ones
    bool oneobj;	// write one object file instead of multiple ones
    bool trace;		// insert profiling hooks
    bool quiet;		// suppress non-error messages
    bool verbose;	// verbose compile
    bool vtls;		// identify thread local variables
    bool symdebug;	// insert debug symbolic information
    bool optimize;	// run optimizer
    bool map;		// generate linker .map file
    bool cpu;		// target CPU
    bool isX86_64;	// generate X86_64 bit code
    bool isLinux;	// generate code for linux
    bool isOSX;		// generate code for Mac OSX
    bool isWindows;	// generate code for Windows
    bool isFreeBSD;	// generate code for FreeBSD
    bool isSolaris;	// generate code for Solaris
    bool scheduler;	// which scheduler to use
    bool useDeprecated;	// allow use of deprecated features
    string[] ddocfiles;	// macro include files for Ddoc

    bool doHdrGeneration;	// process embedded documentation comments
    string hdrdir;		// write 'header' file to docdir directory
    string hdrname;		// write 'header' file to docname

 	 bool doXGeneration; // write JSON file
	 string xfilename;	// write JSON file to xfilename

    uint debuglevel;	// debug level

                              // these associative arrays just hold the strings
                              // but bool should suffice as a placeholder
    bool[string] debugids;		// debug identifiers

    uint versionlevel;	// version level
    bool[string] versionids;		// version identifiers

    bool dump_source;

    string defaultlibname;	// default library for non-debug builds
    string debuglibname;	// default library for debug builds

    string moduleDepsFile;	// filename for deps output
    
    // might use an actual std.outbuffer for this?
    char[] moduleDeps;	// contents to be written to deps file
    // auto moduleDepsBuf = appender(moduleDeps);

    // Hidden debug switches
    bool debuga;
    bool debugb;
    bool debugc;
    bool debugf;
    bool debugr;
    bool debugw;
    bool debugx;
    bool debugy;

    bool run;		// run resulting executable
    string[] runargs;	// arguments for executable

    // Linker stuff
    string[] objfiles;
    string[] linkswitches;
    string[] libfiles;
    string deffile;
    string resfile;
    string exefile;
    string mapfile;
}
