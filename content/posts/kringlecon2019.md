+++
title = "come ctf with me #1 - kringlecon 2019 - pt 1"
date = "2019-12-12"
author = "josh masek"
cover = "img/cranpi.png"
tags = ["ctf", "kringlecon"]
keywords = ["", ""]
description = "my work on the holiday hack challenge of 2019: kringlecon 2: turtle doves"
showFullContent = false
+++

Kringlecon 2: Turtle Doves!
======

I'm starting Kringlecon a day late this year, but I'm hoping to be able to at least get as far as I got last year. This time, I plan on documenting my findings, and I'll be updating this as I go. My plan is for this to be one big post, almost in a journal/gamefaqs style.

Escape Ed - CranberryPi
------

This one is easy, but I did have to google since i'm unfamiliar with ed. You're trapped in a text editor (ed), and have to exit it. I'm fairly familiar with vi, so I tried `:q`, which failed. After finding the man page for ed with google, I discovered that I was almost correct-- the command to quit is just `q`.

Bushy Evergreen, the elf that we just helped, gives us a hint about looking into DeepBlueCLI, so we'll have to keep that in mind. Objective 3 is now open, though I'd like to start from the beginning, so I'm going to look around for another CranberryPi problem.

Talk to Santa in the Quad - Objective 0
------

Leaving the train station gives you this objective, and a quick chat with santa hands you objectives 1, 2, 4, and 5 (and completes 0). I'm off to find more CranberryPis though, so those will have to wait.

To the left, I found a lobby (called Hermey Hall) with a few different rooms: Labratory, Netwars, Speaker Unpreparedness, and the 7 tracks for this year. I'll have to check them out, but first I'm itching for a problem to solve. I'll continue my left-to-right routing.

Xmas Cheer Laser - (not)CranberryPi
------

Oh man, I found a powershell problem. I'm immediately greeted with a "Do not use endless loops" warning, reminicent of the Netwars 2 posh chapter. Noted. There's a calling card left at `/home/callingcard.txt`, so I `get-content /home/callingcard.txt` and give it a read. It references `history` so we'll give that a look. In bash, the command for showing the history is just `history`, and powershell has a verb-noun version, `get-history`, so lets run that.

Looks like the user wrote `get-service` as an html, a csv, and then revised the csv to only display the columns that they wanted. Then, an `invoke-webrequest` was done to set the angle to 65.5, and open the Application event log. The last one is super weird though, and extends past the end of the line, so lets look at that one with `(get-history -id 9).commandline`, which lets us look at this with wrapping.

It references variables and `get-childitem` indirectly, so we'll store that info for later. First, I'd like to have a go at `(invoke-webrequest -uri http://localhost:1225/).rawcontent`, which is in the motd banner when you log in. It lists a bunch of examples, so i'm gonna try the angle command we found in the history (`(invoke-webrequest http://127.0.0.1:1225/api/angle?val=65.5).rawcontent`). `(invoke-webrequest http://127.0.0.1:1225/api/output).rawcontent` tells me it's not correct, so I try `/api/angle?val=45.1` like in the example, and it's still not correct (though closer). I have a feeling that's where the variables and child-items come into play, so lets start looking.

I got dropped and logged back in, and apparently I got a powershell hint with a link to SANS' powershell cheatsheet. Won't take that out until I'm stumped. I had the idea to brute-force this, and see if I can get the right value without digging in, but that's no fun. I noticed that there's a directory in `/home/elf/` called `depths` so I ran a `get-childitem -recurse | where-object {$_.mode -like "d*"} | where-object {$_.name -like "api"}`, to see if it could be that easy. No luck. Dropping the second `where-object` shows that this is mostly auto-generated garbage. no luck there. Same with a `notlike` instead. Just a bunch of files that match the regex `^.{8}\.txt$` (8 of any character followed by .txt). Piped the `-notlike` version of my command to a `$_.name -notmatch` of the regex above, and only the motd files showed up. Tells me it's all garbage. Time to start digging into the variables.

`get-childitem env:` dumps all the environment variables, and one is created called `riddle`. `(get-childitem env:riddle).value` references `/etc`, `sort`, and `lastwritetime`. Not so much a riddle as instructions for finding the answer, but lets go for it. I `cd /etc/` and then run `get-childitem -recurse | sort-object -property lastwritetime`. There's an archive file under `/etc/apt`.

`get-content` on this file is a mistake. It's a binary file, so a look at the first line should give us a magic number. Luckily for us, I can scroll up to the top and the magic number is acutally human readable! `PK..` is the zip format ([this list](https://en.wikipedia.org/wiki/List_of_file_signatures) is very useful when you dont' have `file`), and so we use `expand-archive` on the file to expand it. `get-childitem -recurse` after the fact shows that `trusted.gpg.d` and `apt.conf.d` have files in them, and there's a `sources.list` in the root of the archive. `sources.list` doesn't seem useful. There are no hidden files (`get-childitem -recurse -hidden`), and the config files in `apt.conf.d` don't seem to have anything, except maybe an archive directory.

Not totally sure where to go from here, so I'll set it aside and start working on something else.

Splunk - Objective 6
------

We're given a username and password for `splunk.elfu.org/`: `elf` and `elfsocks`. At least for the time being, we have a bunch of chatlogs to comb through so let's get started.

Kent has nothing to say to us at first, so we talk to Alice. She introduces the challenge (find the embeded message for Kent in the attack).

There's some training questions to help guide us, so we can answer those.

The #ELFU SOC channel has the answer to the first question, `sweetums`. This updates the chats (specifically, the one with Alice). This gives us a sample of a search in splunk, which we can modify to do our own searches. The chat also reminds us that since this is a training exercise, there isn't a whole lot of noise, and suggests that the high-value target of the organization is Santa. We search `index=main santa` and get 11 events.

Looks like a lot of base64 encoded powershell, but splunk helpfully displays the commands that are run in the code. Looks like Santa sent the professor a draft of his list. That might be valuable. Changing our search from `santa` to `get-item` yields an entry for that command being run on the file, which confirms that it's the one that was grabbed, and the training center tab confirms that `C:\Users\cbanas\Documents\Naughty_and_Nice_2019_draft.txt` is the correct answer. The updated chat also confirms that `santa` was the right choice for a search term.

Now, we need an FQDN for the C2 server. Alice helpfully suggests that we should use sysmon as our source, and gives a search term to find all sysmon powershell network connections. After searching this, on the left we have a single entry for the `destinationhostname` interesting field, `144.202.46.214.vultr.com`, and that's the correct answer.

For the fourth question, we're looking for the document that is launching the code. Alice suggests finding stuff that happens within 5 seconds of powershell events to find interesting process IDs to investigate. We get 40 events within 5 seconds of the first powershell log. Interesting Fields tells us there's 4 process IDs, `6268`, `5864`, `0x16e8`, and `0x2248`. Those last two are hex, so if we convert them to decimal, we get `5864` and `8776`, respectively. `5864` showing up in multiple sources is interesting. lets dig in.

Using the hex version, we find a single event that occurs at 5:18:35, so if we look at Windows Process Execution events that happen before that time, we should be able to see what launches it. Alice provides us with the syntax for that search, and at 5:18:15 Word opens a macro'd document, `19th Century Holiday Cheer Assignment.docm`, and this is our file.

Now, we're looking at emails, using stoQ as a source. Alice gives us a sample search to let us know how the formatting looks. We simply take that format and use the `results{}.workers.smtp.subject` field to search for the appropriate subject: `search "results{}.workers.smtp.subject"="Holiday Cheer Assignment Submission"` We get our answer of `21` on the statistics tab.

This next one is a cakewalk, Alice tells us that the attacker used the MITRE ATT&CK technique 1193, which is Spearphishing. We can see from the previous filter we used that Bradly sent a password for his malicious doc, which was `123456789`. There's likely a way to actually search that using stoQ, as implied by the chat after answering, but I'm not going to look into it *yet*.

The last question is dead-easy, we already have the stoQ entry up from the last two questions. `bradly.buttercups@eifu.org>` sent the email.

Finally, the challenge question. Alice provides us with a stoQ event, so we'll start there. She also provides us with a means to pull filenames/paths, and hints at how word documents are just xml files at their core. If we run that pipeline, we get 19 entries, one of which is named `core.xml` at `/home/ubuntu/archive/f/f/1/e/a/ff1ea6f13be3faabd0da728f514deb7fe3577cc4/`. That file, when opened, has a description element: `Kent you are so unfair. And we were going to make you the king of the Winter Carnival`, which concludes objective 6.

Find the Turtle Doves - Objective 1
------

Since we're doing objectives now, might as well go back to the first one and do that. Time to go exploring!

I took a look at the netwars room, and I'm actually a part of that one! At the time of writing, I'm number 24 on the leaderboards that scroll down. There's also a CranberryPi in here with Holly Evergreen, but we'll come back to that one.

In the main lobby area, there's another CranberryPi by SugarPlum Mary. Noted. Alabaster Snowball also has one in the Speaker Unpreparedness Room. We'll get to these soon enough.

Working my way clockwise, there's another room, which looks like a vender area? Anyways, there's two turtledoves hanging out by the fire. Clicking on them gets us our objective. Santa also said to copmlete 2-5, so let's get to work.

Unredact Threatening Document - Objective 2
------

This objective doesn't have a link, but it says the letter is in the quad, so back we go. I took a look around and had no idea where this thing was, but I was impatient to get on with it, so I just opened up the developer tools (`F12`) and searched for "letter" in the elements tab, and opened it there. Feels like cheating, but in the good, hacker kind of way.

The PDF is simply a poorly-redacted document, and highlighting the text shows that the redactions are only covering up the text, and haven't eliminated it. I copy-pasted it into notepad, and found the answer I was looking for: `DEMAND`

Windows Log Analysis: Evaluate Attack Outcome - Objective 3
------

This one has a link, so away we go. We download the event log, and open it in event viewer. We're looking for a user account that's been compromised using password spray, so we're looking for successful logons, which are event ID 4624. We can create a filter to only show successful logons. In here, we see a few successful logons from pminstix, DC1$, and supatree, and DC1$ isn't a user account, so we don't have to worry about that. Now, we look at the date and time stamps. It looks like the password spray happens between 6:21:44 and 6:22:51. supatree was the only user to successfully log in in this time frame, so this is likely the popped account.

Linux Path - CranberryPi
------

I'd like to get started on objective 4, but I don't exactly know enough about sysmon to dig in, so I'm heeding the advice of the objective: talk to SugarPlum Mary. She has a CranberryPi for me to resolve, so I'll do that for her. Her issue is that she can't use `ls`. Running `ls` returns a StarWars quote, and running `which ls` returns `/usr/local/bin/ls`, which isn't the normal directory for `ls`. To be lazy, I ran `locate ls` and discovered that there's a copy of `ls` in `/bin/ls`, where it should be, and running the command `/bin/ls ~` gives us the flag.

Windows Log Analysis: Determine Attacker Technique - Objective 4
------

SugarPlum Mary tells us about EQL, which was the missing piece for me. A quick `pip3 isntall eql` grabs it and I'm ready to go. I move to the directory where I have extracted the sysmon-data.json, and run `eql --file sysmon-data.json`. This gives us a cli using eql's language. The link SugarPlum Mary gives us has a sample of dumping password hashes using ntdsutil, and gives us guidance on how to identify that behavior. In this case, I run `search command_line='*ifm*'` which returns a single line, confirming that this was used, and `ntdsutil` is our answer.

Network Log Analysis: Determine Compromised System - Objective 5
------

Looks like this one ships with an ActiveCountermeasures site for viewing the logs, so we'll probably have to get familiar with RITA. We're looking for the infected machine's IP, so we open up the index and take a look at the Beacons tab. Looks like `192.168.134.130` has RITA absolutely convinced it's beaconing (score of .998), and, sure enough, that's our infected host.

Frosty Keypad - (not)CranberryPi
------

Santa wants us to complete 6 and 7, and this also has unlocked all the way to 12. We already completed 6, so 7 is next. I have no idea where to go from here, so I guess I'll explore. Back to the vendor room, I spot Kent Tinseltooth with a CranberryPi (noted), and Shinny Upatree outside a Sleigh Shop. Nothing new there, so I head out and continue on, clockwise around the quad. To the east, we have Tangle Coalbox in front of a Frosty Keypad, with a quick puzzle. One key is repeated, it's a prime number, we can tell which numbers are used. If we click, we get 1, 3, and 7. The obvious answer would be 1337, but that's not a prime number. Let's work our way up from the bottom.

Our number's digits can't add up to a multiple of 3. This means 1137 and 1377 are out, so 3 has to be the number that's duplicated. If we reverse 1337, we get a prime number, and `7331` is the correct key.

Holiday Hack Trail - CranberryPi
------

The keypad got us acces to the east area, where Pepper Minstix is sitting next to a CranberryPi. Minty Candycane is also sitting next to a CranberryPi, and if we go to the open door, we see someone rush into a door. Follow them, and there's a lock inside of a closet. Click on it, and a keyring is clickable in the top left. Clicking that keyring opens an "open" prompt, so I assume we will need to upload a key to that keyring later, so let's go back and talk to Minty like the objective 7 prompt suggests.

Minty's CranberryPi is a Oregon Trail knock-off, and they hint that maybe there's some webapp pentesting to try. Clicking Normal and Hard doesn't give us anything useful, but Easy gives us
```url
hhc://trail.hhc/store/?difficulty=0&distance=0&money=20000&pace=0&curmonth=7&curday=1&reindeer=2&runners=2&ammo=100&meds=20&food=400&name0=Emma&health0=100&cond0=0&causeofdeath0=&deathday0=0&deathmonth0=0&name1=John&health1=100&cond1=0&causeofdeath1=&deathday1=0&deathmonth1=0&name2=Vlad&health2=100&cond2=0&causeofdeath2=&deathday2=0&deathmonth2=0&name3=Ruth&health3=100&cond3=0&causeofdeath3=&deathday3=0&deathmonth3=0
```
which we can work with. To test, I changed the `money` from 5000 to 20000, which worked. 9999999 did not, so this will be a bit of trial and error, but it looks like the real key is the `distance` value. If we click `buy`, the distance remaining counter says 8000. If we change the value of `distance` to 8000, that should give us our win condition. We change it, hit go, and are rewarded with a win screen.

Get Access To The Steam Tunnels - Objective 7
------

Minty suggests that we can use the item in her room to copy keys, and that we can find a key in the network tab of the dev tools. Playing with the key machine, it funtionally creates a 6 character numeric password in the form of a png, and we need to find what that is. We'll leave the room, open the dev tools/network tab, and go back in.

That wasn't it, but that's okay, I'll just continue to walk around until I see something.

As usual, I over thought it. The elf that runs into the closet (apparently named Krampus) has a key on his person, in the image file we can retrieve from the network tab. We can use this image to figure out the code, make our own key, and unlock it.

I used PDN to do my comparisons. Guessed at 233821 based on eyeballing, and overlaid at 50% opacity the key from the cutter on a hue-shifted magic-wanded copy of the key on Krampus. Then, I revised to 122621, which was really close, but the 6 and last 1 seem to be too large. Sure enough, `122520` ends up being the right combo, and we can move on. We go into the tunnels for Krampus to tell us his last name is Hollyfeld, and we can answer the question.

Nyanshell - CranberryPi
------

Krampus now wants us to bypass a captcha, or rather, a CAPTEHA, for the Frido Sleigh contest. Basically, it prevents you from actually being to click the appropriate items before the time runs out, so we may have to script something. He has the api (a python script) and a dump of all the images, so this may be easy to do. However, I'd like to utilize all my resources, so we'll go talk to Alabster Snowball in the Speaker Unpreparedness room to get some hints.

Alabaster suggests checking `sudo -l`, which is the list of what the current user can sudo. Looks like we can run `/usr/bin/chattr` as root with no password, so lets dig in. 

There's a script at `/entrypoint.sh`, which looks like uses `chmod` and `chattr` against `/bin/nsh`. `/bin/nsh` is the Nyanshell, so we're making progress. If we `chattr -i /bin/nsh` (and then `sudo !!` because I forgot to sudo) we can now make changes to the file! I beat my head against this way longer than I should, but eventually I realized (with some helpful nudging) that we can just copy `/bin/bash` to `/bin/nsh` and switch users, and we win!

To be continued...