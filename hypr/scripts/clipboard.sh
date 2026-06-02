#!/bin/bash

cliphist list |
    rofi -theme ~/.config/hypr/rofi/clipboard/clipboard.rasi -dmenu -sync -display-columns 2 |
    cliphist decode |
    wl-copy
