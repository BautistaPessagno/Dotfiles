#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10
#/* big-window.rasi */
#{
#font: "JetBrainsMono NF 16";
#width: 50%;              #ancho de la ventana
#element-height: 2.0em;   #alto de cada línea
#padding: 1.5em;          #relleno interior
#}
#window {
#border-radius: 8px
#}


dir="$HOME/.config/rofi/launchers/type-7"
theme='style-1'


## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
