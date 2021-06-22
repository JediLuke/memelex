# Initialization of the Mix project

```
pi@raspberrypi:~/workbench $ mix new memex --sup
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/memex.ex
* creating lib/memex/application.ex
* creating test
* creating test/test_helper.exs
* creating test/memex_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd memex
    mix test

Run "mix help" for more commands.
pi@raspberrypi:~/workbench $ cd memex/
pi@raspberrypi:~/workbench/memex $ ls
config  lib  mix.exs  README.md  test
pi@raspberrypi:~/workbench/memex $ git status
fatal: not a git repository (or any of the parent directories): .git
pi@raspberrypi:~/workbench/memex $ git init
Initialized empty Git repository in /home/pi/workbench/memex/.git/
pi@raspberrypi:~/workbench/memex $ git status
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)

	.formatter.exs
	.gitignore
	README.md
	config/
	lib/
	mix.exs
	test/

nothing added to commit but untracked files present (use "git add" to track)
pi@raspberrypi:~/workbench/memex $ git checkout -b mainline
Switched to a new branch 'mainline'
pi@raspberrypi:~/workbench/memex $ git add .
pi@raspberrypi:~/workbench/memex $ git commit -m "“Science has a simple faith, which transcends utility. Nearly all men of science, all men of learning for that matter, and men of simple ways too, have it in some form and in some degree. It is the faith that it is the privilege of man to learn to understand, and that this is his mission. If we abandon that mission under stress we shall abandon it forever, for stress will not cease. Knowledge for the sake of understanding, not merely to prevail, that is the essence of our being. None can define its limits, or set its ultimate boundaries.”
— Vannevar Bush"
[mainline (root-commit) 3fdfa82] “Science has a simple faith, which transcends utility. Nearly all men of science, all men of learning for that matter, and men of simple ways too, have it in some form and in some degree. It is the faith that it is the privilege of man to learn to understand, and that this is his mission. If we abandon that mission under stress we shall abandon it forever, for stress will not cease. Knowledge for the sake of understanding, not merely to prevail, that is the essence of our being. None can define its limits, or set its ultimate boundaries.” — Vannevar Bush
 9 files changed, 155 insertions(+)
 create mode 100644 .formatter.exs
 create mode 100644 .gitignore
 create mode 100644 README.md
 create mode 100644 config/config.exs
 create mode 100644 lib/memex.ex
 create mode 100644 lib/memex/application.ex
 create mode 100644 mix.exs
 create mode 100644 test/memex_test.exs
 create mode 100644 test/test_helper.exs
 ```