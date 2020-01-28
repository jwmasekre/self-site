+++
title = "josh's posh #3 - get-status: a jwmasekre cmdlet"
date = "2020-01-27"
author = "josh masek"
cover = "img/Powershell_av_colors.ico"
tags = ["posh", "powershell", "test-connection", "status", "update"]
keywords = ["", ""]
description = "a cmdlet that only informs you of when a status changes, rather than the status every time it tests"
showFullContent = false
+++

Got the idea for this one from a conversation I had with one of our senior network engineers at work. I had been using `ping -t <ip>` for seeing when someone rebooted devices and they came back online. That works fine for one device, but I ended up needing multiple, so I input a couple commands in powershell:

```powershell
$iplist = @()
$iplist += <ip1>
$iplist += <ip2>
$iplist += <ip3>
while ($true) {foreach ($ip in $iplist) {if (test-connection -computername $ip -count 1 -erroraction silentlycontinue){write-host "$ip is up"}}}
```

which creates an array, adds the three IP addresses I wanted to test, and then alternates between `test-connection` on them, which is essentially a ping, but writes "\<ip\> is up" instead of the output of test-connection. This was fantastic, did exactly what I wanted, and was A *MASSIVE* BLAST OF ICMP. And since I had stepped away from my computer after starting the loop, I have no idea how long it had been sending ICMP echo requests and receiving echo replies at the speed of computer. Completely cleared the buffer, at least.

So I reevaluated what I *actually* wanted: I wasn't looking for a constant, continual ping, I just needed to know whether it was up or down. And my previous issue of walking away introduced another nugget of info I was missing: *when* it goes up or down. And now that I had a much clearer idea of what I'm after, I began to craft an actual script.

First, we need to lay out the basic building blocks of our script. The end product will extend beyond pings, but for now we'll just use test-connection for simplicity's sake. This is an endless loop, so that's easy:

>`while ($true){}`

And we're pinging, but we don't want a bunch of red stuff on our screen:

>`{test-connection -computername <ip> -count 1 -erroraction silently continue}`

But, we also don't want the output to just be the output of test-connection; that isn't what we need to know.

>`{if (<test...>){write-host "host is online" -foregroundcolor green}}`

and we need to output something if it fails:

>`{if...}else{write-host "host is offline" -foregroundcolor magenta}}`

And we want timestamps:

>`{if (<test...>){get-date;write-host "host is online" -foregroundcolor green} else {get-date;write-host "host is offline" -foregroundcolor magenta}}`

However, this is going to blast us with repeating onlines until it goes offline, and then offlines until it goes online. This is where we start getting some boolean flags in. *Note: There may be a way better way to do this, this is just what makes sense to me logically.*

We're gonna create two flags, `$online` and `$offline`. We're also going to set them to `$true` right off the bat. This might sound weird, but it's actually really critical for the way we use the flags. Then, when a `test-connection` is successful, we're gonna set the `$online` flag to `$true`. "But Josh, it's already `$true!`" It sure is, right now, but as the loop continues it may not be, and it's not worth the extra lines of code to check whether or not it's already true. We then insert a new if statement that checks to see if `$offline` is true, in which case *then and only then* will it tell us the "\<ip\> is online" message, after which it sets `$offline` to `$false` because, well, it's not offline. We also do the same but opposite to the `else` statement, and the code looks like this:

```powershell
$online = $true
$offline = $true
while ($true) {
    if (test-connection -ComputerName <ip> -count 1 -ErrorAction SilentlyContinue) {
        $online = $true
        if ($offline -eq $true) {
            Get-Date
            Write-Host "Host is Online" -foregroundcolor Green
            $offline = $false
        }
    }
    else {
        $offline = $true
        if ($online -eq $true) {
            Get-Date
            Write-Host "Host is Offline" -foregroundcolor Magenta
            $online = $false
        }
    }
}
```

Also, we should add a `start-sleep -s 5` or however long you wanna wait between ping attempts just before the last curly bracket, so it isn't bombarding the network with ICMP traffic.

So to clear up the logic here, since it might not make sense to someone out there, let's step through it. At the beginning, we have online as true and offline as true. Then we actually test the connection. Let's say that the connection passes. Online gets set to true, and since offline is also true, we output `get-date` and "\<ip\> is online". Then, we set offline to false, since it's not offline, and we sleep for 5 seconds. On the second pass, we test the connection and it's still up! We set online to true again, since we've confirmed it's online, but since offline is set to false, we don't bother with the date/time or the line about it being online; we already know it's online, we don't need to be told again.

After several more loops, we get to the test connection, and it fails. This takes us to the `else` statement, and here we set offline to true, since now it's offline. And since it was just online, online is still set to true, so we output `get-date` and "\<ip\> is offline", and finish it up with setting online to false, since it's no longer online. And thus it continues until you hit `ctrl + c` or otherwise interrupt the loop.

This works great, though there's some formatting weirdness with `get-date` by itself, but what I really want is to be able to throw stuff at it and have it just process what I add. The target is something like this:

`get-status -scriptblock "invoke-webrequest -uri localhost:5601" -sleeplength 30 -successmsg "kibana is up" -failuremsg "kibana is down"`

...and for the evolution into `get-status` as a cmdlet, we'll have to wait until the next post, as this one is already pretty long. I'm excited to flesh this out though, and work out what will most likely end up being some parsing issues.