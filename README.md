# Nazi Zombies: Portable QuakeC

## About
This is the QuakeC portion of the NZ:P source code. QuakeC is responsible for most game-related code such as weapon logic, ai, and Perks. You can read more about QuakeC on the [Wikipedia page](https://en.wikipedia.org/wiki/QuakeC).

## Project Structure
Here is a brief explanation for each of the (sub)directories in this repository:
* `bin`: Command line binaries for [FTEQCC](https://www.fteqcc.org/) + the ini configuration file.
* `progs`: `*.src` files, a list of QuakeC source files each platform is dependent on. 
* `source`:
  * ~~`client`: FTE-exclusive CSQC, used for the HUD, achievements, and other server->client requests.~~
  * `server`: Game code relevant to all platforms, contains most expected logic.
  * `shared`: Definitions for weapon stats and some utility functions ~~shared by both the `client` and `server`~~.
* `tools`: Build scripts to compile the QuakeC into `.dat` and `.lno` files.

## Updating
While it's usually recommended to stay on the QuakeC version provided with your build of NZ:P, you may want to update it to the current development builds to test new features and changes. To do this, navigate to the [Releases](https://github.com/nzp-team/quakec/releases/tag/bleeding-edge) page and follow the instructions there for downloading and installing.

## Building
Like all components, building is supported via [NZ:P Toolbox](https://github.com/nzp-team/toolbox/), via the `build-quakec` command.

After having done this, a `build` directory will have been created, and inside of it will be more directories named after every platform. Copy the contents of the platform directories into your `nzp` game directory. (Example: For PSP, copy `progs.dat` and `progs.lno` from `standard/handheld` to `PSP/GAME/nzportable/nzp`).
