#!/bin/bash
cd /c/development/VSCode/vcodegen/bin

function nspanel(){
    bash /c/development/VSCode/vcodegen/bin/esp.sh $*
}

function switchman(){
    bash /c/development/VSCode/vcodegen/bin/esp.sh $*
}

function allNSPanels() {
    rm -f .runAll.sh
    ls ../devices/nspanel/*.cfg | while read cfg
    do
        echo nspanel $* `basename $cfg | sed 's/.cfg//g'` >> .runAll.sh
    done
    . .runAll.sh
    rm -f .runAll.sh
}

function allSwitchman() {
    ls ../devices/switchman/*.cfg | while read cfg
    do
        switchman $* `basename $cfg | sed 's/.cfg//g'`
    done
}

allNSPanels -e
allSwitchman -e
