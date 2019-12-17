+++
title = "josh's posh #2 - an admin console for everyone"
date = "2019-12-16"
author = "josh masek"
cover = "img/Powershell_av_colors.ico"
tags = ["posh", "powershell", ".net", "forms", "gui"]
keywords = ["", ""]
description = "building an admin console everyone can use"
showFullContent = false
+++

Today's post is covering one of the first things I made at my previous employer, which I also have a sanitized version [on my github here](https://github.com/jwmasekre/RandomPoshScripts/tree/master/Scripts/admingui). We used smartcards for login, and we had separate cards and accounts for administration. We also couldn't select a separate account through UAC for installers/administrative applications, so the solution was to open command prompt and run `runas /smartcard cmd.exe`, select the admin card, and have a command prompt open as our admin account. From there, we could run any of the various tools we had installed, but this felt too manual to me, so I began investigating automation.

My admin tool launcher went through a couple iterations, starting as just a batch script to launch all of my tools as my admin account, but eventually I discovered [POSHGUI](https://poshgui.com/), which I leveraged to build the base infrastructure for my admin tool.

The `contents.txt` file in my repo describes all of the files that make this work. I built this with easy of deployment in mind, and leveraged Windows' shortcuts to set taskbar icons. The `adminguilauncher.bat` launches `iconlaunch.bat` using `runas /smartcard`. `iconlaunch.bat` links to the `powershell.lnk` shortcut, which links to powershell, but with the `adminguiico2-2.ico` icon set, so it uses that icon on the taskbar. That batch script launches the actual `admingui.ps1` script that builds the form.

The script starts with the functions. I have a function for each button, and the majority are `start-process <command or path to binary> -verb runas`, which launches that command in an administrative context. The only exception is SCCM, which I had testing two different known install locations for the management console instead of checking the registry (something I learned to do much later).

Then we get to the form itself, which uses .Net to build a Windows Form. First, we add `system.Windows.Forms` and `System.drawing`, which we will be using to build the tool. Second, we create the window itself using `$AdminConsole = New-Object Windows.Forms.Form` and design it with `$AdminConsole`'s properties. We can then add more stuff to add to the form. I created an instruction label using `$instructions = New-Object system.Windows.Forms.Label` and set its `.parent` to `$AdminConsole`. The buttons are created using `New-Object Windows.Forms.Buttion` and the locations of everything is set by setting the `location` property of each object equal to `New-Object System.Drawing.Point(\<x>,\<y>).

Once we've created all of our objects, we then have to add them to a collection via `$adminConsole.controls.AddRange(@($firstobject,..$lastobject))` and then start assigning actions to each of the objects. For example, I have a button named `$cmd`, and to assign it the function `run-cmd` I put `$cmd.Add_Click({run-cmd})`. Once we have finished assigning everything, we end it with `[void]$AdminConsole.ShowDialog()` and we have a window filled with buttons that we can use to launch a bunch of tools as admin! If we create a desktop shortcut to the `adminguilauncher.bat` file, anyone can just double-click that link and the process begins. No more memorizing commands or looking up file locations.

I plan on returning to this to improve upon the whole thing; I know I can cut out a ton of redundant lines of code, and I've been playing with the idea of making it significantly more modular than it currently is. I know I can come up with a system of automating the functions and the buttons, and I'll probably upload a 2.0 version and a follow-up post when I finish that.