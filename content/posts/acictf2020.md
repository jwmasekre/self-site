+++
title = "come ctf with me #2 - acictf - pt 1"
date = "2020-04-24"
author = "josh masek"
cover = "img/aacs-logo.png"
tags = ["ctf", "acictf"]
keywords = ["", ""]
description = "my work on 2020's acictf"
showFullContent = false
+++

Army Cyber Institute Capture the Flag
======

On the ball this year about starting right away, so let's get right in

Skip the Tutorial - 0
------

no thanks

First Rule - 1
------

So this one is just getting us familiar with what a flag looks like; in this case, `ACI{this_is_a_flag}`

Distant Socializing - 2
------

This one's easy, just join an appropriate group (NCO, in my case), and you get a flag: `ACI{welcome_to_the_club}`

Nudge, Nudge - 2
------

Naturally, this is also easy, just use the hint button. Hints are free for this CTF, since the point is to encourage learning. `ACI{are_you_flagging_already}`

Download Me - 3
------

This one has slight nuance to it; you download the file, and it has no file extension. Luckily, if we open it in a text editor (like VSCode) we can see that it's a plain text file. `ACI{g3tt!ng_m0r3_R4nd0M_d008339c}`

Slacking Off - 3
------

All this one requires is joining the Slack and grabbing the flag out of #announcements. `ACI{dont_steal_our_LCDs}`

InterNet Cats - 4
------

Another quick one, there's a netcat listener on port 55270 at `challenge.acictf.com`, responding to anything that "'sounds' like a cat." I'm running in Windows right now, so I fire up powershell and type `ncat challenge.acictf.com -port 55270`. It responds with a `Hello?` and I reply with `meow`, and it gives me the flag: `ACI{72e708b1414c0aebec94d9f3ca0}`

Out of Site - 5
------

This one is a demo of the flag validation, and how it works both client-side and server-side. We'll want to take a look at the source, and the hints so helpfully tell us that `Ctrl+U` is the keyboard shortcut for viewing the source, where it shows the pattern that it's looking for: `ACI{hidden_in_plain_site_1baa684f}`

Rotate Me - 5
------

The description hints at this being a caeser cipher, so I fire up my favorite data manipulation tool, [CyberChef](https://gchq.github.io/CyberChef/), and drop the data in the file we get into the input. We drop a ROT13, and it looks like `VXD{XmTkOj_ApI_aJm_VgG_IOvSXjTD}`. Right format, but the first three letters are off, so we click the up arrow next to the amount box until it looks like this: `ACI{CrYpTo_FuN_fOr_AlL_NTaXCoYI}`

Socially Distanced Challenges - 5
------

This one's a play off of current world events, comparing social distancing to containerizing. Basically, it's breaking down that the "Socially Distanced" challenges are spun up when you start them, and you can only have one open at a time. They only last 20 minutes, too, so you have to be quick. I'll be utilizing this page to keep notes as I go, so if it takes me more than one time to get it, I'll have a record. It also mentions that the port changes, so if we have scripts/payloads, we'll need to update them. I'll try implementing some modularity to my scripts to make this a non-issue. At the end, we get our flag: `ACI{clean_your_keyboard_too}`

Filing Extension - 10
------

Here we have a .png file that isn't a .png. I remove the file extension and go to my trusty VSCode. Obviously it struggles to open it, but I get exactly what I need: the file begins with `PK`. I go to my [favorite source for magic numbers](https://en.wikipedia.org/wiki/List_of_file_signatures) and discover that this is actually a .zip. Change the file extension again, and we have a flag: `ACI{Something_witty_92adc6d7}`

More Out of Site - 10
------

We have another client-side codebase, but this time in everyone's favorite language, javascript. Another `CTRL+U` gets us the HTML, which links to a `flag_checker.js`. Hidden in the js is our flag, `ACI{client_side_fail_845ce5f8}`.

Bootcamp - 20
------

Up until this one, there were a lot of solves (100+) on the problems, even half an hour into the competition, but this one, at the moment of solving the last one, only had 35, so I'm curious to see what's going on with it. Looks like a copy of a floppy drive image. It's tarball'd and gzip'd so I break it open with 7z. The question hints at all the data being on the first sector of the disk, so my first instinct is to throw something like photorec at it and see if it recovers anything. No dice there.

A google search yields some freeware called Active@ Disk Editor. I'm always wary of installing new software, but I can't find any skankiness at a cursory glance, so I go for it. They're not wrong, it's all right there at the 000 offset, and if I drop the hex into CyberChef, I can see hints of a flag (matching curly brackets with three characters inside). If I start going through encoding types, I find ACI shows up before the curly brakcets. I think I'm in the right vicinity, but not quite on the right path.

Of course, I forgot about the hints. Took a quick break for some coffee and opened them up. I didn't even think of trying to boot it. I create a quick VM in VMWare Workstation and boot to the floppy, and it outputs `ACI{BoOt_MaGiC}`. I really liked that one, I just can't believe I didn't think to freakin' boot to it.

Most Out of Site - 20
------

Another site to try and extract a flag from. Same as before, we check the source, and then the js. At a glance, looks like their using cookies for it (`var secret_flag=get_cookie("most_out_of_site_flag")` looks sus). I go back to the main page, hit `F12`, and head over to the Application tab. There, on the left side (in Chrome) is a Cookies drop-down, under Storage. If we click on the url under Cookies, we see the flag we're looking for, stored as the cookie we identified earlier: `ACI{cookies_fail_too_60f43d39}`

Reverse Engineering 101 - 25
------

Looks like another one that has not a lot of solves (about 25% less), but as this is reverse engineering, I'm going to set it aside. I really want to spend a good amount of time on this, because reverse engineering is something I'm not very familiar with, but for now I want to knock out as many of the questions as I can.

Really Senseless Admins - 35
------

This one has about half the solves of the reverse engineering, but it might be a cakewalk. We have an .enc file and a list of parameters. We don't have the private key to decrypt the file, but the parameters might be enough to decrypt it anyways. It has values for `p`, `q`, and `e`, and a quick google shows that those values relate to RSA. [Stack Exchange](https://security.stackexchange.com/questions/25631/crack-plain-rsa-given-p-q-and-e) has a great answer for htis, tells me everything I need. I found a [site](https://www.cryptool.org/de/cto-highlights/rsa-schritt-fuer-schritt) (in German, but math is universal) that will do the calculations for me, and at the end put the ciphertext into the bottom to get the code. I get a value, `104873340459054924181115292546315913092670481552037142520358525`, which looks like just a big decimal. A quick Decimal to Hex conversion gets me `4143497B5072316D33735F54214D337A5F33306235336463667D`, and a Hex to ASCII gets me `ACI{Pr1m3s_T!M3z_30b53dcf}`

Let me INNNNNN - 40
------

Everybody is definitely slowing down now, this one has half the solves of the previous. This one is a webapp to break, so this is probably gonna be a lot of fun. We have two pages, a `Home` and a `Login`. If we go to `Login`, there's a `Log In` button and a `Resend password` button. Clicking `Resend password` creates a pop-up that says `Email sent to vault.master@cyberstakes.club!` This might be our ticket. If we look at the Network tab of the developer menu (`F12`) and click it again, we see that there's a `POST` sent, with the email in the form data. I right-click the `POST` and `Copy as Powershell`. I paste that into a powershell window, change the email to my personal email, and I get the password emailed to me! I enter it in and receive `ACI{2169760b7e933785}`

All Your Base Are Belong To Us - 50
------

This one gives us some starter code and asks us to connect to `challenge.acictf.com:5248`. If we connect to it with ncat, we see that it gives us a key for reformatting data, will tell us what conversion to do and submit, and keep feeding us until we do it 5 times. I suppose that there will be a time limit to do this; there was a similar problem last ACICTF with directions and parsing. I'll sit on this one as well, I want to come back to it later.

Binary Exploitation 101 - 50
------

This one is exploiting a binary, and they give us the source code. Since we're inputing numbers, my guess is that this is a buffer overflow (or underflow) exploit. If we connect to `challenge.acictf.com:46743`, it asks for two numbers, multiplies them, and returns the value and the number it ends in. If we input random numbers, we find that somewhere between 9 and 10 digits, it breaks, and considers it a negative number. If we just take 2 up exponentially until we get to a 10 digit number, we get `1073741824`, which when input twice, gives us `0`. What this tells us is that we're underflowing to 0 at this value. If we drop it by one (`1073741823`) and multiply them together, we get another negative number, and a bunch of text as the value it ends in. We're on to something here.

Messing around some more, if we go higher, we also get a random number and text (in this case, I tried `1073745000` twice, which yielded `six` because the resulting value underflowed enough to become positive again). We're definitely accessing parts of the code we shouldn't be when we make it negative. If we look at the code, we actually just need to multiply two numbers together whose product is > 2147483648, which is the max of 32 bit. To give ourselves more granularity, I'm switching to `1073741824` and `2`, and incrementing `1073741824` to move up and down by 2.

It looks like if you go up by 2, it cycles through the same 5 responses. Mathematically, we're getting (real, not underflowed) products of `2147483648`, `2147483650`, `2147483652`, 2`147483654`, and `2147483656` (and on and on). We're missing the odd numbers in between, so using a factorization calculator, I can determine which multiples lead to the odd numbers; eventually I get to `5895` and `364289` to get a real value of `2147483655`, which gives me `ACI{c6a489a6cbc23f19a894b6d44c1}`. There was probably a more reverse-engineer-y way to solve that, but discovering that there were only 10 invalid results made it easy.

Lockbox - 50
------

Another reverse engineering, I'll come back to it when I do the other reverse engineering problem.

Not So Meta - 50
------

Looks like we have an image that might have some metadata worth looking into. Dropping the image into CyberChef lets us look at all of the metadata, and it looks like tucked under the Creator Tool entry is an ItsTheFlag entry, and some very obviously base64 encoded text. CyberChef can also take care of this: `ACI{0713be79cac77f58c6dac4947e3}`

Over Time: Paid - 50
------

This one is an encrypted document, each line of which is 128 hex characters long, and a source python script. It also looks like a line is repeated frequently, which is likely white space. Since they use `encrypt_otp` in the source, and we see the same line repeated, that means that they're reusing the key, which means we can find the key. Cyberchef can convert the hex back to utf-8, and then we can XOR it with the known white space to get nearly our answer. Ideally, we want to find every instance of white space and find what the resultant value was for that white space, and use that to `XOR`.

The line above the flag is pure white space, and if we do the `XOR` with that line, we can clearly read the whole document... except that all the letters have switched case, and the numbers are just gone. There's likely a better way to do this, but basically I took the hex values for `aci[ECEF.DA.C..ADEB..F...D...CB]` and subtracted 0x20 from the letters and added 0x20 to the non-characters, and got our flag, `ACI{ecef0da3c02adeb06f983d514cb}`.

No Escape - 60
------

This one looks like a SQLi problem, so we'll dig right into `challenge.acictf.com:47635`. If we use `'` in the username and password box, we get the exact query being run: `SELECT username FROM users WHERE username = ''' AND pwHash = '265fda17a34611b1533d8a281ff680dc5791b0ce0a11c25b35e11c8e75685509'`. This tells us where we can inject our SQL. First, we want to remove the password hash checking, so we add a `--` at the end (to comment it out). Then, we can add `admin'` in front of that, and with the comment at the end it gets us in as admin. The resulting screen says `The "hash" for account 'houdini' is 'Not a hash'.`, so we go back to the login screen with that info. Now, we need to spoof what we send as the password hash, so we input `houdini' AND pwHash = 'Not a hash'--`, which tricks it into thinking that we typed in the "right password", which was actually a hash that is impossible to achieve.

Boot Master - 75
------

Another floppy image. I think my line of thinking originally in `Bootcamp` is the right way to go here. It won't boot to the drive currently, so we'll open it up with the hexdump extension for VSCode. A google search for the standard format of an MBR is that the signature should always be `55 AA`, but this sector has `51 AA`. Right-clicking on the hex allows us to edit it, and we can export the file to binary and boot it, yielding us `ACI{fails2boot}`

DENIED - 75
------

We have another web site to break! In this case, we want `flag.txt` off the server. The hint asks how websites keep private pages off of search engines; they use robots.txt, so we'll attach that to the end of the URL. We get a disallow entry, so let's add that `/maintenance_foo_bar_deadbeef_12345.html`. If we look at the source code of the page, we can see that a different url (`/secret_maintenance_foo_543212345`) supports a `POST` method, with an input of `cmd`. This is all we need to execute commands on the server.

I like using powershell, so that's what we'll do. With powershell, we use `invoke-webrequest` to interact with web pages, so we start with `invoke-webrequest -uri "http://challenge.acictf.com:62914/secret_maintenance_foo_543212345"`. We want it to be a `POST` request, so we add `-Method POST` to it. Finally, we need to submit our commands: `-body @{cmd='ls'}`, so our final input looks like `Invoke-WebRequest -Uri "http://challenge.acictf.com:62914/secret_maintenance_foo_543212345" -Method POST -body @{cmd='ls'}`.

This is great, but it also doesn't show us much, because by default `invoke-webrequest` doesn't show us the full content. We have to pipe it to `select-object -expand content` to see everything. When we submit the new request, we get a list of files, including our `flag.txt`. If we update the command to `@{cmd='cat flag.txt}` it outputs `ACI{dd1cfae8b197bdd737f904e466f}`

Your Cup Overfloweth - 75
------

A buffer overflow problem, but one that'll probably require reverse engineering, so I'll set this one aside too for now.

ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz12345678900987654321

Boot Riddle - 100
------

Another boot disk! We mount it and... nothing happens. The hints suggest using QEMU, so we'll give it a shot. Launching that way (`qemu-system-x86_64 floppy.img`) works well, and tells us our flag is at `0x7DC0`. We need a way to access the memory, and View -> compatmonitor0 takes us there. The command `xp` will give us memory at a specific address, we use `/40b` to get 40 bytes (just to be safe), and we list our address `0x7dc0`, and we get `0x41 0x43 0x49 0x7b 0x52 0x45 0x41 0x4c 0x6d 0x6f 0x64 0x65 0x7d` (and a bunch of `0x00`), which translates to `ACI{REALmode}`

Hacker, Scan Thyself - 100
------

Looks like a port scanner that is one of the timed challenges, and at a glance it looks like one that I can learn a lot from, so I'm gonna set it aside for now.

Serial Killer - 100
------

Setting aside for now.

That's More Than Enough - 100
------

This one appears to be seganography via .jpg.

Conclusion
------
And that's about how far I got, real life is a PITA and I wasn't able to devote more time to this. Hopefully next year I'll be able to, but for now, this one was fun, and I learned a lot.