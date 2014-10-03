# YAJL binding for D

yajl-d is a YAJL binding for D.

yajl-d is based on YAJL2 and tested with YAJL 2.1.0.

# Run example

Need to link yajl library

```sh
dmd -Isrc src/**/*.d -L-lyajl -run example/encode_bench.d
```

# Usage

## Encode

* yajl.encode(value) / yajl.encode(value, opt)

```d
import yajl;

struct Hoge
{ 
    ulong id;
    string word;
    bool yes; 
}

// {"id":100,"word":"hey!","yes":true}
string json = encode(Hoge(100, "hey!", true));
```

## Decode

* yajl.decode(value) / yajl.decode(value, opt)

```d
import yajl;

Hoge hoge = decode!Hoge(`{"id":100,"word":"hey!","yes":true}`);
```

* yajl.decoder.Decoder

Use decode and decodedValue methods.

```d
import yajl.decoder;

Decoder decoder;
if (decoder.decode(`{"id":100,"word":"hey!","yes":true}`) {
    Hoge hoge = decoder.decodedValue!Hoge;
    // ...
}
```

Decoder#decode is a straming decoder, so you can pass the insufficient json to this method. If Decoder#decode can't parse completely, Decoder#decode returns `false`.

## Encoder.Option and Decoder.Option

`encode` and `decode` can take each Option argument. If you want to know more details, see unittest of yajl.encoder / yajl.decoder.

### Set callback to detect missing field

You can set own callback to `Decoder.Option.missingHandler`.
Here is an example:

```d
import yajl;
import std.stdio;

struct Test
{
  string name;
  int age;
}

void main()
{
  auto test = Test("Bob", 20);
  auto encoded = `{ "name": "Bob", "age": 20}`;
  auto missing = `{ "name": "Bob"}`;

  Decoder.Option opt;
  opt.missingHandler = (string field) { writeln(field); };
  writeln(decode!Test(encoded, opt));
  writeln(decode!Test(missing, opt)); // Callback called with missing field
}
```

## Using a D keyword in JSON field names

Since a field name cannot be a D keyword, for example body or out, the variable and JSON field must have separate names. For this, use the @JSONName("name") attribute:

```d
import yajl;

struct Hoge
{ 
    ulong id;
    @JSONName("body") string _body;
    bool yes; 
}

// {"id":100,"body":"hey!","yes":true}
string json = encode(Hoge(100, "hey!", true));
```

# Perfomance comparison

D: dmd 2.065.0
OS: Mac OS X ver 10.9<br />
CPU: 2.6 GHz Intel Core i7<br />

<table>
  <tr>
    <th></th><th>encode(QPS)</th><th>decode(QPS)</th><th>streaming decode(QPS)</th>
  </tr>
  <tr>
    <td>std.json</td><td>221455</td><td>197332</td><td>Not supported</td>
  </tr>
  <tr>
    <td>yajl-d</td><td>706175</td><td>530527</td><td>810994</td>
  </tr>
</table>

Benchmark code can be found in the `example` directory.

# TODO

* Limited direct conversion decoding
* Test on Windows

# Link

* [yajl](http://lloyd.github.com/yajl/)

  YAJL official site

* [yajl-d repository](https://github.com/repeatedly/yajl-d)

  Github repository

# Copyright

<table>
  <tr>
    <td>Author</td><td>Masahiro Nakagawa <repeatedly@gmail.com></td>
  </tr>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2013- Masahiro Nakagawa</td>
  </tr>
  <tr>
    <td>License</td><td>Boost Software License, Version 1.0</td>
  </tr>
</table>
