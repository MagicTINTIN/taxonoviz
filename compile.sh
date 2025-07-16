#!/usr/bin/env bash
projectName="taxonoviz"

mkdir build 2>/dev/null
mkdir debug 2>/dev/null

makearg=""
cmakearg=""
test=0
both=0
folder="build"
for arg in "$@"; do
    if [ "$arg" = "--both" ]; then
        both=1
    elif [ "$arg" = "--release" ]; then
        cmakearg+=" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=\"-O3\" "
    elif [ "$arg" = "--debug" ]; then
        cmakearg+=" -DCMAKE_BUILD_TYPE=Debug "
        folder="debug"
    elif [ "$arg" = "--fastcomile" ]; then
        makearg+=" -j8 "
    elif [ "$arg" = "--test" ]; then
        test=1
    elif [ "$arg" = "--reset" ]; then
        rm -rf build/*
        rm -rf debug/*
    fi
done

if [[ $both == 1 ]]; then
    if [[ $test == 0 ]]; then
        ./compile.sh --debug --fastcomile && ./compile.sh --release --fastcomile && exit
    else
        ./compile.sh --debug --fastcomile && ./compile.sh --release --fastcomile --test && exit
    fi
    exit
fi

echo "================ PREPARING ================"

cd $folder/
cmake $cmakearg ..
if [[ $? != 0 ]]; then
    err=$?
    echo -ne "$(tput setaf 9)"
    echo "Compilation of $projectName went wrong.$(tput sgr0)"
    cd ../
    exit $err
fi

echo "================ COMPILING ================"

make $makearg
if [[ $? != 0 ]]; then
    err=$?
    echo -ne "$(tput setaf 9)"
    echo "Compilation of $projectName went wrong.$(tput sgr0)"
    cd ../
    exit $err
# elif [[ $? == 0 ]]; then
fi

cd ../
echo "$(tput setaf 2)$(tput bold)Compilation of $projectName finished.$(tput sgr0)"
if [[ $test == 0 ]]; then
    echo "Execute $projectName compiler with $(tput bold)$folder/$projectName$(tput sgr0)"
    exit
fi
echo -ne "$(tput sgr0)"

echo "================== TESTS =================="
# ./test.sh 32
if [[ $? != 0 ]]; then
    err=$?
    echo -ne "\n$(tput setaf 9)$(tput bold)"
    echo "Tests are not passing.$(tput sgr0)"
    cd ../
    exit 1
else
    echo -ne "\n$(tput setaf 2)$(tput bold)All tests are passing.$(tput sgr0)\n"
fi