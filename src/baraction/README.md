# baraction 

A `spectrwm` window manager `bar_action` script.

And with

```
bar_format              = +N:+I +S <+P> +A %a %b %d %H:%M:%S
```

the script will produce something like 

```
                                        |-----------------------------------this stuff---------------------------------------------|
1:3 [|] <Xfce4-terminal:xfce4-terminal> 66F/Sunny VOL:32h u78B/d76B cpu:94.21 ram:55Gi home:158G root:20G storage:173G backup:7375Mb Wed Mar 16 19:21:20
```

providing the portion outlined above.

Weather is courtesy of https://www.weatherapi.com/.

The `VOL` value is from amixer but is read from a call to another script in this repository `vol`, which provides support not only for reading this value but also for spectrwm key mappings to control the system volume.

The free space display is coded into the script, but the script should probably be driven with some config file instead.
