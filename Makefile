# build mode: 32bit or 64bit
MODEL ?= $(shell getconf LONG_BIT)
YAJL ?= yajl

ifeq (,$(DMD))
	DMD := dmd
endif

ifeq (,$(YAJL))
	$(error There is no yajl library)
endif

DFLAGS = -Isrc -m$(MODEL) -w -d -property -L-l$(YAJL)

LIB_NAME = libyajld
LIB = $(LIB_NAME).a

ifeq ($(BUILD),debug)
	DFLAGS += -g -debug
else
	DFLAGS += -O -release -nofloat -inline -noboundscheck
endif

SRCS = \
	src/yajl/exception.d \
	src/yajl/yajl.d \
	src/yajl/encoder.d \
	src/yajl/parser.d \
	src/yajl/c/common.d \
	src/yajl/c/gen.d \
	src/yajl/c/parse.d \
	src/yajl/c/tree.d \
	src/yajl/c/version_.d \

target: $(LIB)

$(LIB): $(SRCS)
	$(DMD) $(DFLAGS) -lib -of$@ $(SRCS);

clean:
	-rm -f $(LIB_NAME).o $(LIB)
