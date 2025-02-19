#/bin/bash

set -e

cd vcs

if [ ! -f simulation.log ] || grep -iq 'error\|warning' simulation.log; then
    echo -e "\033[0;31mSim Failed \033[0m"
    exit 1
else
    echo -e "\033[0;32mSim Passed \033[0m"
    exit 0
fi