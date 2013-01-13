module yajl.yajl;

public import yajl.encoder;

/**
 * Short cut for Encoder.encode.
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
