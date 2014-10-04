import yajl;

import std.datetime;
import std.stdio;
import std.typecons;

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
        writefln("json:        %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        foreach (i; 0..Num) {
            encode(handa);
        }
        sw.stop();
        writefln("yajl(one):   %s QPS", Num / sw.peek().to!("seconds", real));
    }
    {
        auto sw = StopWatch(AutoStart.yes);
        Encoder encoder = Encoder();
        foreach (i; 0..Num) {
            encoder.encode(handa);
        }
        sw.stop();
        writefln("yajl(multi): %s QPS", Num / sw.peek().to!("seconds", real));
    }
}

import std.conv;
import std.json;
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

    static if (isTuple!T)
    {
        JSONValue[] arr;
        foreach (i, Type; T.Types)
            arr ~= value[i].toJSONValue();
        result = arr;
    }
    else static if (is(T == struct) || is(T == class))
    {
        static if (is(T == class))
        {
            if (value is null) {
                result = null;
                return result;
            }
        }

        JSONValue[string] obj;
        foreach(i, v; value.tupleof) {
            static if (isNullable!(typeof(v)))
            {
                if (!v.isNull)
                    obj[getFieldName!(T, i)] = v.get.toJSONValue();
            }
            else
            {
                obj[getFieldName!(T, i)] = v.toJSONValue();
            }
        }
        result = obj;
    }
    else
    {
        result = value;
    }

    return result;
}

private template getFieldName(Type, size_t i)
{
    static assert((is(Type == class) || is(Type == struct)), "Type must be class or struct: type = " ~ Type.stringof);
    static assert(i < Type.tupleof.length, text(Type.stringof, " has ", Type.tupleof.length, " attributes: given index = ", i));

    enum getFieldName = __traits(identifier, Type.tupleof[i]);
}

template isNullable(N)
{
    static if(is(N == Nullable!(T), T) ||
              is(N == NullableRef!(T), T) ||
              is(N == Nullable!(T, nV), T, alias nV) &&
              is(typeof(nV) == T))
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}
