// Written in the D programming language.

module yajl.yajl;

import yajl.common;
import yajl.decoder;
import yajl.encoder;

/**
 * Short-cut for Decoder.decode.
 */
T decode(T = JSONValue)(in const(char)[] json, ref Decoder.Option opt)
{
    Decoder decoder = Decoder(opt);

    if (decoder.decode(json))
        return decoder.decodedValue!T;

    throw new YajlException("Invalid json data");
}

/// ditto
T decode(T = JSONValue)(in const(char)[] json)
{
    Decoder decoder;

    if (decoder.decode(json))
        return decoder.decodedValue!T;

    throw new YajlException("Invalid json data");
}

/**
 * Short-cut for Encoder.encode.
 */
string encode(T)(auto ref T value)
{
    return Encoder().encode(value);
}

/// ditto
string encode(T)(auto ref T value, ref Encoder.Option opt)
{
    return Encoder(opt).encode(value);
}
