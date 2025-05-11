# Nazi Zombies: Portable QuakeC

## About
This is the QuakeC portion of the NZ:P source code. QuakeC is responsible for most game-related code such as weapon logic, ai, and Perks. You can read more about QuakeC on the [Wikipedia page](https://en.wikipedia.org/wiki/QuakeC). NZ:P makes use of CSQC for PC/FTE.

## Project Structure
Here is a brief explanation for each of the (sub)directories in this repository:
* `bin`: Command line binaries for [FTEQCC](https://www.fteqcc.org/) + the ini configuration file.
* `progs`: `*.src` files, a list of QuakeC source files each platform is dependent on. 
* `source`:
  * `client`: FTE-exclusive CSQC, used for the HUD, achievements, and other server->client requests.
  * `server`: Game code relevant to all platforms, contains most expected logic.
  * `shared`: Definitions for weapon stats and some utility functions shared by both the `client` and `server`.
* `tools`: Build scripts to compile the QuakeC into `.dat` and `.lno` files.

## Updating
While it's usually recommended to stay on the QuakeC version provided with your build of NZ:P, you may want to update it to the current development builds to test new features and changes. To do this, navigate to the [Releases](https://github.com/nzp-team/quakec/releases/tag/bleeding-edge) page and follow the instructions there for downloading and installing.

## Building (Beginner Friendly)
There are no prerequisites or dependancies needed to build QuakeC other than a working Windows, macOS, or Linux-based machine.

Before you can build the NZ:P QuakeC, you must either [download](https://github.com/nzp-team/quakec/archive/refs/heads/main.zip) this repository (easy) or [clone it](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) (for developers).

[Python](https://www.python.org/) 3.7 or above is required to execute additional required components for hash table generation. You can install the [required modules](https://raw.githubusercontent.com/nzp-team/QCHashTableGenerator/main/requirements.txt) with `pip install -r requirements.txt` pointing to the provided file.

To build, simply navigate to the `tools` directory and run the `qc-compiler-*` script for your platform. If unfamiliar with executing shell (`.sh`) scripts on Linux systems, give this [itsFOSS article](https://itsfoss.com/run-shell-script-linux/) a read.

After having done this, a `build` directory will have been created, and inside of it will be more directories named after every platform. Copy the contents of the platform directories into your `nzp` game directory. (Example: For PSP, copy `progs.dat` and `progs.lno` from `standard/handheld` to `PSP/GAME/nzportable/nzp`).
