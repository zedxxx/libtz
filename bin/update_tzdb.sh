
fpc_path=/c/fpc/bin/i386-win32

export PATH=${fpc_path}:${PATH}

cd tz-db

git reset --hard

./update-compile.sh

