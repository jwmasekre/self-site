+++
title = "come ctf with me #1 - kringlecon 2019 - pt 2"
date = "2019-12-21"
author = "josh masek"
cover = "img/cranpi.png"
tags = ["ctf", "kringlecon"]
keywords = ["", ""]
description = "the continuation of my work on the holiday hack challenge of 2019: kringlecon 2: turtle doves"
showFullContent = false
+++

Mongo Pilfer - CranberryPi
------

After the last CranPi, I took a week break from the ctf to focus on work, but with the arrival of the weekend and completion of some overdue errands, I was ready to go. To get into the swing of things, I decided to start cleaning up the other CranberryPis I dutifully noted before, starting with Holly Evergreen's in the NetWars Continuous room (where I made a cameo!).

This one is a MongoDB that has some sort of flag for us to find. Typing `mongo` fails to connect, but gives us a hint that it might not be listening on the default port. If we run `netstat -l` we see that localhost is listening on 12121, and specifically that it's our mongo instance. We type `mongo --port 12121` and we're in!

The first thing we'll want to do is enumerate the collections in this DB. If we send `db.getCollectionNames().length`, we can see that there's a single collection, and `db.getCollectionNames()` returns "redherring". Not exactly encouraging, and though I'm too curious to not dig deeper, if we run `tojsononeline(db.redherring.find()[0]), we get "This is not the database you're looking for.", as if to quell our curiousity.

Lets start over then. MongoDB supports multiple databases, so maybe we can find a different one. `show dbs` gives us 4 databases, and `db` tells us we're using the test db. "admin" is the most interesting right off the bat, but that just has the system version info. "local" has a bunch of startup logs, which seem like a lot to dig through, so first we'll start looking more at "elfu" using `use elfu` to switch dbs.

`db.getCollectionNames()` yields us several fish-related collections, as well as some more interesting collections, such as "metadata", "solution", and "system.js". Let's look at the obvious one first. `tojsononeline(db.solution.find()[0])` gives us a command to run, and so we run `db.loadServerScripts();displaySolution();`, which shows us an animated ASCII tree, and we win!

Smart Braces - CranberryPi
------

That was a fun little exercise, but not crazy challenging, so lets move onto a new one. The student union has another, so we'll knock it out. Looks like our boy Kent here got social engineered, and we need to clean up his firewall to prevent the unauthorized access that led to the attack. I afk'd for a bit to chat with someone, and then Kent started complaining about taking too long, so I backed out. Good to know there's a time limit

I backed out, grabbed another beer, and jumped back in. The `IOTteethBraces.md` file gives us very straightforward instructions for configuring iptables:

>1. Set the default policies to DROP for the INPUT, FORWARD, and OUTPUT chains.
>2. Create a rule to ACCEPT all connections that are ESTABLISHED,RELATED on the INPUT and the OUTPUT chains.
>3. Create a rule to ACCEPT only remote source IP address 172.19.0.225 to access the local SSH server (on port 22).
>4. Create a rule to ACCEPT any source IP to the local TCP services on ports 21 and 80.
>5. Create a rule to ACCEPT all OUTPUT traffic with a destination TCP port of 80.
>6. Create a rule applied to the INPUT chain to ACCEPT all traffic from the lo interface.

Since we have a time limit, lets build our rules outside of the prompt.

```bash
1.
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP
2.
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
3.
sudo iptables -A INPUT -p tcp --dport 22 -s 172.19.0.225 -j ACCEPT
4.
sudo iptables -A INPUT -p tcp --dport 21 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
5.
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
6.
sudo iptables -A INPUT -i lo -j ACCEPT
```

This looks like it should do it. Let's give it a shot... and it works!

Graylog - CranberryPi
------

Last CranberryPi I can find is in the Dorms, and this one is using graylog to fill out an incident reponse report. Username and password are `elfustudent`, so lets just jump in. Looks like there's 8692 messages to sort through, but lucky for me my first ctf-like experience was working with graylog, so this shouldn't be too bad.

The report starts with asking what the first file Minty downloaded was. `UserAccount:minty` will show us all the events tied to Minty (THIS IS CASE SENSITIVE-- I HAVE SOME ~~OPINIONS~~ ABOUT THIS). It's also important to note that everytime you run a search, it sorts by newest first, so you have to click on the timestamp to go old-to-new. I added a `AND NOT ProcessImage:C*firefox` to clear out all the firefox logs, and found `C:\Users\minty\Downloads\cookie_recipe.exe`. This is the correct answer, though the sheet recommends using sysmon's file creation events (2) that also have a process name of firefox. This makes more sense to me, but it's just not the way my brain thought to do this one.

Now we're looking for the IP and Port that the attacker connected to. Using the same filter we currently have, if we turn on the DestinationIp and DestinationPort we can see the next log after our cookie_recipe.exe is connecting to `192.168.247.175:4444`, which is our answer. We can see some further evidence by seing the ProcessImage is the path of our malicious executable.

Now we're looking at commands the attacker runs in their shell. The CommandLine field will tell us these, and the next log is `C:\Windows\system32\cmd.exe /c "whoami"`, which means `whoami` is our next answer.

Next, we have a service being leveraged to escalate, and if we look at all the CommandLine fields for the next several logs, we can see the commands to list services being executed. If we open that log, there's an option to find the logs that surround this one by 5 minutes each way; this will clear our filter but give us some of the events going on that are related but were filtered out-- like having a UserAccount of minty. Unfortunately, in this case our attacker isn't that fast. I switched to a simple filter of just `source:elfu-res-wks1`, jumped to timestamp 2019-11-19 05:24~ where we first seem cookie_recipe.exe, and just skim through the logs until we see a CommandLine that launches a service with a parent image of cookie_recipe.exe (which we could have filtered for, but I wasn't positive it'd have that parent process, so I opted for more noise but less likely to filter out my target log). Specifically, the user launches `webexservice`, which I belive Ed Skoudis talked about at WWHF 2018 during his keynote.

Now, we need to find the binary used to dump credentials. There are a bunch of references to a cookie_recipe2.exe, but we can see a log (with a parent of our cookie_recipe2.exe) of an `invoke-webrequest` grabbing mimikatz and saving it as `c:\cookie.exe`. Again, we could be implementing filters, and if I was more confident in this, I'd be just doing that, but my success in graylog is usually being able to visually filter out logs, rather than create the filters myself.

Our next task is to identify the account used to pivot to a different workstation. This one is pretty easy, we just have to look for successful logon attempts that aren't with minty's account, and we find one by account `alabaster`.

Next is to identify the time the attacker RDP'd into a different workstation. I thought this would be easy to accomplish; `SourcePort:3389 OR DestinationPort:3389` seems like the obvious solution, but this isn't it. We actually need to look at the LogonType, which is 10 for RDP. There are 4 entries when we use `LogonType:10`, and only one is a successful logon, at `06:04:28`.

Now we need to enumerate another pivot, this time from the RDP'd machine to another one, and we need the LogonType. The question gives us a hint; if we check that `_exists_:LogonType AND _exists_:SourceHostName AND _exists_:DestinationHostname`, then we know that the logs that are returned have all the info we need. Further, we can change the time to absolute, and start with the RDP session's time to further reduce it down to 13 logs. We also already know that the attacker RDP'd into ELFU-RES-WKS2, so we can further reduce it that way. We end up with `elfu-res-wks2,elfu-res-wks3,3`, where the LogonType 3 indicates a network logon.

Almost done, we just need to grab the file that was exfil'd. I actually spotted the file while I was exploring earlier, but we can do a quick `CommandLine:C*secret*` to find any commands executed that have the word "secret" in them, and we have one being moved from `:\Users\alabaster\Desktop\super_secret_elfu_research.pdf`

Lastly, we need the IP it was sent to. This happens to be the next log, which has a destination of `104.22.3.84`, which is pastebin.com, and we're done with the report!

Conclusion
------

With that, I concluded my journey into Kringlecon 2019. I began a new job, and have been having a lot of fun learning a brand new field (to me) in infosec, and may post about it here. I have some Powershell planned for future posts, and a NetWars coming up in April that I may document. I had a lot of fun with this one, but I think the ML portion just felt like too much of a time-sink for me to learn it and get it running. Can't wait to see what Ed and his team come up with for next year's 'con!