PERCYINC = ../percy
PERCYLIB = ../percy
NTLINC = /usr/local/include/NTL
NTLLIB = /usr/local/lib
RELICDIR = ../relic
RELICINC = $(RELICDIR)/include
RELICWRAPINC = relicwrapper/
RELICLIB = $(RELICDIR)/lib
RELICWRAPLIB = relicwrapper/
LINKRELIC = -L$(RELICLIB) -lrelic_s -lgmp -L$(RELICWRAPLIB) -lrelicwrapper
CC = gcc
CXX = g++
CXXFLAGS = -O0 -g -Wall -Wextra -Werror -Wno-deprecated-declarations -Wno-non-template-friend -fPIC \
	-I$(RELICWRAPINC) -I$(RELICINC) -I$(PERCYINC) -I$(NTLINC)
CFLAGS = -O0 -g -Wall -Wextra -Werror -Wno-deprecated-declarations -fPIC
LDLIBS = -lcrypto $(LINKRELIC)
GTEST_DIR = ../gtest-1.7.0
CXXFLAGS += -isystem $(PERCYINC) -isystem $(RELICWRAPINC) -isystem $(GTEST_DIR)/include

BINS = libdp5
TESTS = test_dh test_hashes test_prf test_enc test_epoch \
	test_rsconst test_rsreg test_client test_reqcd \
	test_lscd test_pirglue test_pirgluemt test_integrate
UNITTESTS:=$(patsubst %.cpp,%,$(wildcard *_unittest.cpp))


UNAME = $(shell uname -s)
ifeq ($(UNAME),Darwin)
	ARCHFLAGS = ARCHFLAGS="-arch x86_64"
endif

all: $(BINS) $(TESTS) $(UNITTESTS)

test: $(UNITTESTS)
	@for test in $(UNITTESTS) ; do ./$$test ; done

python: libdp5 dp5py.cpp setup.py
	$(ARCHFLAGS) python setup.py build
	rm -f dp5.so
	cp `find build -name dp5.so` dp5.so

gtest-all.o : $(GTEST_SRCS_)
	$(CXX)  -I$(GTEST_DIR) -I$(GTEST_DIR)/include $(CXXFLAGS) -pthread -c \
            $(GTEST_DIR)/src/gtest-all.cc


gtest_main.o : $(GTEST_SRCS_)
	$(CXX) $(CPPFLAGS) -I$(GTEST_DIR) $(CXXFLAGS) -pthread -c \
            $(GTEST_DIR)/src/gtest_main.cc

gtest.a : gtest-all.o
	$(AR) $(ARFLAGS) $@ $^

gtest_main.a : gtest-all.o gtest_main.o
	$(AR) $(ARFLAGS) $@ $^


libdp5: dp5lookupserver.o dp5regserver.o dp5regclient.o dp5lookupclient.o dp5params.o curve25519-donna.o
	ar rcs $@.a $^

test_dh: test_dh.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_hashes: test_hashes.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_prf: test_prf.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_enc: test_enc.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_epoch: test_epoch.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_rsconst: test_rsconst.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS)

test_rsreg: test_rsreg.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -lpthread

test_client: test_client.o dp5params.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -lpthread $(LINKRELIC)

test_reqcd: test_reqcd.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -L$(PERCYLIB) -lpercyclient -L$(NTLLIB) -lntl -lgmp

test_lscd: test_lscd.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -L$(PERCYLIB) -lpercyserver -L$(NTLLIB) -lntl -lgmp

test_pirglue: test_pirglue.o dp5lookupclient.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -L$(PERCYLIB) -lpercyclient -lpercyserver -L$(NTLLIB) -lntl -lgmp

test_pirgluemt: test_pirgluemt.o dp5lookupclient.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -L$(PERCYLIB) -lpercyclient -lpercyserver -L$(NTLLIB) -lntl -lgmp -lpthread

test_integrate: test_integrate.o dp5lookupclient.o dp5lookupserver.o dp5regserver.o dp5regclient.o dp5params.o dp5metadata.o curve25519-donna.o
	g++ -g $^ -o $@ $(LDFLAGS) $(LDLIBS) -L$(PERCYLIB) -lpercyclient -lpercyserver -L$(NTLLIB) -lntl -lgmp

test_dh.o: dp5params.cpp dp5params.h
	g++ $(CXXFLAGS) -DTEST_DH -c $< -o $@

test_hashes.o: dp5params.cpp dp5params.h
	g++ $(CXXFLAGS) -DTEST_HASHES -c $< -o $@

test_prf.o: dp5params.cpp dp5params.h
	g++ $(CXXFLAGS) -DTEST_PRF -c $< -o $@

test_enc.o: dp5params.cpp dp5params.h
	g++ $(CXXFLAGS) -DTEST_ENC -c $< -o $@

test_epoch.o: dp5params.cpp dp5params.h
	g++ $(CXXFLAGS) -DTEST_EPOCH -c $< -o $@

test_rsconst.o: dp5regserver.cpp dp5regserver.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_RSCONST -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

test_rsreg.o: dp5regserver.cpp dp5regserver.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_RSREG -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

test_client.o: dp5regclient.cpp dp5regclient.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_CLIENT -c $< -o $@

test_reqcd.o: dp5lookupclient.cpp dp5lookupclient.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_REQCD -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

test_lscd.o: dp5lookupserver.cpp dp5lookupserver.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_LSCD -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

test_pirglue.o: dp5lookupserver.cpp dp5lookupserver.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_PIRGLUE -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

test_pirgluemt.o: dp5lookupserver.cpp dp5lookupserver.h dp5params.h
	g++ $(CXXFLAGS) -DTEST_PIRGLUEMT -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

dp5regserver.o: dp5regserver.cpp dp5regserver.h dp5params.h
	g++ $(CXXFLAGS) -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

dp5regclient.o: dp5regclient.cpp dp5regclient.h dp5params.h
	g++ $(CXXFLAGS) -c $< -o $@

dp5combregclient.o: dp5combregclient.cpp dp5combregclient.h dp5params.h
	g++ $(CXXFLAGS) -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

dp5lookupclient.o: dp5lookupclient.cpp dp5lookupclient.h dp5params.h
	g++ $(CXXFLAGS) -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

dp5lookupserver.o: dp5lookupserver.cpp dp5lookupserver.h dp5params.h
	g++ $(CXXFLAGS) -I$(PERCYINC) -I$(NTLINC) -c $< -o $@

dp5params.o: dp5params.cpp dp5params.h
	g++ $(CPPFLAGS) $(CXXFLAGS) -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

test_integrate.o: dp5integrationtest.cpp dp5lookupclient.h dp5lookupserver.h dp5regserver.h dp5regclient.h dp5params.h
	g++ $(CXXFLAGS) -I$(PERCYINC) -I$(NTLINC) -I$(RELICWRAPINC) -I$(RELICINC) -c $< -o $@

pairing_unittest.o: pairing_unittest.cpp dp5params.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR)/include -I$(RELICWRAPINC) -I$(RELICINC) -c pairing_unittest.cpp
pairing_unittest: pairing_unittest.o dp5params.o curve25519-donna.o gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDLIBS) -L$(RELICWRAPLIB) -L$(RELICLIB) -lrelicwrapper -lrelic_s -lgmp -lpthread -o $@
dp5combregclient_unittest.o: dp5combregclient_unittest.cpp dp5combregclient.h dp5params.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR)/include -I$(RELICWRAPINC) -I$(RELICINC) -c dp5combregclient_unittest.cpp
dp5combregclient_unittest: dp5combregclient_unittest.o dp5combregclient.o dp5params.o curve25519-donna.o gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDLIBS) -L$(RELICWRAPLIB) -L$(RELICLIB) -lrelicwrapper -lrelic_s -lgmp -lpthread -o $@
pairing_integrationtest.o: pairing_integrationtest.cpp dp5combregclient.h dp5regserver.h dp5params.h dp5metadata.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR)/include -I$(RELICWRAPINC) -I$(RELICINC) -c pairing_integrationtest.cpp
pairing_integrationtest: pairing_integrationtest.o dp5combregclient.o dp5regserver.o dp5params.o dp5metadata.o  curve25519-donna.o gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDLIBS) -L$(RELICWRAPLIB) -L$(RELICLIB) -lrelicwrapper -lrelic_s -lgmp -lpthread -o $@

dp5lookupclient_unittest.o: dp5lookupclient_unittest.cpp dp5lookupclient.h dp5params.h dp5metadata.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR)/include -c dp5lookupclient_unittest.cpp
dp5lookupclient_unittest: dp5lookupclient_unittest.o dp5lookupclient.o dp5params.o dp5metadata.o curve25519-donna.o gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDLIBS) -L$(PERCYLIB) -lpercyclient -lntl -lgmp -lpthread -o $@
dp5metadata_unittest.o: dp5metadata_unittest.cpp dp5metadata.h dp5params.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -Wno-error -I$(GTEST_DIR)/include -c dp5metadata_unittest.cpp
dp5metadata_unittest: dp5metadata_unittest.o dp5params.o dp5metadata.o curve25519-donna.o gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDLIBS) -lpthread -o $@

bytearray_unittest.o: bytearray_unittest.cpp dp5util.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR)/include -c bytearray_unittest.cpp
bytearray_unittest: bytearray_unittest.o gtest_main.a
	$(CXX) $(CXXFLAGS) $^ $(LDLIBS) -lpthread -o $@



clean:
	rm -f *.o
	rm -f dp5.so
	rm -rf build

pairing.o: pairing.cpp
	g++ $(CXXFLAGS) -I../relic/include -c $< -o $@

pairing: pairing.o
	g++ -L../relic/lib -o $@ $< -lrelic
