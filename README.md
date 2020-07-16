## wpi-many

This project contains scripts used to control
[do-like-javac](https://github.com/kelloggm/do-like-javac) to run
[whole-program
inference](https://checkerframework.org/manual/#whole-program-inference)
(WPI) of Checker Framework annotations.

There are two modes these scripts support:
1. running large-scale experiments on a collection of GitHub repositories, and
2. running WPI on a single project on your local machine.

### Large experiments

To run a large experiment:

1. Use `query-github.sh` to search GitHub for candidate repositories.
File `securerandom.query` is an example query, and file `securerandom.list`
was created by running `./query-github.sh securerandom.query 100`.

2. Use `wpi-many.sh` to run whole-program inference on every buildable
gradle or maven project in a list of (GitHub repository URL, git hash)
pairs.  File `no-literal-securerandom-exact-cmd.sh` is a no-arguments
script that serves as an example of how to use `wpi-many.sh` with a
custom checker.

3. Use `summary.sh` to summarize the logs in the output results directory.

See the documentation of the individual scripts for more information.

### Single repository

Run `wpi.sh`.
Its use is similar to `wpi-many.sh`, described above. However,
its input is a single directory on your local machine rather than
a list of repositories and hashes. `wpi-many.sh` uses this script internally
after checking out projects.
