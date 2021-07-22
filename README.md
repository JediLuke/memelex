# Memex

A personal knowledge-base, written in Elixir.

## What is a Memex?

Memex is the name of the hypothetical electromechanical device that Vannevar Bush described in his 1945 article "As We May Think". Bush envisioned the memex as a device in which individuals would compress and store all of their books, records, and communications, "mechanized so that it may be consulted with exceeding speed and flexibility". The individual was supposed to use the memex as automatic personal filing system, making the memex "an enlarged intimate supplement to his memory".

https://en.wikipedia.org/wiki/Memex

* Created by Vannevar Bush
* TiddlyWiki
* Thus, Memex - Memory Extended (same root as Meme)

## Creating your local Memex environment

The memex uses local storage (i.e. your hard-disc) to persist data.
When Memex boots, it looks in it's configuration for a directory
to use, the `memex_directory`. You can set this in the `dev.exs`
config file, because we will be running Memex in `:dev` mode.

For example, this is the config I use when running the Memex
on my Raspberry Pi

```
config :memex,
  environment: %{
    name: "JediLuke",
    memex_directory: "/home/pi/memex/JediLuke"
  }
```

This directory must be created before we run Memex - otherwise,
a runtime error is raised. This also applies to the `:test`
environment when running tests - we must create a directory and
specify it in the `test.exs` file to use when running the ExUnit
tests. DO NOT use the same directory as your real Memex, because
we delete the entire contents of this directory immediately after
running the tests.

## Running the Memex

The Memex runs in dev mode, and you will primarily interact with
it via the IEx console.

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

## Memex Agents

## Using the `my_customizations.ex` module

ALthough the original idea was that each person would have their own copy of the
Memex repo & simply update it themselves (and I actually think this is something
every serious user of the Memex needs to do!) there comes a point where (at least
for me, as the main developer) there are some things so specific to an individual
that putting them into the mainline code simply doesn't make sense.

For example, I want to have a function which will bring up the current chapte of the
book I am writing. I want to be able to use the features of the REPL, and not have to
go through some clunky "TidBitBit.find(%{tags: "my_writing", "title_of_my_book"})...
I want to just use something like `JediLuke.writing_desk`, which will have tab
completion, and fill in the logic behind it - but nobody else would want this! So I
added the ability to load modules dynamically from _inside the Memex itself_

Modules places inside the `my_customizations.ex` file in the Memex will be loaded
into the BEAM when the Memex boots. You also can put any custom boot code you would
like in here.

Note that this module needs to be git-tracked _seperately_, so it's really not ideal
having it out - we should try to minimize the things in here.
