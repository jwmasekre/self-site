+++
title = "come ctf with me #3 - metactf 2020 part 1 - password here please"
date = "2020-10-26"
author = "josh masek"
cover = "img/cg_2020_bonus.png"
tags = ["ctf", "metactf", "reverse engineering"]
keywords = ["", ""]
description = "my solution for the metactf 2020 problem 'password here please'"
showFullContent = false
+++

# MetaCTF 2020 - Password Here Please
For this CTF, I'll upload the challenges I found interesting as individual write-ups. I don't know how many I'll do (time is a bastard) but I'll try and get at least a few. For this challenge specifically, I have the [source code down below](#python%20script), as well as my [full script in the tl;dr](#tl;dr).

## Description
```
I forgot my bank account password! Luckily for me, I wrote a program that checks if my password is correct just in case I forgot which password I used, so this way I don't lock myself out of my account. Unfortunately, I seem to have lost my password list as well...

Could you take a look and see if you can find my password for me?

Part 3 requires some math skills. To solve it, think about what is being done by the exponentiation step. Try rewriting the large number in base 257.
```

## methodology
So this problem is realistically 4 parts: is the length right (`if(len(password[::-2]) != 12 or len(password[17:]) != 7):`), are first 8 chars right (`chunk1`), are second 8 chars right (`chunk2`), are last 8 chars right (`chunk3`). We'll tackle each part one by one, and should have a usable answer at the end.

## part 1 - length
The code is doing some math on the length of the provided password and checking if it matches those. Realistically, you could just brute force this by inputing `A`, then `AA`, etc, but this is how the math works: the colon (`:`) is being used as a slice operator, which is in the form of `[start]:[stop]:[step]`, with the defaults being index 0, end, and 1 respectively. Also, using a negative just reverses everything, so for `[::-2]`, what it's doing is starting at the end, working to the beginning, and skipping every other, to end with a list that would turn `123456789012345678901234` into `[4, 2, 0, 8, 6, 4, 2, 0, 8, 6, 4, 2]`. then, we're taking `len()` (length) of that, which in this case is 12. At this point, just by reading that first bit, we should know that the length is 24, but we can check the other part (which is an or, and could be different). This one is `[17:]`, which is starting at 17 and working its way to the end, stepping by one. the `len()` of the result needs to be 7 to pass, so `17 + 7 = 24` and we have our confirmation that the password is **24 characters long**.

## part 2 - chunk1
Now we start stepping up the math. First, it creates a variable `pwlen` which is just the length of the password. Then, it creates a new string called `chunk1` by taking the ascii decimal value of each character, subtracting it from hex 0x98 (decimal 152), transforming that back into an ascii character, and then sticking the word "key" in between each one. The `for c in range(0, int(pwlen / 3))` part is just iterating from the begining to the 8th character. Then, it checks every 4th character, starting at the first (`chunk[::4]`) to see if it matches string `&e"3&Ew*`. Essentially, the "key" bit is just extra bs that we can ignore, but the other part is easy to reverse. in python, we can do this:

```python
ciphertext = '&e"3&Ew*'
chunk1 = ""
for i in range(0, len(ciphertext)):
    x = 152 - ord(ciphertext[i])
    chunk1 += chr(x)
print(chunk1)
```

Because `152 - x = new_character_decimal_value`, so `152 - new_character_decimal_value = x`

...and that results in **r3verS!n**

## part 3 - chunk2
Again, the math steps up. This one grabs the middle 8 characters (`for c in password[int(pwlen / 3) : int(2 * pwlen / 3)]`, which is from 8 to 16 (24/3 to 2*24/3)) and applies a conditional: if the hex value of the character is greater than 0x60, it subtracts 0x1f, if the hex value is greater than 0x40, it adds 0x1f, and otherwise it doesn't change anything (`chunk2 = [ord(c) - 0x1F if ord(c) > 0x60 else (ord(c) + 0x1F if ord(c) > 0x40 else ord(c))`). This will be useful to us later; this section has to be done totally in reverse.

The next section of it establishes an array (`ring = [54, -45, 9, 25, -42, -25, 31, -79]`), and checks to see if each number in `chunk2` plus the number in the corresponding slot in `ring` is equal to the next number in `chunk2`, *unless we're at the end of `chunk2`*, in which case it compares it to 0. This is the key to this part; we can solve `ring[8] + chunk2[8] = 0` to `chunk2[8] = 79`, and from there solve the rest. in python, that looks like this:

```python
ring = [54, -45, 9, 25, -42, -25, 31, -79]
chunk2array = [0, 0, 0, 0, 0, 0, 0, 79]
for i in range(len(chunk2array)-1, 0, -1):
    chunk2array[i-1] = chunk2array[i] - ring[i-1]
print(chunk2array)
```

That gives us the array of the characters, but we still have to do the conditional arithmetic from above. If we apply the conditionals in reverse, we can determine the original character values. Here is what that looks like in python:

```python
chunk2 = ""
for i in range(0, len(chunk2array)):
    if chunk2array[i] < 0x40:
        chunk2array[i] = chr(chunk2array[i])
    elif chunk2array[i] - 0x1F < 0x40:
        chunk2array[i] = chr(chunk2array[i] + 0x1F)
    else:
        chunk2array[i] = chr(chunk2array[i] - 0x1F)
    chunk2 += chunk2array[i]
print(chunk2)
```

Essentially, there's no condition where a value goes from >0x40 to <0x40, so we know that if it's already less than 0x40, it's the same. The next part is a little tricky; we also know that there's no condition where a value <0x40 goes to >0x40, so if removing 0x1f from the ring value brings it under 0x40, we know that it wouldn't have added 0x1f to get to that value, so we know that 0x1f was subtracted from it and it started >0x60. Finally, anything that's left must have been in the middle, so we know 0x1f must have been added to it. Running this yields us **g_pyTh0n**

## part 4 - chunk3
And finally, the last bit, the most complicated math of the script. It first grabs the last 8 characters of the password (`chunk3 = password[int(2 * pwlen / 3):]`), and then it stores a giant number as `code`. It then checks the value of each character to see if it's less than 0x28, and marks the password invalid if it is. Otherwise, it takes 257 to the power of the value of the character minus 0x28, multiplies that by the number one bit-shifted to the left by the number of the iteration currently on, and then subtracts that giant number from the giant number `code`. That's a lot, so i'll break it down some.

Assuming `i` is 0 and `chunk3[i]` is "A", `257 ** (ord(chunk3[i]) - 0x28)` condenses down to `257 ** (0x41 - 0x28)` (0x41 being the hex value of ascii "A"), which becomes `257 ** 25` (we did some conversions from hex to decimal), which is a 61 digit number, *way* too large to justify placing here. Then, it's multiplied by `1 << i`, which is just 1 in this case. For the rest of the characters, the first bit is unchanged, but here's how a left bit shift works as used here:

In binary, 1 is represented by a 1 preceeded by as many zeros as relevant to the system you're working. For the sake of this problem, we'll use 8 digits (bits) total: `00000001`. When we shift the bit to the left, it becomes this: `00000010`; all characters move to the left and we append a 0 at the end. Since preceding 0s don't mean anything, we can ignore any preceding zeros and drop them. `00000010` is equal to 2 in decimal; if we bitshift by 2, we get `00000100`, which is equal to 4. If we continue until we've bitshifted to 7, we get the following: `0=1, 1=2, 2=4, 3=8, 4=16, 5=32, 6=64, 7=128`. These are the values that we are multiplying our giant number by before subtracting it from our other giant number.

So how do we reverse this? Well, rather elegantly, we can do this:

```python
code = 0xaace63feba9e1c71ef460e6dbf1b1fbabfd7e2e35401440ac57e93bd9ba41c4fbd5d437b1dfab11fe7a1c6c2035982a71765fc9a7b32ccef695dffb71babe15733f5bb29f76aae5f80fff
g = int(code)

def numberToBase(n, b):
    if n == 0:
        return [0]
    digits = []
    while n:
        digits.append(int(n % b))
        n //= b
    return digits[::-1]

truenum = numberToBase(g, 257)
print(truenum)

chunk3array = [0, 0, 0, 0, 0, 0, 0, 0]
chunk3 = ""
for i in range(0, len(truenum)):
    if truenum[i] !=0:
        j = truenum[i]
        for k in range(7 , -1, -1):
            m = 1 << k
            if j >= m:
                chunk3array[k] = chr(len(truenum) - 1 - i + 0x28)
                j = j % m
for i in range (0, len(chunk3array)):
    chunk3 += str(chunk3array[i])
print(chunk3)
```

Of course, that's a lot of code, and it's not totally apparent what we're doing here, so i'll break it down. First, the whole bit where we raise 257 to an exponent is very much like the operations you use to change bases. For example, let's say we have the hex number 3f5. To convert it to decimal, we would, for each digit starting from the back, take that number's decimal value, and multiply it by 16^(the place of the digit, starting with 0):

5 = 16^0 * 5 = 5
f = 16^1 * 15 = 240
3 = 16^2 * 3 = 768

...which comes to 1013.

These equasions look an awful lot like the one in the script: the number place (`^0, ^1, ^2`) is supplanted with `ord(chunk3[i]) - 0x28`, our base is now 257, and the value of the number on that place (`5, 15, 3`) is now instead `1, 2, 4, 8, 16, 32, 64, 128`. Of course, we're trying to solve for something in the middle of that; we want the number place that the values `1, 2, 4, 8, 16, 32, 64, 128` are at. So in our problem, what we're given is equivalent to `1013 = 16^x*5 - 16^y*240 - 16^z*768`, knowing that we're using base 16. that's where our `numberToBase` function comes in. What it does is rewrite the number (like 1013) to something easier to parse: `768, 240, 5`, which tells us `x`, `y`, and `z` since we know that 5 is in the 0 digit spot, 240 is in the 1 digit spot, and 768 is in the 2 digit spot, so our problem is `1013 = 16^0*5 - 16^1*240 - 16^2*768`

Therefore, we need to convert the huge number stored as `code` to base 257 and see where our numbers are at. First, `numberToBase` checks to make sure the value being converted isn't 0, as 0 is 0 in all base configurations. Then, it performs a modulo of our number over our base (`code % 257`) to get the remainder after you divide it by 257, adding it to an array called `digits`. Then, it re-writes `code` as the quotient without the remainder, and repeats until it's 0. It then outputs all of the digits in reverse order, and that gives us our base257 version of `code`:

`[8, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]`

It looks perfect, except for a slight hiccup: one of the values is 17, which isn't in our list. Fortunately, we have everything but the 1 and 16, so what we know is that the 1 space and the 16 space are the same digit. While we can look at this and figure out, based on which space they're all in, what value we need to add 0x28 to, we can make the computer do it, which is what the second part of the script does. It basically just goes through each digit, checks to see if it's not 0, and if not, goes through each of our options (`1, 2, 4..128`) in reverse order, checking to see if it's larger than or equal to that number. If so, it subtracts its location in the array and 1 from the length of the array and adds 0x28, and then takes the modulus of it in case there's another smaller value to be found. For example, at position 19 we have 17. It's not larger than or equal to 128, 64, or 32 but is larger than or equal to 16, so we take 75 (the length of the array) minus 19, minus 1 (since we start at 0 but the length starts at 1), and then plus 0x28, which gives us 95, the decimal value for `_` and store that in the 4th position. We then take 17 % 16, which gives us 1, and then since it's not larger than or equal to 8, 4, or 2 but equal to 1, we do the same thing, storing another `_` in the first position. Once it's finished, we get **_fOr_FUn**

## finally, the answer

```python
print(chunk1 + chunk2 + chunk 3)
```

Just combines the whole thing into **r3verS!ng_pyTh0n_fOr_FUn**, which is the password.

I had a ton of fun with this one, it was challenging but not in a way that was imposible.

## tl;dr
```python
ciphertext = '&e"3&Ew*'
chunk1 = ""
for i in range(0, len(ciphertext)):
    x = 152 - ord(ciphertext[i])
    chunk1 += chr(x)
print(chunk1)

ring = [54, -45, 9, 25, -42, -25, 31, -79]
chunk2array = [0, 0, 0, 0, 0, 0, 0, 79]
for i in range(len(chunk2array)-1, 0, -1):
    chunk2array[i-1] = chunk2array[i] - ring[i-1]
print(chunk2array)
chunk2 = ""
for i in range(0, len(chunk2array)):
    if chunk2array[i] < 0x40:
        chunk2array[i] = chr(chunk2array[i])
    elif chunk2array[i] - 0x1F < 0x40:
        chunk2array[i] = chr(chunk2array[i] + 0x1F)
    else:
        chunk2array[i] = chr(chunk2array[i] - 0x1F)
    chunk2 += chunk2array[i]
print(chunk2)

code = 0xaace63feba9e1c71ef460e6dbf1b1fbabfd7e2e35401440ac57e93bd9ba41c4fbd5d437b1dfab11fe7a1c6c2035982a71765fc9a7b32ccef695dffb71babe15733f5bb29f76aae5f80fff
g = int(code)

def numberToBase(n, b):
    if n == 0:
        return [0]
    digits = []
    while n:
        digits.append(int(n % b))
        n //= b
    return digits[::-1]

truenum = numberToBase(g, 257)
print(truenum)

chunk3array = [0, 0, 0, 0, 0, 0, 0, 0]
chunk3 = ""
for i in range(0, len(truenum)):
    if truenum[i] !=0:
        j = truenum[i]
        for k in range(7 , -1, -1):
            m = 1 << k
            if j >= m:
                chunk3array[k] = chr(len(truenum) - 1 - i + 0x28)
                j = j % m
for i in range (0, len(chunk3array)):
    chunk3 += str(chunk3array[i])
print(chunk3)

print(chunk1 + chunk2 + chunk3)
```

## python script
```python
def ValidatePassword(password):
    print("Password Validator v1.0")
    print("Attempting to validate password...")

    if(len(password[::-2]) != 12 or len(password[17:]) != 7):
        print("Woah, you're not even close!!")
        return False

    pwlen = len(password)
    chunk1 = 'key'.join([chr(0x98 - ord(password[c]))
                             for c in range(0, int(pwlen / 3))])
    if "".join([c for c in chunk1[::4]]) != '&e"3&Ew*':
        print("You call that the password? HA!")
        return False

    chunk2 = [ord(c) - 0x1F if ord(c) > 0x60
                  else (ord(c) + 0x1F if ord(c) > 0x40 else ord(c))
                  for c in password[int(pwlen / 3) : int(2 * pwlen / 3)]]
    ring = [54, -45, 9, 25, -42, -25, 31, -79]
    for i in range(0, len(chunk2)):
        if(0 if i == len(chunk2) - 1 else chunk2[i + 1]) != chunk2[i] + ring[i]:
            print("You cracked the passwo-- just kidding, try again! " + str(i))
            return False

    chunk3 = password[int(2 * pwlen / 3):]
    code = 0xaace63feba9e1c71ef460e6dbf1b1fbabfd7e2e35401440ac57e93bd9ba41c4fbd5d437b1dfab11fe7a1c6c2035982a71765fc9a7b32ccef695dffb71babe15733f5bb29f76aae5f80fff
    valid = True
    for i in range(0, len(chunk3)):
        if(ord(chunk3[i]) < 0x28):
            valid = False
        code -= (257 ** (ord(chunk3[i]) - 0x28)) * (1 << i)

    if code == 0 and valid:
        print("Password accepted!")
        return True
    else:
        print("Quite wrong indeed!")
        return False

print("Please enter password")
while not ValidatePassword(input()):
    pass
```