// Written in the D programming language.

module yajl.common;

import yajl.c.common;

import core.memory : GC;

/// Exception for yajl-d
class YajlException : Exception
{
    pure @trusted
    this(string msg, string filename = __FILE__, size_t line = __LINE__)
    {
        super(msg, filename, line);
    }
}

package:

extern(C)
{
    void* yajlMalloc(void *ctx, size_t sz)
    {
        return GC.malloc(sz);
    }

    void* yajlRealloc(void *ctx, void * previous, size_t sz)
    {
        return GC.realloc(previous, sz);
    }

    void yajlFree(void *ctx, void * ptr)
    {
        GC.free(ptr);
    }

    yajl_alloc_funcs yajlAllocFuncs = yajl_alloc_funcs(&yajlMalloc, &yajlRealloc, &yajlFree);
}

struct JSONName
{
    string name;
}

template getFieldName(Type, size_t i)
{
    import std.conv : text;

    static assert((is(Type == class) || is(Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    string helper() {
        foreach(attribute; __traits(getAttributes, Type.tupleof[i]))
        {
            static if(is(typeof(attribute) == JSONName))
            {
                return attribute.name;
            }
        }

        return __traits(identifier, Type.tupleof[i]);
    }

    enum getFieldName = helper();
}

// Code from: http://forum.dlang.org/thread/tkxmfencyhgnxopcsljw@forum.dlang.org#post-mailman.294.1386309272.3242.digitalmars-d-learn:40puremagic.com
template isNullable(N)
{
    static if(is(N == Nullable!(T), T) ||
              is(N == NullableRef!(T), T) ||
              is(N == Nullable!(T, nV), T, alias nV) && is(typeof(nV) == T))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}

unittest
{
    import std.typecons : Nullable;

    static assert(isNullable!(Nullable!int));
    static assert(isNullable!(const Nullable!int));
    static assert(isNullable!(immutable Nullable!int));

    static assert(!isNullable!int);
    static assert(!isNullable!(const int));

    struct S {}
    static assert(!isNullable!S);
}
