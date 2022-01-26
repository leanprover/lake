set -ex

(cd bar; ${LAKE:-../../../build/bin/lake} build)
