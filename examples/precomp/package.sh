set -ex

cd foo
${LAKE:-../../../build/bin/lake} build
cd ..
