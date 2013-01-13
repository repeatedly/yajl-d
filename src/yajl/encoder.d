// Written in the D programming language.

/**
 * Yajl Encoder
 *
 * Example:
 * -----
 * Encoder encoder;
 * assert(encoder.encode(["foo":"bar"] == `{"foo":"bar"}`));
 * -----
 *
 * with option:
 * -----
 * Encoder.Option opt;
 * opt.beautify = true;
 * opt.indentString = "  "; 
 * Encoder encoder = Encoder(opt);
 * assert(encoder.encode(["foo":"bar"] ==
 * `{
 *    "foo": "bar"
 * }
 * `));
 * -----
 *
 * See_Also:
 *  $(LINK2 http://lloyd.github.com/yajl/yajl-2.0.1/yajl__gen_8h.html, Yajl gen header)$(BR)
 *
 * Copyright: Copyright Masahiro Nakagawa 2013-.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Masahiro Nakagawa
 */
module yajl.encoder;

import yajl.c.common;
import yajl.c.gen;
import yajl.exception;

import core.memory : GC;

import std.traits;


/**
 * Encoder provides the method for serializing a D object into JSON format.
 */
struct Encoder
{
    //alias yajl_print_t PrintCallback;

    /// See: http://lloyd.github.com/yajl/yajl-2.0.1/yajl__gen_8h.html#a57c29080044a7231ac0cf1fead4de4b0
    static struct Option
    {
        bool beautify;
        bool validateUTF8;
        bool escapeSolidus;
        string indentString;
        //PrintCallback printCallback; // TODO: Fix "killed by signal 11"
    }

  private:
    yajl_gen _gen;

  public:
    /**
     * Constructs an Encoder object with $(D_PARAM opt).
     */
    @trusted
    this(ref Option opt)
    {
        initialize();
        setEncoderConfig(_gen, opt);
    }

    @trusted
    ~this()
    {
        clear();
    }

    /**
     * Encodes an argument and returns the JSON.
     */
    @trusted
    string encode(T)(auto ref T value)
    {
        // YAJL2 doesn't provide reset API to resue object.
        // See: https://github.com/lloyd/yajl/pull/76
        if (_gen is null)
            initialize();

        yajlGenerate(_gen, value);

        ubyte* resultBuffer;
        size_t resultLength;

        yajl_gen_get_buf(_gen, &resultBuffer, &resultLength);

        string result = cast(string)resultBuffer[0..resultLength].dup;
        yajl_gen_clear(_gen);

        return result;
    }

  private:
    void initialize()
    {
        _gen = yajl_gen_alloc(&yajlAllocFuncs);
    }

    void clear()
    {
        if (_gen !is null)
            yajl_gen_free(_gen);
    }
}

unittest
{
    static struct Handa
    {
        ulong id;
        string name;
        double height;
    }

    Handa handa = Handa(1000, "shinobu", 169.5);

    {
        Encoder encoder;
        assert(encoder.encode(handa) == `{"id":1000,"name":"shinobu","height":169.5}`);
    }
    { // opt
        Encoder.Option opt;
        opt.beautify = true;
        opt.indentString = "  ";
        assert(Encoder(opt).encode(handa) == `{
  "id": 1000,
  "name": "shinobu",
  "height": 169.5
}
`);
    }
}

private:

@trusted
void setEncoderConfig(yajl_gen gen, ref Encoder.Option opt)
{
    import std.string : toStringz;

    if (opt.beautify)
        yajl_gen_config(gen, yajl_gen_option.yajl_gen_beautify, 1);
    if (opt.validateUTF8)
        yajl_gen_config(gen, yajl_gen_option.yajl_gen_validate_utf8, 1);
    if (opt.escapeSolidus)
        yajl_gen_config(gen, yajl_gen_option.yajl_gen_escape_solidus, 1);
    if (opt.indentString)
        yajl_gen_config(gen, yajl_gen_option.yajl_gen_indent_string, toStringz(opt.indentString));
    //if (opt.printCallback)
    //    yajl_gen_config(gen, yajl_gen_option.yajl_gen_print_callback, opt.printCallback);
}

@trusted
void yajlGenerate(T)(yajl_gen gen, auto ref T value)
{
    import std.conv : to;
    import std.typecons : isTuple;

    static if (isBoolean!T)
    {
        checkStatus(yajl_gen_bool(gen, value ? 1 : 0));
    }
    else static if (isIntegral!T)
    {
        checkStatus(yajl_gen_integer(gen, value));
    }
    else static if (isFloatingPoint!T)
    {
        checkStatus(yajl_gen_double(gen, value));
    }
    else static if (isSomeString!T)
    {
        checkStatus(yajl_gen_string(gen, cast(const(ubyte)*)value.ptr, value.length));
    }
    else static if (isArray!T)
    {
        if (value is null) {
            checkStatus(yajl_gen_null(gen));
        } else {
            checkStatus(yajl_gen_array_open(gen));
            foreach (ref v; value)
                yajlGenerate(gen, v);
            checkStatus(yajl_gen_array_close(gen));
        }
    }
    else static if (isAssociativeArray!T)
    {
        if (value is null) {
            checkStatus(yajl_gen_null(gen));
        } else {
            checkStatus(yajl_gen_map_open(gen));
            foreach (k, ref v; value) {
                yajlGenerate(gen, to!string(k));
                yajlGenerate(gen, v);
            }
            checkStatus(yajl_gen_map_close(gen));
        }
    }
    else static if (isTuple!T)
    {
        checkStatus(yajl_gen_array_open(gen));
        foreach (i, Type; T.Types)
            yajlGenerate(gen, value[i]);
        checkStatus(yajl_gen_array_close(gen));
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value is null) {
                checkStatus(yajl_gen_null(gen));
                return;
            }
        }

        checkStatus(yajl_gen_map_open(gen));
        foreach(i, ref v; value.tupleof) {
            static if (isNullable!(typeof(v)))
            {
                if (!v.isNull) {
                    yajlGenerate(gen, getFieldName!(T, i));
                    yajlGenerate(gen, v.get);
                }
            }
            else
            {
                yajlGenerate(gen, getFieldName!(T, i));
                yajlGenerate(gen, v);
            }
        }
        checkStatus(yajl_gen_map_close(gen));
    }

    return;
}

// status check is needed?
void checkStatus(yajl_gen_status status) pure
{
    if (status != yajl_gen_status.yajl_gen_status_ok)
        throw new YajlException(formatStatus(status));
}

string formatStatus(yajl_gen_status status) pure
{
    final switch (status) {
	case yajl_gen_status.yajl_gen_status_ok:
        return null;
	case yajl_gen_status.yajl_gen_keys_must_be_strings:
        return "A map key is generated, a function other than yajl_gen_string was called";
	case yajl_gen_status.yajl_max_depth_exceeded:
        return "YAJL's maximum generation depth was exceeded";
	case yajl_gen_status.yajl_gen_in_error_state:
        return "A generator function was called while in an error state";
	case yajl_gen_status.yajl_gen_generation_complete:
        return "A complete JSON document has been generated";
	case yajl_gen_status.yajl_gen_invalid_number:
        return "Invalid floating point value (infinity or NaN)";
	case yajl_gen_status.yajl_gen_no_buf:
        return "There is no internal buffer to get from print callback";
    case yajl_gen_status.yajl_gen_invalid_string:
        return "Returned invalid utf8 string from yajl_gen_string";
    }
}

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

template getFieldName(Type, size_t i)
{
    import std.conv : text;

    static assert((is(Type == class) || is(Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    // 3 means () + .
    enum getFieldName = Type.tupleof[i].stringof[3 + Type.stringof.length..$];
}

template isNullable(T)
{
    import std.typecons : Nullable;

    static if (is(Unqual!T U: Nullable!U))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}
