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
import std.array : popBack;
import std.conv;


/**
 * Decoder provides the method for deserializing JSON into a D object.
 */
struct Decoder
{
    alias void delegate(string) MissingHandler;

    /// See: http://lloyd.github.io/yajl/yajl-2.1.0/yajl__parse_8h.html#a5434a7c3b3165d782ea42c17d6ba9ac3
    static struct Option
    {
        bool allowComments;
        bool dontValidateStrings;
        bool allowTrailingGarbage;
        bool allowMultipleValues;
        bool allowPartialValue;

        MissingHandler missingHandler;
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
    MissingHandler _missingHandler;

  public:
    /**
     * Constructs an Decoder object with $(D_PARAM opt).
     */
    @trusted
    this(ref Option opt)
    {
        initialize();
        setDecoderConfig(opt);
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
            return cast(inout(T))fromJSONValue!T(_stack[0].value, this);
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
    bool decode(in const(char)[] json)
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
            _stack.destroy();
    }

    void clear()
    {
        if (_handle !is null) {
            yajl_free(_handle);
            _handle = null;
        }
    }

    @safe
    void checkStatus(in yajl_status status, lazy const(char)[] json)
    {
        if (status != yajl_status.yajl_status_ok)
            throw new YajlException(formatStatus(_handle, json));
    }

    @trusted
    void setDecoderConfig(ref Decoder.Option opt)
    {
        if (opt.allowComments)
            yajl_config(_handle, yajl_option.yajl_allow_comments, 1);
        if (opt.dontValidateStrings)
            yajl_config(_handle, yajl_option.yajl_dont_validate_strings, 1);
        if (opt.allowTrailingGarbage)
            yajl_config(_handle, yajl_option.yajl_allow_trailing_garbage, 1);
        if (opt.allowMultipleValues)
            yajl_config(_handle, yajl_option.yajl_allow_multiple_values, 1);
        if (opt.allowPartialValue)
            yajl_config(_handle, yajl_option.yajl_allow_partial_values, 1);
        if (opt.missingHandler)
            _missingHandler = opt.missingHandler;
    }
}

unittest
{
    static struct Handa
    {
        ulong id;
        string name;
        double height;
        int[] arr;

        bool opEquals(const Handa other)
        {
            return (id == other.id) && (name == other.name) && (height == other.height) && (arr == other.arr);
        }
    }

    Handa handa = Handa(1000, "shinobu", 170.0, [1, 2]);
    immutable json = `{"id":1000,"name":"shinobu","height":170.0,"arr":[1,2]}`;
    { // normal
        Decoder decoder;
        assert(decoder.decode(json));
        assert(decoder.decodedValue!Handa == handa);
    }
    { // with splitted json
        Decoder decoder;
        assert(!decoder.decode(`{"id":1000,"name":"shino`));
        assert(decoder.decode(`bu","height":170.0,"arr":[1,2]}`));
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
    { // json array
        static struct Sect
        {
            string attr = "sect";

            bool opEquals(const Sect other)
            {
                return attr == other.attr;
            }
        }
        immutable composed = `[{"attr":"sect"},{"attr":"sect"},{"attr":"sect"}]`;

        Decoder decoder;
        assert(decoder.decode(composed));
        assert(decoder.decodedValue!(Sect[]) == [Sect(), Sect(), Sect()]);
    }
    { // with missing handler
        int count = 0;
        Decoder.Option opt;
        opt.missingHandler = (string fieldName) { count++; };

        Decoder decoder = Decoder(opt);
        assert(decoder.decode(`{"id":1000,"name":"shinobu"}`));
        assert(decoder.decodedValue!(Handa).id == 1000);
        assert(count == 2);
    }
    { // parse non-json object
        Decoder decoder;
        try {
            decoder.decode(`"string"`);
            assert(false, "Why reach here?");
        } catch (Exception e) { }
    }
}

private:

@trusted
string formatStatus(yajl_handle handle, in const(char)[] json)
{
    import std.c.string : strlen;

    auto msg = yajl_get_error(handle, 1, cast(const(ubyte)*)json.ptr, json.length);
    scope(exit) { yajl_free_error(handle, msg); }

    return cast(string)(msg[0..strlen(cast(const(char*))msg)].dup);
}

@trusted
void setParsedValue(T)(void* ctx, auto ref T value)
{
    import std.conv : text;

    Decoder* decoder = cast(Decoder*)ctx;
    JSONValue v = JSONValue(value);
    if (decoder._nested == 0)
        throw new YajlException(text("JSON must be object or array: type = ", v.type));

    setParsedValueToContainer(decoder, v);
}

@trusted
void setParsedValueToContainer(Decoder* decoder, ref JSONValue value)
{
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
        setParsedValue(ctx, null);

        return 1;
    }

    int callbackBool(void* ctx, int boolean)
    {
        setParsedValue(ctx, boolean != 0);

        return 1;
    }

    int callbackNumber(void* ctx, const(char)* buf, size_t len)
    {
        static bool checkFloatFormat(const(char)* b, size_t l)
        {
            import std.c.string;

            return memchr(b, '.', l) ||
                   memchr(b, 'e', l) ||
                   memchr(b, 'E', l);
        }

        if (checkFloatFormat(buf, len))
            setParsedValue(ctx, to!real(buf[0..len]));
        else
            setParsedValue(ctx, to!long(buf[0..len]));

        return 1;
    }

    int callbackString(void* ctx, const(ubyte)* buf, size_t len)
    {
        setParsedValue(ctx, cast(string)(buf[0..len].dup));

        return 1;
    }

    int callbackStartMap(void* ctx)
    {
        JSONValue[string] obj;
        JSONValue value = JSONValue(obj);

        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested++;
        decoder._stack.length = decoder._nested;
        decoder._stack[decoder._nested - 1] = Decoder.Container(Decoder.ContainerType.mapKey, value);

        return 1;
    }

    int callbackMapKey(void* ctx, const(ubyte)* buf, size_t len)
    {
        setParsedValue(ctx, cast(string)(buf[0..len]));

        return 1;
    }

    int callbackEndMap(void* ctx)
    {
        Decoder* decoder = cast(Decoder*)ctx;
        decoder._nested--;
        if (decoder._nested > 0) {
            setParsedValueToContainer(decoder, decoder._stack[decoder._nested].value);
            decoder._stack.popBack();
        }

        return 1;
    }

    int callbackStartArray(void* ctx)
    {
        JSONValue[] arr;
        JSONValue value = JSONValue(arr);

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
        if (decoder._nested > 0) {
            setParsedValueToContainer(decoder, decoder._stack[decoder._nested].value);
            decoder._stack.popBack();
        }

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
T fromJSONValue(T)(ref const JSONValue value, ref const Decoder decoder)
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : ElementType;
    import std.traits;

    @trusted
    void typeMismatch(string type)
    {
        throw new JSONException(text("Not ", type,": type = ", value.type));
    }

    T result;

    static if (is(Unqual!T U: Nullable!U))
    {
        result = fromJSONValue!U(value, decoder);
    }
    else static if (is(Unqual!T == enum))
    {
        auto temp = fromJSONValue!(OriginalType!T)(value, decoder);
        result = cast(T)(temp);
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
        result = array(map!((a){ return fromJSONValue!(ElementType!T)(a, decoder); })(value.array));
    }
    else static if (isAssociativeArray!T)
    {
        if (value.type == JSON_TYPE.NULL)
            return null;
        if (value.type != JSON_TYPE.OBJECT)
            typeMismatch("object");
        foreach (k, v; value.object)
            result[k] = fromJSONValue!(ValueType!T)(v, decoder);
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
            immutable fieldName = getFieldName!(T, i);
            auto field = fieldName in value.object;
            if (field) {
                v = fromJSONValue!(typeof(v))(*field, decoder);
            } else {
                if (decoder._missingHandler)
                    decoder._missingHandler(fieldName);
            }
        }
    }

    return result;
}
