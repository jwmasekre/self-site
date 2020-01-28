+++
title = "josh's posh #5 - enumerating users and groups in AD"
date = "2020-12-26"
author = "josh masek"
cover = "img/Powershell_av_colors.ico"
tags = ["posh", "powershell","active directory", "get-aduser", "get-adgroupmembership"]
keywords = ["", ""]
description = "building a script for enumerating AD for on the fly assessments"
showFullContent = false
draft = true
+++

This is part of an ongoing effort to build a set of tools for in case of an emergency. Part of the training I go through requires falling in on someone else's network and having to perform as comprehensive of a vulnerabilty assessment as possible in a condensed amount of time. I'm mostly leveraging this blog as a means to encourage myself to actually script out the things I do when enumerating Active Directory.

I have a bad problem, as I've identified on twitter: I find myself leaning towards the perfect side of perfect vs. good. I usually try to make my scripts as modular as possible, and end up getting bogged down in usability vs functionality. Because of this, I'm starting this one out being functional. Do the job manually first, then figure out how to start automating pieces, instead of building it from the ground up with modularity and automation in mind.

So first, let's identify what we want. I'm using our Battle Drills as a reference for the types of things we want to check in AD, but if there's more worth checking, I'm all ears. We have the following things listed:

* 
* 
* 
* 
* 
* 
* 

...and those can be enumerated using the following:

* 
* 
* 
* 
* 
* 
* 

Perfect. We have the foundation for our script.