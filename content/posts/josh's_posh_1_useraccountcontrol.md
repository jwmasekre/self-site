+++
title = "josh's posh #1 - parsing the useraccountcontrol property"
date = "2019-12-11"
author = "josh masek"
cover = "img/Powershell_av_colors.ico"
tags = ["posh", "powershell", "active directory", "get-aduser", "properties", "bitwise", "anding"]
keywords = ["", ""]
description = "a quick overview of the `useraccountcontrol` property and an easy way to parse the bits"
showFullContent = false
+++
This first one is the inspiration for the site. I've been a bit obsessed with bitwise anding and parsing flags stored as bits ever since BPF in SANS SEC503. I ran into a situation recently where I wanted to check whether a smartcard was required for an account, but I didn't have access to active directory users and computers (dsa). A quick google search told me that the value for "smartcard required" is 262144, which briefly confused me, since that same search also told me basically all those checkboxes on the account screen are governed by the `useraccountcontrol` property. i found a table that made it much clearer: each flag is assigned a bit, with the highest one in the 27th bit, so really "smartcard required" is `000000001000000000000000000`.

Of course, it usually isn't just one check box; you might have an account that can't change their password and their password doesn't expire (`000000000010000000001000000`), in which case the `useraccountcontrol` property isn't `64,65536`, it gives you `65600`, which is less useful and requires math. Good thing computers are good at math.

There are 22 flags that can be set for the `useraccountcontrol` property, which means, yes, not all bits correspond to a flag (and by extension not all values between 1 and 134217727 are possible). I built a handy little hashtable for "reference":

```powershell
$uacflags = @{1="script";2="accountdisable";8="homedir_required";16="lockout";32="passwd_notreqd";64="passwd_cant_change";128="encrypted_text_pwd_allowed";256="temp_duplicate_account";512="normal_account";2048="interdomain_trust_account";4096="workstation_trust_account";8192="server_trust_account";65536="dont_expire_password";131072="mns_logon_account";262144="smartcard_required";524288="trusted_for_delegation";1048576="not_delegated";2097152="use_des_key_only";4194304="dont_req_preauth";8388608="password_expired";16777216="trusted_to_auth_for_delegation";67108864="partial_secrets_account"}
```

As you can see, the third, eleventh, fifteenth, sixteenth, and twenty-sixth bits are unused. I don't *know* why, per se, but I'd guess it's for future use, especially since I'd bet that's a 32 bit value, which means bits 28-32 are unused as well.

So to make this useful to us, we can run that hashtable so that `$uacflags` is available to reference, do a quick `$user = get-aduser -filter * -properties name,useraccountcontrol | where-object {$_.name -like "masek*"}` to grab my user account, and then we can throw something like this at it:

`$uacflags.Keys | where {$_ -band $user.useraccountcontrol} | foreach {$uacflags.Get_Item($_)}`

Let's analyze. First, `$uacflags.Keys` is just the numbers that we set equal to each flag. By piping it to the `where` statement, we're getting the list of valid values that result from bitwise anding (`-band`) that number against our `useraccountcontrol` property. We then send those numbers to the `foreach` statement, which just returns the values. In my case, `$user.useraccountcontrol` was equal to `66048`. When I ran that line of code above, it returned:

`normal_account`
`dont_expire_password`

So, essentially, we have our list of valid flags and what they mean to humans (the hashtable), we then take each one and bitwise and it against the `useraccountcontrol` property, and then we get the values that actually mean something to humans spat back. That alone is kinda useful for quick lookups, but the real value is getting a list of users (maybe everyone in your admin group) and using this to compare their `useraccountcontrol` flags against the standard, and report on which users have misconfigured flags.