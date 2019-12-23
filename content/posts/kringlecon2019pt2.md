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
iptables -A INPUT -i lo -j ACCEPT
```

This looks like it should do it. Let's give it a shot... and it works!

a - CranberryPi
------

Last CranberryPi I can find is in the Dorms, and this one is using graylog to fill out an incident reponse report. Username and password are `elfustudent`, so lets just jump in. Looks like there's 8692 messages to sort through, but lucky for me my first ctf-like experience was working with graylog, so this shouldn't be too bad.

The report starts with asking what the first file Minty downloaded was. `UserAccount:minty` will show us all the events tied to Minty (THIS IS CASE SENSITIVE-- I HAVE SOME ~~OPINIONS~~ ABOUT THIS). It's also important to note that everytime you run a search, it sorts by newest first, so you have to click on the timestamp to go old-to-new.