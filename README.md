## run-dljc

This project contains scripts used to control
[do-like-javac](https://github.com/kelloggm/do-like-javac) to run
[whole-program
inference](https://checkerframework.org/manual/#whole-program-inference)
(WPI) of Checker Framework annotations.

There are two modes these scripts support:
1. running large-scale experiments on a collection of GitHub repositories, and
2. running WPI on a single project on your local machine.

### Large experiments

To run a large experiment, the most important script is
`run-dljc.sh`. It runs whole-program inference on every buildable
gradle or maven project in a list of (GitHub repository URL, git hash)
pairs.  The output is stored in a results directory, which can be
summarized with `summary.sh`. To create an input file, you can use
`run-queries.sh` to search GitHub for candidate repositories, or you
can write an input file from scratch.

Three example files are included:
* `no-literal-securerandom-exact-dljc-cmd.sh` is a no-arguments script that serves as an example of how to use `run-dljc.sh` with a
custom checker.
* `securerandom.list` is a list of repositories and hashes in the format expected by `run-dljc.sh`. It was created by invoking `run-queries.sh`
and is used by `no-literal-securerandom-exact-dljc-cmd.sh`.
* `securerandom.query` is the GitHub search query used to create `securerandom.list`. The exact command to create `securerandom.list` is
`./run-queries.sh securerandom.query 100`.

See the documentation of the individual scripts for more information.

### Single repository

The entry point for this mode is the `configure-and-exec-dljc.sh` script.
Its use is similar to `run-dljc.sh`, described above. However,
its input is a single directory on your local machine rather than
a list of repositories and hashes. `run-dljc.sh` uses this script internally
after checking out projects.
