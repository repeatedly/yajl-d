import yajl.yajl;

import std.datetime;
import std.stdio;

static struct Handa
{
    static struct AAA
    {
        bool ok;
    }

    ulong id;
    string name;
    double height;
    Nullable!AAA aaa;
}

void main()
{
    immutable Num = 10000;

    Handa handa;
    handa.id = 1000;
    handa.name = "shinobu";
    handa.height = 169.5;
    handa.aaa = Handa.AAA(true);

    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            toJSON(toJSONValue(handa));
        }
        sw.stop();
        writefln("json %s QPS: ", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            encode(handa);
        }
        sw.stop();
        writefln("yajl %s QPS: ", Num / sw.peek().to!("seconds", real));
    }
}

import std.conv;
import std.json;
import std.typecons;
import std.traits;

@trusted
{
    string toJSON(const JSONValue value)
    {
        return toJSON(value);
    }

    string toJSON(ref const JSONValue value)
    {
        return std.json.toJSON(&value);
    }
}

@trusted
JSONValue toJSONValue(T)(auto ref T value)
{
    JSONValue result;

    static if (isBoolean!T)
    {
        result.type = value ? JSON_TYPE.TRUE : JSON_TYPE.FALSE;
    }
    else static if (isIntegral!T)
    {
        result.type = JSON_TYPE.INTEGER;
        result.integer = value;
    }
    else static if (isFloatingPoint!T)
    {
        result.type = JSON_TYPE.FLOAT;
        result.floating = value;
    }
    else static if (isSomeString!T)
    {
        result.type = JSON_TYPE.STRING;
        result.str = text(value);
    }
    else static if (isArray!T)
    {
        result.type = JSON_TYPE.ARRAY;
        result.array = array(map!((a){ return a.toJSONValue(); })(value));
    }
    else static if (isAssociativeArray!T)
    {
        result.type = JSON_TYPE.OBJECT;
        foreach (k, v; value)
            result.object[k] = v.toJSONValue();
    }
    else static if (isTuple!T)
    {
        result.type = JSON_TYPE.ARRAY;
        foreach (i, Type; T.Types)
            result.array ~= value[i].toJSONValue();
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value is null) {
                result.type = JSON_TYPE.NULL;
                return result;
            }
        }

        result.type = JSON_TYPE.OBJECT;
        foreach(i, v; value.tupleof) {
            static if (isNullable!(typeof(v)))
            {
                if (!v.isNull)
                    result.object[getFieldName!(T, i)] = v.get.toJSONValue();
            }
            else
            {
                result.object[getFieldName!(T, i)] = v.toJSONValue();
            }
        }
    }

    return result;
}

private template getFieldName(Type, size_t i)
{
    static assert((is(Type == class) || is(Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    // 3 means () + .
    enum getFieldName = Type.tupleof[i].stringof[3 + Type.stringof.length..$];
}

template isNullable(T)
{
    static if (is(Unqual!T U: Nullable!U))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}
