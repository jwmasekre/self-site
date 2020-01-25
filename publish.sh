#!/bin/sh

#error protection
set -e

printf "\033[0;32mdeploying changes to master\033[0m\n"
git pull
git add --all
git commit -m "$1"
git push

printf "\033[0;32mbuilding site\033[0m\n"
./hugo.exe

printf "\033[0;32mdeploying site to gh-pages\033[0m\n"
cd public
git add --all
git commit -m "$1"
git push

printf "\033[0;32mdone\033[0m\n"