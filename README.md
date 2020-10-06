## wpi-many

This project contains an ipmlementation of type inference for Checker
Framework type qualifers.  More specifically, it contains scripts used to control
[do-like-javac](https://github.com/kelloggm/do-like-javac) to run
[whole-program
inference](https://checkerframework.org/manual/#whole-program-inference)
(WPI) of Checker Framework annotations.

These scripts support two use cases:
1. running large-scale experiments on a collection of GitHub repositories, and
2. inferring type qualifiers for a single project.

### Large experiments

To run a large experiment:

1. Use `query-github.sh` to search GitHub for candidate repositories.
File `securerandom.query` is an example query, and file `securerandom.list`
was created by running `./query-github.sh securerandom.query 100`.

2. Use `wpi-many.sh` to run whole-program inference on every
Gradle or Maven project in a list of (GitHub repository URL, git hash)
pairs.
 * If you are using a checker that is distributed with the Checker
   Framework, use wpi-many.sh or wpi.sh directly.
 * If you are using a checker that is not distributed with the Checker
   Framework (also known as a "custom checker"), file
   `no-literal-securerandom-exact-cmd.sh` is a no-arguments
   script that serves as an example of how to use `wpi-many.sh`.

The log files for each project are placed in a results directory.
Each log file will either indicate the reason that WPI could not
be run to completion on the project or include
all the checker invocations that were used during WPI on that project.
The log file for a succesful run indicates whether the project was verified
(i.e. no errors were reported), or whether the checker issued warnings
(which might be true positive or false positive warnings).

3. Use `summary.sh` to summarize the logs in the output results directory.
Use its output to guide your analysis of the results of running `wpi-many.sh`:
you should manually examine the log files for the projects that appear in the
"results available" list it produces. This list is the list of every project
that the script was able to successfully run WPI on.

4. (Optional) Fork repositories and make changes (e.g., add annotations or fix bugs).
Modify the input file for wpi-many.sh to remove the line for the original repository,
but add a new line that indicates the location of both your
fork and the original repository.
Then, re-run your experiments, supplying the -u "$yourGithubId" option to `wpi-many.sh`.
`wpi-many.sh` will perform inference on your forked version rather than
the original. 

See the documentation of the individual scripts for more information.

### Single repository

Run `wpi.sh`.
Its use is similar to `wpi-many.sh`, described above. However,
its input is a single directory on your local machine rather than
a list of repository URLs and hashes. `wpi-many.sh` uses this script internally
after checking out projects.
