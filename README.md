# Memelex

A personal knowledge-base, written in Elixir.

## What is a Memex?

**Introducing Memelex (Denver Elixir meetup, December 2021)**
https://www.youtube.com/watch?v=ahyH5EqSDwk

Memex is the name of the hypothetical electromechanical device that
Vannevar Bush described in his 1945 article "As We May Think". Bush
envisioned the memex as a device in which individuals would compress
and store all of their books, records, and communications, "mechanized
so that it may be consulted with exceeding speed and flexibility". The
individual was supposed to use the memex as automatic personal filing
system, making the memex "an enlarged intimate supplement to his/her memory".
Ted Nelson, who did pioneering work with first practical hypertext system
(a pre-cursor to modern web browsers), and coined the term “hypertext”
in the 1960’s, credited Bush as his main influence.

https://en.wikipedia.org/wiki/Memex

Many people have implemented the ideas of the Memex in various pieces of software. My
favourite of these is [TiddlyWiki](https://tiddlywiki.com/). I was a TiddlyWiki
user for a while, and I rate it as very good software indeed. In particular,
I admire Ruston's choice to save all the data _within the code itself_.
This design choice clearly leads to more robust (I use the word 'perdurable')
software, and as Ruston himself says "even 80 years from now I will still
be able to run my TiddlyWiki, because the software and all my data runs
in the most pervalent platform aaround today, the browser." I did not go
down this path for Memelex because I wanted to share this source-code with
the world - and committing modules like "MyFriends" and "MyPasswords" into
a public git repo was a non-starter. We gain some flexibility by splitting
out the data this way, but an unfortunate yet unavoidable tradeoff in this
choice is that loss of perdurability I so admire about TiddlyWiki. It has
however been my intention to hide this from the user, so that when you're
using the Memex on the command line, it feels like you're purely interacting
with Elixir modules that contain all your data inside them.

So if TiddlyWiki is so good, why create this Memex? Well, this software
began life as just a feature of another project of mine, [Flamelex](https://github.com/JediLuke/flamelex),
which is a text-editor programmed in Elixir. I wanted to have a text-editor
with a built-in memex. As a programmer, it infuriated me that I was always
going to a browser, using my mouse to "copy" some code-snippet, back into
my text-editor. So I wanted to integrate these programs. I also wanted to
be able to access the Memex on the command line, because as a programmer
that's just how I use a computer. And as an Elixir programmer, what I really
wanted was to access the Memex in the IEx console - thus, `Memelex` was
born. During development of Flamelex I decided to spin this off into it's
own program, as it was growing increasingly complex, and I realized that
all I really needed to make the Memex work was an IEx console and text-editor
(I use `gedit` to fill this role, at least until Flamelex is developed
enough to fullfil my original goal, when I will integrate these two
programs once again).

This Memex is logically almost a compelte clone of TiddlyWiki - each piece
of information is saved as a "TidBit", they contain links to other TidBits,
have tags etc. To get a good understanding of this model, and just because
it's such good software, I highly encourage you to play around with TiddlyWiki
and learn how it's underlying data model works.

In the documentation, the `Memex` is one's personal collection of data.
`Memelex` is this Elixir application, which is used to access one's Memex.

## Creating your local Memex environment

### Make a local `memex` directory

The memex uses local storage (i.e. your hard-disc) to persist data.
When Memex boots, it looks in it's configuration for a directory to use,
the `memex_directory`. This directory must be made manually before we can
use the Memex. You can set this in the `config.exs`config file, because we
will be running Memex in `:dev` mode.

We also may optionally declare a backups directory. Backups are taken
periodically just incase we accidentally corrupt or otherwise break the
Memex database. This is also declared in the `config.exs` config file.
It is recommended to store backups on an external drive.

For example:

Make the directories
```
mkdir -p /home/pi/memex/JediLuke
mkdir -p /Volumes/Samsung\ USB/memex_backups/
```

Note that this example is a bit mixed up, MacOS uses `Volumes` for external
drives, but linux uses `/home/pi` as it's root directory... it's an example,
you're supposed to read it not just copy-paste!

Then the `config.exs` file would look like this:
```
config :memelex,
  environment: %{
    name: "JediLuke",
    memex_directory: "/home/pi/memex/JediLuke",
    backups_directory: "/Volumes/Samsung\ USB/memex_backups/"
  }
```

#### The test environment

If you wish to modify the Memelex source-code, you may be interested in
running the unit tests. The tests use their own Memex environment - we must
create a directory and specify it in the `test.exs` file to use when
running the ExUnit tests. *DO NOT use the same directory as your real Memex
for testing*, because we delete the entire contents of this directory
immediately after running the tests!!

### Cloning an existing Memex

Memelex has the ability to save encrypted backups in a Git repo (TODO see:
how to backup the Memex). To pull down an existing Memex & get started
that way, see (HOW TO CLONE AN EXISTING MEMEX) #TODO

### Installing dependencies

To make editing some text files easier. the Memex uses some third-party
text editors. On Linux, I have used [gedit](https://wiki.gnome.org/Apps/Gedit) to great effect.
On MacOS I have used [Sublime](https://www.sublimetext.com/) which also works very well.

In order to be able to open and edit text files using one of these third
party softwares, you will need to install them & ensure that they can be
called via the command line, e.g.

```
subl ~/some_notes.txt
```

Whatever text editor you use, you need to configure it in the `config.exs`
file:

```
config :memelex,
  text_editor_shell_command: "gedit" # e.g. gedit ~/some_notes.txt
```

### Declaring secret keys as environment variables

The Memex stores some data encrypted, e.g. Git-based backups, and passwords
saved locally. These encryption keys are required in order for the Memex
to function correctly, so they must be declared.

To generate a good password, use the following Elixir code:

```
:crypto.strong_rand_bytes(30) |> :base64.encode
```

Or, if you can open Memex:

```
Memelex.Utils.Encryption.generate_password
Memelex.Utils.Encryption.generate_secret_key
```

Then (assuming you are using bash shell, other shells will have different
syntax) you must declare the following environment variables:

* MEMEX_PASSWORD_KEY
* MEMEX_SYNCING_KEY

e.g.

```
export MEMEX_PASSWORD_KEY=some_random_string
```

Without these declarations, the Memex may still run, but functionality will
be limited.

## Running the Memex

Assuming you have created the memex directory and updated your `config.exs`
file - we start the memex as a typical Elixir application, in `dev` mode,
opening up an IEx console (which is how we primarily interact with the Memex).

```
iex -S mix run
```

## Getting Started - how to use the Memex for beginners

As has been mentioned, the underlying data model comes from TiddlyWiki.
To develop some intuition for it, I suggest playing around with it for
a few hours.

Once you have a mental image of it, you just need to understand that the
Memex is not much more than a wrapper around a list of TidBits. Instead
of Tidlers, we call them TidBits - but it's the same concept. Instead of
saving them inside a HTML/Javascript file (surely the coolest feature of
TiddlyWiki!) we simply save them as text files to disc.

Right now, there is no "story river" as you might be used to in the
TiddlyWIki UI.

## Using the API modules

The entire point of an API module is to make a user-friendly interface around
day to day tasks like manipulating TidBits & their labels. So when we have any
function like:

> Memelex.My.Appointments.new()
> Memelex.My.Snippets.new()

or

> Memelex.My.TODOs.new()

They all have this siilar interface which is usually just "add this tag"

## Using the `my_customizations.ex` module in your Memex

Although the original idea was that each person would have their own copy of the
Memex repo & simply update it themselves (and I actually think this is something
every serious user of the Memex needs to do!) there comes a point where (at least
for me, as the main developer) there are some things so specific to an individual
that putting them into the mainline code simply doesn't make sense.

For example, I want to have a function which will bring up the current chapter of the
book I am writing. I want to be able to use the function in the REPL, and not have to
go through some clunky "TidBitBit.find(%{tags: "my_writing", "title_of_my_book"})...
I want to just use something like `JediLuke.open_my_book`. This will have tab
completion, and can encapsulate even complex logic - but nobody else would want this! So I
added the ability to load modules dynamically from _inside the Memex itself_

Modules places inside the `my_customizations.ex` file in the Memex will be loaded
into the BEAM when the Memex boots. You also can put any custom boot code you would
like in here.

Note that this module needs to be git-tracked _seperately_, so it's really not ideal
having it out - we should try to minimize the things in here. One should
consider this file as a piece of data in your personal Memex, and not code
that has been comitted to the `Memelex` project repo.

There's some stuff which just doesn't fit into the standard API - for example,
I have a module called `Memelex.My.Work`, and whilst (sadly) we all have to work,
what that looks like (and the secrets/conveniences) people need will differ.
So this is another good example of something would would fit best inside
the `my_customizations.ex` file.

### Reloading the `my_customizations.ex` file

If you change the code in the `my_customizations.ex` file, you can reload
it without restarting the Memex using the following function call:

```
iex> Memelex.reload_customizations()
```

### How to backup the Memex

#### Utilizing a git repo for backups & cross-device syncing

This is a WIP #TODO

#### Cloning an existing Memex

If an encrypted backup has already been performed & pushed to a git repo,
you can pull it down & activate it by following these steps.

NOTE - right now, there's a lot of manual steps to push/pull, because
Memex isn't managing the git repo itself, just important and exporting
from a local git-repo. It's on the user to make sure the most up to date
versions are being push/pulled. This will be improved in upcoming versions
of Memelex.

*1 - Clone the repo*

If your Memex directory was say `~/memex/JediLuke`, then if the backup was
done correctly, the git repo will be named `JediLuke_sync`. Go to `~/memex`
and clone the repo

```
cd ~/memex
git clone https://github.com/JediLuke/JediLuke_sync
ls
JediLuke      JediLuke_sync      memex_backups
```

This is obviously just an example, your Memex will have a different name,
but the `_sync` convention will be the same. If you didn't already have
a main directory for your Memex, you will need to create one, e.g.
`mkdir -p /home/pi/memex/JediLuke`

*2 - Start Memelex & pull-in the repo*

After cloning the repo, then start Memelex as normal. Assuming you have
an empty Memex directory set up (if it's not empty, it will be over-written
by this process!!) then Memelex should start up normally, just with no
data to use.

With Memelex running, go to the IEx console and run the following function:

```
Memelex.Utils.Sync.pull_in()
```

This will copy & decrypt all the files inside the git repo into your local
Memex directory.

*3 - Restart the Memex*

You now have all the files in the Memex at your disposal. Simply restart
Memelex to ensure they are loaded in correctly.

## Memex Agents

Agents are processes continuously running. Unlike the rest of the Memex, which
is a glorified wrapper around reads/writes to text files (thus, not pro-active),
Agents are always running in a loop (as they are all GenServers) so they can
be working on things in the background, without requiring user intervention.

#TODO we should be able to declare custom agents inside each Memelex

## Troubleshooting

### Using `kiex` and `kerl` to get the correct Elixir versions.

Inside the `~/workbench/tools/kerl` directory, run:

```
pi@raspberrypi:~/workbench/tools/kerl $ ./kerl list installations
24.0.3 /home/pi/kerl/24.0.3
pi@raspberrypi:~/workbench/tools/kerl $ . /home/pi/kerl/24.0.3/activate
```

