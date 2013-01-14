// Written in the D programming language.

/**
 * Yajl Decoder
 *
 * Example:
 * -----
 * Decoder decoder;
 * if (decoder.decode(`{"foo":"bar"}`))
 *     assert(decoder.decodedValue!(string[string]) == ["foo":"bar"]);
 * -----
 *
 * See_Also:
 *  $(LINK2 http://lloyd.github.com/yajl/yajl-2.0.1/yajl__parse_8h.html, Yajl parse header)$(BR)
 *
 * Copyright: Copyright Masahiro Nakagawa 2013-.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Masahiro Nakagawa
 */
module yajl.decoder;

import yajl.c.parse;
import yajl.common;

public import std.json;
import std.array : popFront;
import std.conv;


/**
 * Decoder provides the method for deserializing JSON into a D object.
 */
struct Decoder
{
    /// See: http://lloyd.github.com/yajl/yajl-2.0.1/yajl__parse_8h.html#a5434a7c3b3165d782ea42c17d6ba9ac3
    static struct Option
    {
        bool allowComments;
        bool dontValidateStrings;
        bool allowTrailingGarbage;
        bool allowMultipleValues;
        bool allowPartialValue;
    }

  private:
    static enum ContainerType
    {
        arrayItem,
        mapKey,
        mapValue
    }

    static struct Container
    {
        ContainerType type; // value container type
        JSONValue value;    // current value
        string key;         // for map value
    }

    yajl_handle _handle;
    Container[] _stack;
    size_t _nested;

  public:
    /**
     * Constructs an Decoder object with $(D_PARAM opt).
     */
    @trusted
    this(ref Option opt)
    {
        initialize();
        setDecoderConfig(_handle, opt);
    }

    @trusted
    ~this()
    {
        clear();
    }

    @property
    {
        /**
         * Returns the decoded object.
         */
        nothrow ref inout(T) decodedValue(T = JSONValue)() inout if (is(T : JSONValue))
        {
            return _stack[0].value;
        }

        /// ditto
        inout(T) decodedValue(T = JSONValue)() inout if (!is(T : JSONValue))
        {
            return cast(inout(T))fromJSONValue!T(_stack[0].value);
        }
    }

    /**
     * Try to decode the $(D_PARAM json). The decoded result is retrieved from $(LREF decodedValue).
     *
     * Returns:
     *  true if parsing succeeded. Passed json is insufficient, returns false.
     *
     * Throws:
     *  a YajlException when parsing error ocurred.
     */
    bool decode(in string json)
    {
        initialize();

        checkStatus(yajl_parse(_handle, cast(const(ubyte)*)json.ptr, json.length), json);
        if (_nested == 0) {
            checkStatus(yajl_complete_parse(_handle), json);
            return true;
        }

        return false;
    }

  private:
    void initialize()
    {
        if (_handle is null)
            _handle = yajl_alloc(&yajlCallbacks, &yajlAllocFuncs, &this);

        if (_nested == 0)
            _stack.clear();
    }

    void clear()
    {
        if (_handle !is null) {
            yajl_free(_handle);
            _handle = null;
        }
    }

    @safe
    void checkStatus(in yajl_status status, lazy string json)
    {
        if (status != yajl_status.yajl_status_ok)
            throw new YajlException(formatStatus(_handle, json));
    }

    @trusted
    static void setDecoderConfig(yajl_handle handle, ref Decoder.Option opt)
    {
        if (opt.allowComments)
            yajl_config(handle, yajl_option.yajl_allow_comments, 1);
        if (opt.dontValidateStrings)
            yajl_config(handle, yajl_option.yajl_dont_validate_strings, 1);
        if (opt.allowTrailingGarbage)
            yajl_config(handle, yajl_option.yajl_allow_trailing_garbage, 1);
        if (opt.allowMultipleValues)
            yajl_config(handle, yajl_option.yajl_allow_multiple_values, 1);
        if (opt.allowPartialValue)
            yajl_config(handle, yajl_option.yajl_allow_partial_values, 1);
    }
}

unittest
{
    static struct Handa
    {
        ulong id;
        string name;
        double height;

        bool opEquals(const Handa other)
        {
            return (id == other.id) && (name == other.name) && (height == other.height);
        }
    }

    Handa handa = Handa(1000, "shinobu", 170.0);
    immutable json = `{"id":1000,"name":"shinobu","height":170.0}`;
    { // normal
        Decoder decoder;
        assert(decoder.decode(json));
        assert(decoder.decodedValue!Handa == handa);
    }
    { // with splitted json
        Decoder decoder;
        assert(!decoder.decode(`{"id":1000,"name":"shino`));
        assert(decoder.decode(`bu","height":170.0}`));
        assert(decoder.decodedValue!Handa == handa);
    }
    { // with comments
        Decoder.Option opt;
        opt.allowComments = true;

        Decoder decoder = Decoder(opt);
        assert(decoder.decode(`{/* test */ "foo":"bar"}`));
        assert(decoder.decodedValue!(string[string]) == ["foo":"bar"]);
    }
    { // with multiple values
        Decoder.Option opt;
        opt.allowMultipleValues = true;

        int i;
        Decoder decoder = Decoder(opt);
        foreach (_; 0..10) {
            assert(decoder.decode(json));
            assert(decoder.decodedValue!Handa == handa);
            i++;
        }
        assert(i == 10);
    }
}

private:

@trusted
string formatStatus(yajl_handle handle, in string json)
{
    import std.c.string : strlen;

    auto msg = yajl_get_error(handle, 1, cast(const(ubyte)*)json.ptr, json.length);
    scope(exit) { yajl_free_error(handle, msg); }

    return cast(string)(msg[0..strlen(cast(const(char*))msg)].dup);
}

@trusted
void setParsedValue(void* ctx, JSONValue value)
{
    setParsedValue(ctx, value);
}

@trusted
void setParsedValue(void* ctx, ref JSONValue value)
{
    Decoder* decoder = cast(Decoder*)ctx;
    
    auto container = &decoder._stack[decoder._nested - 1];
    final switch (container.type) {
    case Decoder.ContainerType.arrayItem:
        container.value.array ~= value;
        break;
    case Decoder.ContainerType.mapKey:
        container.key = value.str;
        container.type = Decoder.ContainerType.mapValue;
        break;
    case Decoder.ContainerType.mapValue:
        container.value.object[container.key] = value;
        container.type = Decoder.ContainerType.mapKey;
        break;
    }
}

extern(C)
{
    int callbackNull(void* ctx)
    {
        JSONValue value;
        value.type = JSON_TYPE.NULL;
        setParsedValue(ctx, value);

        return 1;
    }

    int callbackBool(void* ctx, int boolean)
    {
        JSONValue value;
        value.type = boolean ? JSON_TYPE.TRUE : JSON_TYPE.FALSE;
        setParsedValue(ctx, value);

        return 1;
    }

    /**
     * callbackInt and callbackFloat are not used when callbackNumber is passed.
    int callbackInt(void* ctx, long number)
    {
        JSONValue value;
        value.type = JSON_TYPE.INTEGER;
        value.integer = number;
        setParsedValue(ctx, value);

        return 1;
    }

    int callbackFloat(void* ctx, double number)
    {
        JSONValue value;
        value.type = JSON_TYPE.FLOAT;
        value.floating = number;
        setParsedValue(ctx, value);

        return 1;
    }
    */

    int callbackNumber(void* ctx, const(char)* buf, size_t len)
    {
        static bool checkFloatFormat(const(char)* b, size_t l)
        {
            import std.c.string;

            return memchr(b, '.', l) ||
                   memchr(b, 'e', l) ||
                   memchr(b, 'E', l);
        }

        JSONValue value;
        if (checkFloatFormat(buf, len)) {
            value.floating = to!double(buf[0..len]);
            value.type = JSON_TYPE.FLOAT;
        } else {
            value.integer = to!long(buf[0..len]);
            value.type = JSON_TYPE.INTEGER;
        }
        setParsedValue(ctx, value);

        return 1;
    }

    int callbackString(void* ctx, const(ubyte)* buf, size_t len)
    {
        JSONValue value;
        value.type = JSON_TYPE.STRING;
        value.str = cast(string)(buf[0..len]);
        setParsedValue(ctx, value);

        return 1;
    }

    int callbackStartMap(void* ctx)
    {
        JSONValue value;
        value.type = JSON_TYPE.OBJECT;

        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested++;
        decoder._stack.length = decoder._nested;
        decoder._stack[decoder._nested - 1] = Decoder.Container(Decoder.ContainerType.mapKey, value);

        return 1;
    }

    int callbackMapKey(void* ctx, const(ubyte)* buf, size_t len)
    {
        JSONValue value;
        value.type = JSON_TYPE.STRING;
        value.str = cast(string)(buf[0..len].dup);
        setParsedValue(ctx, value);

        return 1;
    }

    int callbackEndMap(void* ctx)
    {
        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested--;

        if (decoder._stack.length > 1)
            decoder._stack.popFront();

        return 1;
    }

    int callbackStartArray(void* ctx)
    {
        JSONValue value;
        value.type = JSON_TYPE.ARRAY;

        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested++;
        decoder._stack.length = decoder._nested;
        decoder._stack[decoder._nested - 1] = Decoder.Container(Decoder.ContainerType.arrayItem, value);

        return 1;
    }

    int callbackEndArray(void* ctx)
    {
        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested--;

        if (decoder._stack.length > 1)
            decoder._stack.popFront();

        return 1;
    }

    yajl_callbacks yajlCallbacks = yajl_callbacks(&callbackNull,
                                                  &callbackBool,
                                                  null,
                                                  null,
                                                  &callbackNumber,
                                                  &callbackString,
                                                  &callbackStartMap,
                                                  &callbackMapKey,
                                                  &callbackEndMap,
                                                  &callbackStartArray,
                                                  &callbackEndArray);
}

@trusted
T fromJSONValue(T)(ref const JSONValue value)
{
    import std.traits;

    @trusted
    void typeMismatch(string type)
    {
        throw new JSONException(text("Not ", type,": type = ", value.type));
    }

    T result;

    static if (is(Unqual!T U: Nullable!U))
    {
        result = fromJSONValue!U(value);
    }
    else static if (isBoolean!T)
    {
        if (value.type != JSON_TYPE.TRUE && value.type != JSON_TYPE.FALSE)
            typeMismatch("boolean");
        result = value.type == JSON_TYPE.TRUE;
    }
    else static if (isIntegral!T)
    {
        if (value.type != JSON_TYPE.INTEGER)
            typeMismatch("integer");
        result = value.integer.to!T();
    }
    else static if (isFloatingPoint!T)
    {
        switch (value.type) {
        case JSON_TYPE.FLOAT:
            result = value.floating.to!T();
            break;
        case JSON_TYPE.INTEGER:
            result = value.integer.to!T();
            break;
        case JSON_TYPE.STRING: // for "INF"
            result = value.str.to!T();
            break;
        default:
            typeMismatch("floating point");
        }
    }
    else static if (isSomeString!T)
    {
        if (value.type == JSON_TYPE.NULL)
            return null;
        if (value.type != JSON_TYPE.STRING)
            typeMismatch("string");
        result = value.str.to!T();
    }
    else static if (isArray!T)
    {
        if (value.type == JSON_TYPE.NULL)
            return null;
        if (value.type != JSON_TYPE.ARRAY)
            typeMismatch("array");
        result = array(map!((a){ return fromJSONValue!(ElementType!T)(a); })(value.array));
    }
    else static if (isAssociativeArray!T)
    {
        if (value.type == JSON_TYPE.NULL)
            return null;
        if (value.type != JSON_TYPE.OBJECT)
            typeMismatch("object");
        foreach (k, v; value.object)
            result[k] = fromJSONValue!(ValueType!T)(v);
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value.type == JSON_TYPE.NULL)
                return null;
        }

        if (value.type != JSON_TYPE.OBJECT)
            typeMismatch("object");

        static if (is(T == class))
        {
            result = new T();
        }

        foreach(i, ref v; result.tupleof) {
            auto field = getFieldName!(T, i) in value.object;
            if (field)
                v = fromJSONValue!(typeof(v))(*field);
        }
    }

    return result;
}
