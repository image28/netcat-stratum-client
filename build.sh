ROOT=`pwd`
git submodule init
git submodule update
cd cuckoo/src/cuckatoo
make mean31x8
cp ./mean31x8 "$ROOT"
cd "$ROOT"
