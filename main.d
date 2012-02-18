module main;

import dmd.Global;
import dmd.Module;
//import dmd.Lexer;
import dmd.Type;
import dmd.Id;
import dmd.Identifier;
import dmd.Token;

import std.string : toStringz; 
alias toStringz toCString;

import std.exception;
import std.file;
import std.path; 
import std.stdio;
import std.getopt;
import std.process;
import std.array; // split, appender

int main(string[] args)
{
    // gloabal defaults: see dmd.Global.static this(){}
    // Actually it would be nice to get rid of Globals.

    // Deal with options. Just a stub.
    // dealWithOptions();
    // void dealWithOptions()
    // {
    // }

    /+ In theory you have many files, but I'm just overwhelmed
    // trying to get it to compile!
    foreach ( arg; args )
    {
        files ~= arg;
    }
    +/
    // These are now initialized in their appropriate modules
    /+
    Type.init();
    Id.initialize();
    initPrecedence();
    +/
    // Gone. I don't know what it did
    //global.initClasssym();

    // Create Modules
    // I need to just get 1 module working, so I'm cutting out
    // much very important stuff
    Module m;
    m.read(Loc(0));

    // Parse file

    if (global.errors)
        fatal();
    return 0;
}
