# Adding extra languages to DOMjudge

<!--ts-->
<!-- prettier-ignore -->
   * [Short summary](#short-summary)
   * [Explanation](#explanation)
   * [Improved adding new language in chroot environment of judgehost](#improved-adding-new-language-in-chroot-environment-of-judgehost)
   * [Patch run of rs executable to allow multiple rust source files](#patch-run-of-rs-executable-to-allow-multiple-rust-source-files)
   * [Entering chroot environment in judgehost docker container for debugging](#entering-chroot-environment-in-judgehost-docker-container-for-debugging)
   * [Background info](#background-info)
      * [domjudge's official way to install rustc is to rebuild chroot env from scratch with rustc included](#domjudges-official-way-to-install-rustc-is-to-rebuild-chroot-env-from-scratch-with-rustc-included)
      * [DOMjudge documentation about chroot environment and language executables](#domjudge-documentation-about-chroot-environment-and-language-executables)
      * [Failed attempts to install rustc using build script for rs executable](#failed-attempts-to-install-rustc-using-build-script-for-rs-executable)
<!--te-->

## Short summary

This story begins with the request to add Rust to DOMjudge.

DOMjudge has basic support for rust with rustc, but not with cargo which is normally
used. The reason for this is probably because DOMjudge is meant for small algoritmic
problems. Cargo can probably also not be support because when the judgehost evaluates
the submission it does not have network access in the chroot environment where it
builds and executes the code. Cargo needs network access to download all dependencies
which is not possible. DOMjudge simply requires that you upload all files needed.

For instructions to use Rust with only rustc without cargo see
https://doc.rust-lang.org/rustc/. You can then still have modules next to your main
Rust file.

I found out that DOMjudge supports by default scripts to run rustc for doing
submission of single `.rs` file. However you need a patch for submissions with
multiple `.rs` files.

DOMjudge by default does not have `rustc` installed on the judgehost server. This
installation of `rustc` on he judgehost servers you must do yourself. To official
DOMjudge way to do this installation is to create a new chroot environment with extra
language installed using the `dj_make_chroot` tool on the judgehost. However this is
a slow method which requires in this docker compose setup that specialized judgehost
images must be made.

Instead I first tried to install rustc by adapting the build script of the `rs`
executable via the DOMjudge web interface. However this was not possible because the
non-root user rights and lack of network access.

Then I decided to use a more direct approach of adapting the default chroot
environment in the containers from the default image. I did this by wrapping the
start.sh script run on booting the judgehost container to make it call an
`install-languages` script which adds extra languages in chroot environment of the
judgehost. After that the wrapper script calls the normal startup script of the
judgehost.

The `install-languages` script is bind mounted in the judgehost container, and can be
easily adapted to add installation instructions of other languages. After adaption
the end-user only needs to enable the language for submitting in the DOMjudge web
interface and you can also submit code in that language.

This method using an `install-languages` script gives you an easy and flexible way to
add languages to DOMjudge.

The DOMjudge started with the `docker-compose.yml` and `install-languages` files in
this repository by default adds the `rustc` compiler to the judgehosts. You then only
need to fix the `run` script for the `rs` executable, and then enable the 'Allow
submit' and 'Allow judge' options of the rust language. (details see below)

## Explanation

DOMjudge evaluates programs on separate judgehosts, where each judgehost has a
specialized chroot environment in which it runs the programs.

The default chroot environment is setup for c,c++,java, and pypy3

DOMjudge allows you to add more languages. You have to

1.  create a new chroot environment with extra language installed using the
    `dj_make_chroot` tool on the judgehost (see below instructions for rustc)
2.  add an 'compile executable' on the domserver
3.  create a language definition on the domserver using the 'compile executable'
4.  enable for the language the 'Allow submit' and 'Allow judge' options

note: for many languages 2) and 3) are already defined for many languages, you only
have to do 1) and 4)

In step 2) you add an 'compile executable'. This It can include a build file which is
run once to create run script. However one can skip the build file and directly
provide the run script. Both build and run are run in the chroot env of the
judgehost.

## Improved adding new language in chroot environment of judgehost

The default chroot environment is setup for c,c++,java, and pypy3

The official method of DOMjudge for adding an extra language to chroot environment is
to build a a new chroot environment with extra language installed using the
dj_make_chroot tool on the judgehost (see below instructions for rustc)

However in our setup (https://github.com/harcokuppens/DOMjudgeDockerCompose) we use
an prebuild docker image for the judgehost. To build a new chroot environment we need
to make a new docker image. This means extra work:

- we have to make a new docker image for every new version of judgehost image
- we have to deploy this image so that it is available
- if we want add another language we again need to make new images => very
  inflexible!

I thought to have an easier solution by using the the build script to install a
language however the the chroot env of the judgehost is pretty limited:

- commands are run as a none-root user, and you cannot become root
- there is no network access -> everything you need to install must be supplied in
  the zip note: you can upload a zip with files containing the build and run scripts
  but also with other files => this means that you have to figure out what is
  downloaded during a normal install via internet (and which dependencies are needed)
  which makes it pretty complicated to configure and to break it (in case of new
  judgehost docker image)!

So using a build script to install the extra language does not really work.  
Therefore I decided to use another method: patch to chroot environment in the
judgehost docker container using an install script which is run at container startup.
The language install script is run immediately in the chroot environment as root with
network access. To run the language install script we needed to wrap the original
/scripts/start/sh startup script, where the wrapper script:

1.  becomes the new command of the container (set in docker compose)
2.  it first calls: /opt/domjudge/judgehost/bin/dj_run_chroot /bin/install-languages
    where it runs the language install script within the chroot environment
3.  then it calls the original start script: exec /scripts/start.sh

Advantages of this method:

- have root and network access, so we can just do simple apt-get installation
- installation happens immediately when container is started note: with build the
  installation happens on first submission of source files of that language
- easy to adapt the language installation script to add more languages; you can also
  test this script in a running judgehost

Adaptations needed in `docker-compose.yml`

Changed:

     judgehost-1:
       image: domjudge/judgehost:${DOMJUDGE_VERSION}
       ...
       volumes:
         - /sys/fs/cgroup:/sys/fs/cgroup:ro
         - ./data/passwords:/passwords:ro

Into:

     judgehost-1:
       image: domjudge/judgehost:${DOMJUDGE_VERSION}
       ...
       volumes:
         - /sys/fs/cgroup:/sys/fs/cgroup:ro
         - ./data/passwords:/passwords:ro
         - ./install-extra-languages/install-languages:/chroot/domjudge/bin/install-languages:ro
         - ./install-extra-languages/wrapped-start.sh:/scripts/wrapped-start.sh:ro
       command: /scripts/wrapped-start.sh

Note that the same change is applied to all judgehost services (judgehost-0 and
judgehost-1).

The change in the `docker-compose.yml` needs the following scripts to be added:

    $ cat install-extra-languages/wrapped-start.sh
    #!/bin/sh

    # script which wraps the normal start.sh script of the judgehost to that
    # we before starting the judgehost we can install extra languages in the chroot environment of
    # the judgehost using the 'install-languages' script

    # following line copied from /scripts/start.sh which is needed to get network running right in chroot
    cp /etc/resolv.conf /chroot/domjudge/etc/resolv.conf
    # run script to install extra languages in chroot
    /opt/domjudge/judgehost/bin/dj_run_chroot /bin/install-languages
    # start normal judgehost start script
    exec /scripts/start.sh


    $ cat install-extra-languages/install-languages
    #!/bin/sh

    # this script installs extra languages withing the chroot environment of the judgehost
    # this script is run within the chroot environment of the judgehost
    # commands in this script must run non-interactive
    # note: the installed languages must manually be enabled in the domserver. However
    #       this only needs to be done once, because these settings are persistently stored
    #       in the mariadb domjudge database on disk.

    # install rustc
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y rustc

## Patch `run` of `rs` executable to allow multiple rust source files

The `rs` executable can be found in the DOMjudge interface at
https://SERVER/jury/executables/rs .

The default run script for rust with the `rs` executable does:

    #!/bin/sh

    DEST="$1" ; shift
    MEMLIMIT="$1" ; shift

    # first you need to ./dj_make_chroot -i rustc

    mkdir rust_tmp_dir
    export TMPDIR=rust_tmp_dir
    rustc -C opt-level=3 -o "$DEST" "$@"
    rmdir rust_tmp_dir
    exit 0

However this gives an error if you give two source files like main.rs and foo.rs in
the example at https://doc.rust-lang.org/rustc/

      Compiling failed: no executable was created; compiler output:
      error: multiple input filenames provided (first two filenames are `main.rs` and `foo.rs`)

The problem is caused by giving rustc multiple source files. As described in
https://doc.rust-lang.org/rustc/ you should only give the rust file with the main
function as argument, and rustc will automatically find all files which are imported.
E.g. 'mod foo;' in main.rs will rustc automatically look for foo.rs and then it will
compile it and link it into the final binary.

So the fix is to find the rust source file with the main function and only give that
to rustc compiler:

        #!/bin/bash

        DEST="$1" ; shift
        MEMLIMIT="$1" ; shift

        # first you need to ./dj_make_chroot -i rustc

        mkdir rust_tmp_dir
        export TMPDIR=rust_tmp_dir
        found_main="false"
        for rustfile in "$@"
        do
        if grep -q 'fn main' "$rustfile"
        then
            rustc -C opt-level=3 -o "$DEST" "$rustfile"
            found_main="true"
            echo "rust file '$rustfile' contains main function"
            break
        fi
        done
        rmdir rust_tmp_dir
        if [[ "$found_main" == "true" ]]
        then
        exit 0
        else
        echo "no main function found in rust files: $@"
        exit 1
        fi

## Entering chroot environment in judgehost docker container for debugging

To debug the `install-languages` within a judgehost container's chroot environment we
first need to access it there. This can easily done using the following docker
commands:

    $ docker exec -it judgehost-1 bash
    -> we enter judgehost-1

    # dj_run_chroot
    Entering chroot in '/chroot/domjudge'
    -> now we enter chroot directory /chroot/domjudge on judgehost-1 as root folder /


    $ docker exec -it judgehost-1 dj_run_chroot
    Entering chroot in '/chroot/domjudge'
    -> now we directly enter chroot directory /chroot/domjudge on judgehost-1 as root folder /

## Background info

### domjudge's official way to install rustc is to rebuild chroot env from scratch with rustc included

from http://localhost:12345/jury/executables/rs

build

    #!/bin/sh
    # nothing to compile

run

    #!/bin/sh

    DEST="$1" ; shift
    MEMLIMIT="$1" ; shift

    # first you need to ./dj_make_chroot -i rustc

    mkdir rust_tmp_dir
    export TMPDIR=rust_tmp_dir
    rustc -C opt-level=3 -o "$DEST" "$@"
    rmdir rust_tmp_dir
    exit 0

=> so official instructions advices to make new chroot with rustc package installed
we do this with

        $ docker exec -it judgehost-1 bash

        # dj_make_chroot -a amd64 -i rustc -d /chroot/domjudgerust -y
                                      `-> use 'cargo' here to install cargo instead!
        -> takes a long time
          note: still doesn't install cargo

        # dj_run_chroot -d /chroot/domjudgerust/ rustc --version
        rustc 1.63.0

### DOMjudge documentation about chroot environment and language executables

https://www.domjudge.org/docs/manual/8.2/install-judgehost.html#make-chroot

The judgedaemon compiles and executes submissions inside a chroot environment for
security reasons. By default it mounts parts of a prebuilt chroot tree read-only
during this judging process (using the script lib/judge/chroot-startstop.sh). The
chroot needs to contain the compilers, interpreters and support libraries that are
needed at compile- and at runtime for the supported languages.

-> chroot environment

This chroot tree can be built using the script bin/dj_make_chroot. On Debian and
Ubuntu the same distribution and version as the host system are used, on other Linux
distributions the latest stable Debian release will be used to build the chroot. Any
extra packages to support languages (compilers and runtime environments) can be
passed with the option -i or be added to the INSTALLDEBS variable in the script. The
script bin/dj_run_chroot runs an interactive shell or a command inside the chroot.
This can be used for example to install new or upgrade existing packages inside the
chroot. Run these scripts with option -h for more information.

-> building chroot environment

Finally, if necessary edit the script lib/judge/chroot-startstop.sh and adapt it to
work with your local system. In case you changed the default pre-built chroot
directory, make sure to also update the sudo rules and the CHROOTORIGINAL variable in
chroot-startstop.sh.

https://www.domjudge.org/docs/manual/8.2/config-advanced.html#executables

-> adding executables to chroot in domjudge

DOMjudge supports executable archives (uploaded and stored in ZIP format) for
configuration of languages, special run and compare programs. The archive must
contain an executable file named build or run. When deploying a new (or changed)
executable to a judgehost build is executed once if present (inside the chroot
environment that is also used for compiling and running submissions). Afterwards an
executable file run must exist (it may have existed before), that is called to
execute the compile, compare, or run script. The specific formats are detailed below.

Executables may be changed via the web interface in an online editor or by uploading
a replacement zip file. Changes apply immediately to all further uses of that
executable.

=> build and run script uploaded to judgehost server and run in its chroot
environment -> thus executed at submission, and build only on first submission.

When deploying a new (or changed) executable to a judgehost build is executed once if
present (inside the chroot environment that is also used for compiling and running
submissions).

### Failed attempts to install rustc using build script for rs executable

I discovered that : build and run script uploaded to judgehost server and run in its
chroot environment -> thus executed at submission, and build only on first
submission.

1.  first attempt to install rustc with apt-get

        build:
          #!/bin/sh
          apt-get update
          apt-get install rustc
          # => fails because not running as root, and would otherwise still fail because lack of network

2.  second attempt to install rustc as normal user using rustup

        http://localhost:12345/jury/executables/rs
          build:
            #!/bin/sh
            # nothing to compile

            #curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            # => fails no curl nor wget available in chroot env of judgehost
            #php -r '$content = file_get_contents("https://sh.rustup.rs");file_put_contents("rustup.sh", $content);'
            # => fails no php available in chroot env of judgehost
            pypy3 -c "import urllib.request; urllib.request.urlretrieve('https://sh.rustup.rs','rustup.sh')"
            # => fails with https://stackoverflow.com/questions/57353810/urlopen-error-errno-3-temporary-failure-in-name-resolution
            #    because no network available in chroot env of judgehost

            cat rustup.sh | sh -s -- -y

both attempts failed because chroot environment is too restrictive:

1. no root ; only access as normal user
2. no network available
