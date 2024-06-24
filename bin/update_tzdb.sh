#!/usr/bin/bash

git_path=/c/app/git/bin
fpc_path=/c/app/fpc/bin/i386-win32

export PATH=${fpc_path}:${git_path}:${PATH}

cd tz-db

git reset --hard

./update-compile.sh

read -p "Press ENTER to exit..."
