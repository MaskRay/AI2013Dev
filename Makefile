.SUFFIXES:
.PHONY: all dist clean release wine

#CXXFLAGS += -Wextra -I. -O2
#CXXFLAGS += -Wextra -I. -g -fno-default-inline
CXXFLAGS += -Wextra -I. -g
MINGW := /opt/mingw/bin/i686-w64-mingw32-g++

DIST_SRC := *.cc *.h *.cpp --exclude Main.cpp
RELEASE_SRC := $(DIST_SRC) win/a.dll

SRC := $(wildcard *.cc)
PLATFORM_SRC := $(wildcard Platform/*.cpp)
OBJ := $(addprefix build/,$(notdir $(SRC:.cc=.o)))
WIN_OBJ := $(addprefix win/,$(notdir $(SRC:.cc=.o)))
PLATFORM_OBJ := $(addprefix build/Platform/,$(notdir $(PLATFORM_SRC:.cpp=.o)))

all: win/a.dll build/a.so main platform

# Windows DLL

win/a.dll: CXX := $(MINGW)
win/a.dll: CXXFLAGS += -static
win/a.dll: $(WIN_OBJ) win/Strategy.o | win
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@ -shared

win/%.o: CXX := $(MINGW)
win/%.o: CXXFLAGS += -O3
win/%.o: %.cc | win
	$(MINGW) -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

win/Strategy.o: Strategy.cpp
	$(MINGW) -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

sinclude $(WIN_OBJ:.o=.d)

# Linux so

build/%.so: CXXFLAGS += -fPIC
build/a.so: $(OBJ) build/Strategy.o | build
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@ -shared

build/%.o: CXXFLAGS += -fPIC
build/%.o: %.cc | build
	g++ -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

build/Strategy.o: Strategy.cpp
	g++ -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

sinclude $(OBJ:.o=.d)

# Linux eval test

main: $(OBJ) build/Main.o
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@

build/Main.o: Main.cpp
	g++ -std=c++11 -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

sinclude build/Main.d

# Linux platform

platform: CXXFLAGS += -ldl
platform: $(PLATFORM_OBJ)
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@

build/Platform/%.o: Platform/%.cpp | build/Platform
	g++ -std=c++11 -MM -MP -MT $@ -MF $(@:.o=.d) $<
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

sinclude $(PLATFORM_OBJ:.o=.d)

# mkdir

build win build/Platform:
	mkdir -p $@

# misc

clean:
	-$(RM) -r build win platform main

dist:
	tar zcf /tmp/dist.tar.gz --transform 's,^,$P/,' $(DIST_SRC)

release: all
	tar zcf /tmp/release.tar.gz --transform 's,^,$P/,' $(RELEASE_SRC)

wine:
	wine Compete.exe win/a.dll TestCases/24.dll /tmp/out 10
