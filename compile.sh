# Arm-Specific Cross-Compilation Instructions

sudo dpkg --add-architecture arm64
sudo apt-get update || echo "continuing after 'apt-get update'"
sudo apt-get install -y gcc-${COMPILER_VERSION}-aarch64-linux-gnu g++-${COMPILER_VERSION}-aarch64-linux-gnu python3-venv
sudo apt-get install -y libssl-dev:arm64 libcurl4-openssl-dev:arm64 liblzma-dev:arm64
# MongoDB Instructions
# mkdir ${mongodb_version}
# tar -zxvf mongo-${mongodb_version}.tar.gz -C ${mongodb_version}
# git clone -b ${mongodb_version} git@github.com:mongodb/mongo.git ${mongodb_version}
# cd ${mongodb_version}
sudo apt-get install -y gcc python3-dev git lld
python3 -m venv python3-venv
source python3-venv/bin/activate
# python -m pip install "pip==21.0.1"
python -m pip install pip --upgrade
python -m pip install -r etc/pip/compile-requirements.txt
python -m pip install keyring jsonschema memory_profiler puremagic networkx cxxfilt

# The important part for cross-compilation is to specify the arm toolchain for the following three tools:
#  AR: Archive tool
#  CC: C compiler
# CXX: C++ compiler


# Should take less than a minute.
\time --verbose python3 buildscripts/scons.py -j$(($(grep -c processor /proc/cpuinfo)-1)) AR=/usr/bin/aarch64-linux-gnu-ar CC=/usr/bin/aarch64-linux-gnu-gcc-${COMPILER_VERSION} CXX=/usr/bin/aarch64-linux-gnu-g++-${COMPILER_VERSION} CCFLAGS="${CC_FLAGS}" --dbg=off --opt=on --link-model=static --disable-warnings-as-errors --ninja generate-ninja NINJA_PREFIX=aarch64_gcc_s VARIANT_DIR=aarch64_gcc_s DESTDIR=aarch64_gcc_s

# Will take several hours and depends heavily on your machine's capabilities. Almost 4 hours on my machine.
\time --verbose ninja -f aarch64_gcc_s.ninja -j$(($(grep -c processor /proc/cpuinfo)-1)) install-devcore # For MongoDB 6.x+

# Minimize size of executables for embedded use by removing symbols
pushd aarch64_gcc_s/bin
mv mongo mongo.debug
mv mongod mongod.debug
mv mongos mongos.debug
aarch64-linux-gnu-strip mongo.debug -o mongo
aarch64-linux-gnu-strip mongod.debug -o mongod
aarch64-linux-gnu-strip mongos.debug -o mongos

# Generate release (on Mac OS)
# tar --gname root --uname root -czvf mongodb.ce.${CHIP_NAME}.${MONGO_VERSION}.tar.gz LICENSE-Community.txt README.md mongo{d,,s}
# Generate release (on Linux)
tar --group root --owner root -czvf mongodb.ce.${CHIP_NAME}.r${MONGO_VERSION}.tar.gz LICENSE-Community.txt README.md mongo{d,,s}