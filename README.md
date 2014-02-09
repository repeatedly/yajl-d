# YAJL binding for D

yajl-d is a YAJL binding for D.

yajl-d is based on YAJL2 and tested with YAJL 2.0.4.

# Install

Run make for generating libyajld.a

```sh
make
```

## run example

Need to link yajl library

```sh
dmd -Isrc libyajl-d.a -L-L/path/to/libdir -L-lyajl -run example/encode_bench.d
```

# Usage

## Encode

* yajl.encode(value) / yajl.encode(value, opt)

```d
import yajl.yajl;

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
import yajl.yajl;

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

Decoder#decode is a straming decoder, so you can pass the insufficient json to this method. If Decoder#decode can't parse completely, Decoder#decode returns false.

## Encoder.Option and Decoder.Option

encode and decode can take each Option argument. If you want to know more details, see unittest of yajl.encoder / yajl.decoder.

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
