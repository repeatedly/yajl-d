# build mode: 32bit or 64bit
MODEL ?= $(shell getconf LONG_BIT)
YAJL ?= yajl
YAJL_OPTS = 
DMD ?= dmd

ifeq (,$(YAJL))
	$(error There is no yajl library)
endif

DFLAGS = -Isrc -m$(MODEL) -w -d -L-l$(YAJL) #-property # disable -property for compiling with phobos functions

LIB_NAME = libyajl-d
LIB = $(LIB_NAME).a

ifeq ($(BUILD),debug)
	DFLAGS += -g -debug
else
	DFLAGS += -O -release -nofloat -inline -noboundscheck
endif

ifeq (,$(YAJL_LIBDIR))
	YAJL_OPTS = 
else
	YAJL_OPTS = -L-L$(YAJL_LIBDIR)
endif

D_INSTALL_PATH ?= ~/usr/local/d

SRCS = \
	src/yajl/common.d \
	src/yajl/yajl.d \
	src/yajl/encoder.d \
	src/yajl/decoder.d \
	src/yajl/c/common.d \
	src/yajl/c/gen.d \
	src/yajl/c/parse.d \
	src/yajl/c/tree.d \
	src/yajl/c/version_.d \

target: $(LIB)

$(LIB): $(SRCS)
	$(DMD) $(DFLAGS) -lib -of$@ $(SRCS);

install: $(LIB)
	mkdir -p $(D_INSTALL_PATH)/lib
	mkdir -p $(D_INSTALL_PATH)/src
	cp $(LIB) $(D_INSTALL_PATH)/lib
	cp -r src/yajl $(D_INSTALL_PATH)/src

clean:
	-rm -f $(LIB_NAME).o $(LIB)

MAIN_FILE = "empty_yajl_unittest.d"

unittest:
	make -f posix.mak
	echo 'import yajl.yajl; void main(){}' > $(MAIN_FILE)
	$(DMD) $(DFLAGS) -unittest -of$(LIB) $(YAJL_OPTS) $(SRCS) $(LIB) -run $(MAIN_FILE)
	rm $(MAIN_FILE)
