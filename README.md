# YAJL binding for D

yajl-d is YAJL binding for D.

yajl-d is based on YAJL2.

# Install

Run make for generating libyajld.a

```sh
make
```

## run example

Need to link yajl library

```sh
dmd -Isrc libyajld.a -L-L/path/to/libdir -L-lyajl -run example/encode_bench.d
```

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
