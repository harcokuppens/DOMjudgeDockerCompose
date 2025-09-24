# Running DOMjudge in docker

**Table of contents**

<!--ts-->
<!-- prettier-ignore -->
   * [Intro](#intro)
   * [About DOMjudge](#about-domjudge)
   * [Quick Start](#quick-start)
      * [Prerequisites](#prerequisites)
      * [Start DOMjudge quickly using git and docker](#start-domjudge-quickly-using-git-and-docker)
      * [Persistency, migration and starting fresh.](#persistency-migration-and-starting-fresh)
      * [Backup DOMjudge](#backup-domjudge)
      * [Reset DOMjudge](#reset-domjudge)
      * [Update DOMjudge](#update-domjudge)
   * [Overview](#overview)
   * [Stability](#stability)
   * [Migration](#migration)
   * [Version of DOMjudge](#version-of-domjudge)
   * [Resources, performance and deployment](#resources-performance-and-deployment)
* [Install on a production server](#install-on-a-production-server)
   * [Configure backup of data folder; dump mariadb for reliable backup](#configure-backup-of-data-folder-dump-mariadb-for-reliable-backup)
* [Adding extra languages in DOMjudge](#adding-extra-languages-in-domjudge)
   * [Adding Rust language](#adding-rust-language)
* [Background information](#background-information)
   * [REST interface](#rest-interface)
   * [How credentials are generated/resetted](#how-credentials-are-generatedresetted)
   * [Implementation details of credentials generation/resetting](#implementation-details-of-credentials-generationresetting)
      * [Old manual method](#old-manual-method)
      * [New automated method](#new-automated-method)
   * [References](#references)
<!--te-->

## Intro

This github repository supplies the setup to immediately install and start
[DOMjudge](https://www.domjudge.org) in docker. The `docker-compose.yml` file in this
repository is an improved version of the initial version described in the article
[Deploy Domjudge Using Docker Compose](https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b).
The improvements are:

- **automatic starting** of the system with one command `docker compose up -d`
- better **stability** with **automatic restarting**:<br> all containers will
  automatically restarted when they get stopped.
- easy **`admin` password management** which can be easily done by a system
  administrator who does not need to know the details of the system
- improved **persistency**; we will not lose data when doing `docker compose down`:
  <br> This command stops all containers, however, because all data is stored in bind
  mounted folders on the host machine it will persist, and will be used again when
  starting new containers with `docker compose up -d`.
- easy **migration** to another server:<br>
  1. on old server: `docker compose down`
  2. just move the folder containing `docker-compose.yml` to another server
  3. on new server: `docker compose up -d`
- easy to **backup** DOMjudge:
  1. `docker compose down`
  2. just copy the folder containing `docker-compose.yml` to a backup folder set in
     variable `BACKUPFOLDER`:<br> `sudo cp -a . $BACKUPFOLDER`
  3. `docker compose up -d`
- easy to **reset** DOMjudge; deleting all data, starting fresh:
  1. `docker compose down`
  2. `sudo rm -r ./data`
  3. `docker compose up -d`
  4. new admin password in: `./data/passwords/admin.pw`
- easy to **update** DOMjudge:<br> **IMPORTANT:** strongly recommended to backup
  before updating
  1. `docker compose down`
  2. update by newer `DOMJUDGE_VERSION/MARIADB_VERSION` in `.env` file <br> which can
     be also done by `git pull` if the versions in the github repo are updated.
  3. `docker compose up -d`
- easy combined **backup**, **reset**, and **update** :
  1. `docker compose down`
  2. `sudo cp -a . $BACKUPFOLDER`
  3. `sudo rm -r ./data`
  4. `git pull` or edit versions in `.env` file
  5. `docker compose up -d`
  6. new admin password in: `./data/passwords/admin.pw`

## About DOMjudge

DOMjudge is an automated judge system to run programming contests. It has a mechanism
to submit problem solutions, have them judged fully automatically, and provides
(web)interfaces for teams, the jury, and the general public.

## Quick Start

### Prerequisites

To run DOMjudge

- At least one machine running Linux, with root access is required.
- On this Linux machine `Docker` must be installed, because want to run DOMjudge
  using `Docker`.
- DOMjudge uses Linux Control Groups or cgroups for process isolation in the
  judgehost container. Hence, in the Linux kernel `cgroups` must be enabled. To
  enable `cgroups` edit grub config to add cgroup memory and swap accounting to the
  boot options:

  - Edit `/etc/default/grub` and change the default commandline to

           GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1 \
                                       systemd.unified_cgroup_hierarchy=0"

  - Then run `update-grub` and reboot. After rebooting check that `/proc/cmdline`
    actually contains the added kernel options.

### Start DOMjudge quickly using git and docker

Run DOMjudge using docker:

    git clone https://github.com/harcokuppens/DOMjudgeDockerCompose.git
    cd DOMjudgeDockerCompose/
    docker compose up -d

After a few minutes DOMjudge is running:

- You can access it at http://localhost:1080 .
- To administrate the server you can login with the `admin` user.
- The password of the `admin` is written in the local bind mount folder in
  `./data/passwords/admin.pw`.
- To reset the `admin` password one can delete the file `./data/passwords/admin.pw`
  and execute `docker compose restart`. Then a new `./data/passwords/admin.pw` file
  will be generated with a new password.

The DOMjudge system is up and running, and you can start using it. To start reading
how to use DOMjudge start reading the
[DOMjudge team manual](https://www.domjudge.org/docs/manual/main/team.html). After
you understand how the system works you can start creating a new contest with your
specific problems by reading the
[Configuring the system](https://www.domjudge.org/docs/manual/main/config-basic.html)
section of the [DOMjudge manual](https://www.domjudge.org/docs/manual/).

### Persistency, migration and starting fresh.

For persistency all data stored in the DOMjudge database is kept in a local folder
`./data/mariadb` by using a bind mount. If we delete all containers by running
`docker compose down` and recreate new containers when running `docker compose up -d`
then still all our configuration and data persist and are used in the newly created
containers. Also the `admin` password in `./data/passwords/admin.pw` persists. This
also allows us to move the installation to another server by just moving the docker
folder.

### Backup DOMjudge

All data for a specific DOMjudge server is in the `./data` folder. So if we backup
the `./data/` folder then we can always restore the DOMjudge server from this backup.
However over time the `docker-compose.yml` and `.env` files and the `start.ro/`
folder can change because DOMjudge is upgraded, and it may not work anymore with the
old `./data` folder. Therefore it is recommended to also backup the
`docker-compose.yaml` and `.env` files and the `start.ro/` folder next to the
`./data/` folder. The easiest way to do this is by just copy the whole folder
containing the `docker-compose.yml` file.

To restore the old DOMjudge server from the backup, we only need to switch to this
backup folder and run `docker compose up -d`.

To restore the backup data with the latest DOMjudge server we need to
`git clone https://github.com/harcokuppens/DOMjudgeDockerCompose/` and copy the data
folder from the backup into this folder. However it can happen that the newer
DOMjudge server can have problems with this old data.

### Reset DOMjudge

When you want to start with a fresh database, then you can do this by doing
`docker compose down` and deleting the `./data/mariadb` folder. However it is then
also important to delete the `./data/passwords` folder, because the passwords in that
folder will not be in the new database anymore. So you should also trigger generating
new passwords in the new database and in the `./data/passwords` folder by also
deleting the `./data/passwords` folder before doing `docker compose up -d`. Because
the `./data` folder only contains the folders `./data/mariadb` and `./data/passwords`
we just as well can just delete the `./data` folder.

Thus reset DOMjudge with the commands:

    docker compose down
    sudo rm -r ./data
    docker compose up -d

Read the new `admin` password after the reset from the file
`./data/passwords/admin.pw`. You need to use `sudo` before the `rm` command because
in the bind mounts files are written use different user.

### Update DOMjudge

DOMjudge can be easily updated by setting newer version tags for the docker image by
editing the variable `DOMJUDGE_VERSION` and `MARIADB_VERSION` in `.env` file used by
`docker-compose.yml`. Updating can be also done by `git pull` if the version(s) in
the git repository are updated.

**IMPORTANT:** it is strongly recommended to backup before updating, because
sometimes old data may not be compatible with a newer version.

## Overview

The DOMjudge docker installation consists of multiple containers working together.
These containers can all be started with `docker compose up`. The docker compose
configuration is in `docker-compose.yml` and has the following images:

- `domserver` container

  Main server which has the following responsibilities:

  - running as a central control server to run the contests
  - it uses the `mariadb` container to store its data
  - and it uses the `judgehost` containers as workers to run the contest submissions.
    You can have as many judgehost containers as you want.
  - providing the web interface for the users. It lets an admin user setup the
    contests, and let users in teams submit solutions to the problems in the contest.
    The web interface also shows you an overview of the statistics of the contest.

  When first started the domserver automatically generates a password for an admin
  account that gets stored

- `mariadb` container

  Container which has the responsibility to run the database. The database contains
  all the contest data and configuration of the DOMjudge system.

- `judgehost` container

  Container which has the responsibility to execute the submissions. You can have as
  many judgehost containers as you want. The judgehost container uses a REST API to
  communicate with the `domserver`.

## Stability

The configuration in `docker-compose.yml` makes the containers automatically restart
if they crash.

## Migration

To make the installation more persistent and make moving to another server easy, the
`docker-compose.yml` uses a bind mount of the container's folder `/var/lib/mysql/` to
the local `./data/mariadb/` folder.  
The local `./data/mariadb/` folder then contains all the data and configuration which
is stored in the database.

To move the installation to another server we now only just have to move the docker
folder and create and start new containers with `docker compose`. The new containers
will have the same data and configuration as on the old server.

## Version of DOMjudge

The `docker-compose.yml` uses version tags to include docker images for DOMjudge and
its supporting database mariadb:

    $ cat docker-compose.yml |grep image
    image: mariadb:${MARIADB_VERSION}
    image: domjudge/domserver:${DOMJUDGE_VERSION}
    image: domjudge/judgehost:${DOMJUDGE_VERSION}

These version tags are set by environment variables which `docker` reads from the
`.env` file in the same folder:

    $ cat .env
    DOMJUDGE_VERSION="8.2.3"
    MARIADB_VERSION="11.4.2"

By using fixed versions we always know which versions are used. We can always
increase the version numbers of new versions of the software comes available.

## Resources, performance and deployment

In this section we discuss how using Docker we can match the resource requirement for
running DOMjudge.

The DOMjudge manual
[says](https://www.domjudge.org/docs/manual/main/overview.html#requirements-and-contest-planning):

> One (virtual) machine is required to run the DOMserver. The minimum amount of
> judgehosts is also one, but preferably more: depending on configured timelimits,
> and the amount of testcases per problem, judging one solution can tie up a
> judgehost for several minutes, and if there’s a problem with one judgehost it can
> be resolved while judging continues on the others.
>
> As a rule of thumb, we recommend one judgehost per 20 teams.
>
> DOMjudge scales easily in the number of judgehosts, so if hardware is available, by
> all means use it. But running a contest with fewer machines will equally work well,
> only the waiting time for teams to receive an answer may increase.
>
> Each judgehost should be a dedicated (virtual) machine that performs no other
> tasks. For example, although running a judgehost on the same machine as the
> domserver is possible, it’s not recommended except for testing purposes.
>
> DOMjudge supports running multiple judgedaemons in parallel on a single judgehost
> machine. This might be useful on multi-core machines.

The DOMjudge manual talks about required `machines`, but on a multicore machine each
CPU core can be regarded as a machine, as long shared use of other resources such as
disk I/O does not affect each other's run times.

The Docker documentation
[says](https://docs.docker.com/config/containers/resource_constraints/):

> By default, a container has no resource constraints and can use as much of a given
> resource as the host's kernel scheduler allows.

In the `docker-compose.yml` configuration we setup one container for the `domserver`,
one container for the `mariadb` server, and two containers each running a
`judgehost`, where each `judgehost` gets its own dedicated CPU set by the `DAEMON_ID`
environment variable. So 2 CPU's are reserved for the `judgehost` containers, and the
remaining CPUs are available for the `domserver` and `mariadb` containers. If your
docker host has more CPU's available then you could add even more `judgehost`
containers in your `docker-compose.yml` configuration.

If your Docker host does not have enouchg cores to supply the required number of
machines in the Domjudge manual, that is one judgehost per 20 teams, you could decide
to run an extra docker host which would run the extra needed `judgehost` containers.
This extra docker host would only run `judgehost` containers which connect to
`domserver` running on the primary docker host.

The primary host runs both `domserver` and `judgehost` containers which is fine as
long as shared use of other resources then the CPU does not affect each other's run
times. Be aware of this, because it could happen those submissions to the `judgehost`
containers could require so much memory that memory on the docker host becomes a
bottleneck. This lack of memory then also affects the `domserver` making the DOMjudge
system unresponsive. To prevent this from happening one can
[limit the maximum memory usage by submissions](https://www.domjudge.org/docs/manual/main/configuration-reference.html#memory-limit).
An alternative approach is providing more resources by having the `domserver` and
`mariadb` containers deployed on a separate docker host than the `judgehost`
containers. If the docker host running the `judgehost` containers doesn't host any
other containers, then one can just run a single `judgehost` container with the
`DAEMON_ID` environment variable set to the empty string, meaning that that container
may use all CPUs, RAM and other resources of the docker host.

# Install on a production server

The quickstart of DOMjudge gives us access to it at http://localhost:1080 . However
when you really want deploy DOMjudge you need to:

1. serve DOMjudge with a nice DNS name instead of `localhost` and
2. serve DOMjudge using the `https` protocol instead of `http`.

The setup in this repository can easily provide this with only some minor changes in
the configuration. The `docker-compose.yml` is already configured with a `caddy`
reverse proxy server which provides **automatic https** for the DOMjudge server
running `http`. However, by default this `caddy` server is not enabled in the default
profile of docker compose. By running `docker compose` with the `auto-https` profile
enabled, then also the the `caddy` reverse-proxy service, with automatic https, will
be started

     docker compose --profile auto-https  up -d

Now, you can also open DOMjudge with the URL https://localhost:1443.

By default `caddy` serves on `localhost` because the configuration does not yet know
the DNS name of your production server, eg. `my.server.com`. You can change this in
the `caddy/Caddyfile` config file, by changing the domainname from `localhost` to
`my.server.com`. On start of the caddy service, it will then request an official
certificate from a public ACME CA such as Let's Encrypt or ZeroSSL. Your DOMserver
will then serve DOMjudge on your production site at the URL
https://my.server.com:1443.

By default we configure `caddy` to use port 1443 to avoid a possible conflict with an
already running https server on port 443. So the only thing left to finish the
installation is by changing the line in `docker-compose.yml` for the caddy service:

       ports
        - "1443:443"

into

       ports
        - "80:80"
        - "443:443"

Then you can reach you the DOMjudge server at https://my.server.com.

By also opening port 80 in the `caddy` service, `caddy` provides automatic `http` to
`https` redirects, causing any request to http://my.server.com to be automatically
redirected to https://my.server.com.

You can remove at the `domserver` server the lines

    ports:
      ## for development/testing:
      - 127.0.0.1:1080:80

because `caddy` nows provides the access to the `domserver` service.

Finally, you could remove in the `docker-compose.yml` file the `auto-https` option:

    profiles:
      - auto-https

Then `caddy` will be started also with `'docker compose up -d'` without providing the
option `'--profile auto-https'`.

## Configure backup of data folder; dump mariadb for reliable backup

For persistency all data stored in the DOMjudge database is kept in a local folder
`./data/mariadb` by using a bind mount. This allows use to stop and remove the
`mariadb` container, and later restart it again with the same data in the database.
We can move this folder to another machine are restart `mariadb` in the exact same
state on another machine. Handy for migration to a new server.

However we also want a backup of this data in case of corruption of the data. If the
`mariadb` container is running, then copying the folder `./data/mariadb` may result
in a folder with an an inconsistent state. You first have to stop the database before
doing the copy to be sure to get a consistent state. Effectively doing an offline
backup. However using the `mariadb-dump` command you can make a backup when the
database is online. We provide the script `bin/backup` which
without needing any arguments dumps the data in the live database into the dump file
`data/backups/mariadb.sql.gz`. This file can be used to restore the `domjudge`
database using the script `bin/restore-backup`.  On linux you could for example run a crontab job running this command every
night. If you then make sure your backup software backups the `data` folder then you
can always restore from backup. 

We also provide the script `bin/rolling-backup` to make rolling backups. Rolling backups 
are a backup strategy that involves maintaining a continuous set of backups that are 
regularly updated and rotated. By default the  script `bin/rolling-backup` keeps backups 
for 20 days, but you can configure this number of keep days. 

Usage info for `bin/backup`:

```console
$ bin/backup --help
Usage: backup [-h|--help] [FILEPATH]

Backs up the domjudge MariaDB database.

Options:
  -h, --help    Display this help message and exit.

Arguments:
  FILEPATH      Optional. The path where the database dump file will be saved.
                If not provided, the default path is '../data/backups/mariadb.sql.gz'
                relative to the script's location.
```

Usage info for `bin/rolling-backup`:

```console
$ bin/rolling-backup --help
Usage: rolling-backup [OPTIONS]

Options:
  -d, --dir DIR       Set backup directory (default: /home/harcok/20250901_domdata/DOMjudgeDockerCompose/bin/../data/backups/)
  -k, --keep DAYS     Number of days to keep backups (default: 20)
  -h, --help          Show this help message and exit

Example:
  rolling-backup -d /tmp/backups -k 10
```

Usage info for `bin/restore-backup`:


```console
$ bin/restore-backup --help
Usage: restore-backup [-h|--help] FILEPATH

DESCRIPTION
   Restore the domjudge MariaDB database from a dumpfile

OPTIONS
  -h, --help    Display this help message and exit.

ARGUMENTS
  FILEPATH      The path where the database dump file will is located.

EXAMPLE
  First bring your containers down.

     $ docker compose down

  Then start only the mariadb database container

     $ docker compose up -d mariadb

  Restore the database from a dumpfile

     $ bin/restore-backup data/backups/mariadb.sql.gz
     INFO: Restoring from the dumpfile 'data/backups/mariadb.sql.gz'
     INFO: dumping mariadb database succesful

  Delete the old passwords files,
  and let new ones generated on start of the domserver container

     $ sudo rm  data/passwords/*

  Start all containers

     $ docker compose up -d
      ✔ Network caddy_reverseproxy  Created
      ✔ Container mariadb           Running
      ✔ Container domserver         Started
      ✔ Container judgehost-1       Started
      ✔ Container judgehost-0       Started

   Now you should be able to login as 'admin' user using the password
   in data/passwords/admin.pw

   Note that if you remembered the admin password of the backup,
   then you could skip resetting the admin password.

```



Credits to Simon Oosthoek for creating the original version of the
`bin/backup` script.

# Adding extra languages in DOMjudge

DOMjudge by default only supports c,c++,java, and pypy3. If you want support for more
languages you have to do some extra work. However I also made that work easier in
this repository.

To add a new language in DOMjudge you have to do two things:

1. install the language in the judgehost
2. configure the language in the domserver

## Install extra languages in DOMjudge's judgehosts

The `docker-compose.runtime-extra-lang.yml` configuration makes the judgehost
containers to execute the `install-extra-languages/install-languages` script in the
chroot environment of the judgehost where it executes the submissions. You can then
easily add your favorite languages by adding installation commands for these
languages in this `install-extra-languages/install-languages` script.

The standard `docker-compose.yml` instead uses a customized judgehost image which
already has the extra languages rust and kotlin installed. So, by using the standard
`docker-compose.yml` in this repository you automatically get language support for
c,c++,java,pypy3,kotlin and rust!

## Configuring languages in DOMjudge

To configure a language in DOMjudge it has a separate configuration page for the
'language' and its compiler 'executable`. The 'language' page defines the general
configuration of the language, such as whether you are allowed to submit files for
this language. A compiler 'executable' for a language in DOMjudge is basicly a script
that delivers a script/executable to run a set of sources files in that language.  
For a scripting language it delivers a script which executes the python command with
its sources files, but for a compiled language it delivers the executable from
compiling the source files. The judgehost is given this generated script/executable
to judge it using the problem samples. For more details look at
[DOMjudge's executables documentation](https://www.domjudge.org/docs/manual/main/config-advanced.html#executables).

DOMjudge already has a 'language' and compiler 'executable' setup for many languages
to be used in DOMjudge. So for most languages you only need to install the compiler
using the `install-extra-languages/install-languages` script, and then enable the
'language' in the web interface.

See the page [Adding extra languages to DOMjudge](./Adding_extra_languages.md) for
more details about how and why we implemented the
`install-extra-languages/install-languages` script.

The default judgehost has c,c++,java, and pypy3 installed, therefore by default only
these 4 languages are by default activated, so you only need to activate the extra
languages installed: rustc and kotlin. Therefore below we only discuss how to enable
a language in the domserver in the DOMjudge's configuration. We do not discuss the
details setting up compiler 'executable' for a new language. We only provide a fix
for the compiler 'executable' for the Rust language.

### Enable a predefined language

DOMjudge already has configurations setup for many languages, so after that a
language is installed on the judgehost, it is very easy to enable the language. Eg.
to enable the Rust language in the DOMjudge interface:

        click on 'DOMjudge' in top right corner, to get 'DOMjudge Jury interface'
        click on 'Languages'
        in the section 'Disabled languages' click on the line with ID 'rs'
        then on the line with 'Allow submit' click on the toggle box to change it from 'No' to 'Yes'

### Fix for the compiler 'executable' for the Rust language

There is a problem with the default configuration of the Rust language in DOMjudge :
the `run` script for the `rs` executable used by the Rust language only allows a
single rust file. By replacing it with
[the fixed script](./install-extra-languages/run-rust.bash) then you can submit Rust
code in multiple files as explained in https://doc.rust-lang.org/rustc/. Do this by
doing:

        click on 'DOMjudge' in top right corner, to get 'DOMjudge Jury interface'
        click on 'Executables'
        click on the line for the 'rs' executable
        click on 'run' tab to open it
        then change the code in the text box to the fixed script at ./install-extra-languages/run-rust.bash
        click on 'Save files' button at bottom of window

Now you can submit Rust code, either in a single `.rs` file with a main function. Or
multiple `.rs` files where only one of them contains a main function, which includes
the other Rust files as modules, as explained in https://doc.rust-lang.org/rustc/.

# Background information

## REST interface

The `domserver` container provides a REST interface that requires user/password
authentication using HTTP Basic authentication.

The `judgehost` containers use the REST interface to communicate with the `domserver`
container.

The DOMjudge system allows team members to submit solutions via the web interface,
however, it also provides a `submit` command to do the submit from the commandline.
This commandline utility internally uses the REST api.

The DOMjudge documentation website says
https://www.domjudge.org/docs/manual/main/develop.html

    DOMjudge comes with a fully featured REST API. It is based on the CCS Contest API specification
    to which some DOMjudge-specific API endpoints have been added. Full documentation on the available
    API endpoints can be found at http(s)://yourhost.example.edu/domjudge/api/doc.

    DOMjudge also offers an OpenAPI Specification ver. 3 compatible JSON file, which can be found
    at http(s)://yourhost.example.edu/domjudge/api/doc.json.

When having DOMjudge running in docker this means that the REST API is documented at:

- http://localhost:1080/api/doc.json using OpenAPI Specification JSON file
- http://localhost:1080/api/doc/ using CCS Contest API specification

Below is an example of how to query user info with the `curl` commandline tool:

    $ curl --user admin:ADMINPASSWORD http://localhost:1080/api/v4/user

Note: in the above urls we use `localhost:1080` because in `docker-compose.yml` we
map port `80` of the `domserver` container to the local port `1080`.

## How credentials are generated/resetted

To administrate the `domserver` container we need the credentials of an `admin` user.
The `judgehost` containers use the credentials from the `judgehost` user to
communicate using the REST interface with the `domserver` container.

After all DOMjudge docker containers are started:

- The password of the `admin` can be found in the local bind mount folder in
  `./data/passwords/admin.pw`.
- The password of the `judgehost` can be found in the local bind mount folder in
  `./data/passwords/judgehost.pw`.

If you want to reset the password of either `admin` or `judgehost` you just remove
the `.pw` file that user, and restart the DOMjudge docker containers with the
command: `docker compose restart`. By restarting it will generate for the missing
`.pw` file a new file with a new password.

This method allows a system administrator to quickly and easily get the initial
passwords for `admin` and `domserver`, and allows him to quickly reset either of
these passwords without having to know anything about the DOMjudge system.

## Implementation details of credentials generation/resetting

### Old manual method

When the `domserver` container is started for the first time it automatically
generates the credentials for both the `admin` as the `judgehost` for you. The
`judgehost` credentials need to be passed to the `judgehost` containers. The article
[Deploy Domjudge Using Docker Compose](https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b)
says that you first have to start only the `domserver` container. Fetch the generated
REST password from the `domserver` container and then assign it to the
`JUDGEDAEMON_PASSWORD` environment variable in the `docker-compose.yml` file. Only
after having done that you can start the `judgehost` containers.

### New automated method

Instead of doing this cumbersome manual method, this repository automates this
password exchange process. In `docker-compose.yml` we

- bind mount the local directory `./data/passwords/` to the directory `/passwords/`
  for both the `domserver` and the `judgehost` containers.

- bind mount the local directory `./start.ro/` to the directory `/scripts/start.ro/`
  for only the `domserver`.

Latter bind adds an extra start script `./start.ro/60-passwords.sh` to the
`domserver` container. This start script provides the following extra functionality:

- Resetting password for the `admin` and or `judgehost` user if no entry for that
  user is found in the `/passwords/` folder.
- Storing the resetted password in the `/passwords/` folder.
- After the script is run there should be two password files `/passwords/admin.pw`
  and `/passwords/judgehost.pw`.

This means that on the first startup of the DOMjudge container, the local
`./data/passwords/` will be empty, causing new passwords to be generated. One can
then easily read the passwords from the local `./data/passwords/` folder.

It also means that if for some reason we want to reset the password of the `admin`
and or `judgehost` user we only have to delete that user's `.pw` file and restart the
containers. On restart no entry for the `.pw` file is detected and it will
regenerated with a new password.

This method allows a system administrator to quickly and easily get the initial
passwords for `admin` and `domserver`, and allows him to quickly reset either of
these passwords without having to known anything about the DOMjudge system.

Finally, it also allows us to set the `JUDGEDAEMON_PASSWORD_FILE` environment
variable for the `judgehost` containers in the `docker-compose.yml` configuration
file to the value `/passwords/judgehost.pw`. When a `judgehost` container starts it
can then automatically retrieve the credentials to communicate with the `domserver`.
On the first start of the containers, it can happen that the `judgehost` container
tries to read the `/passwords/judgehost.pw` file which is not yet generated by the
`domserver` container. In that case, the `judgehost` container will exit by this
error, and restart. At some point, the `/passwords/judgehost.pw` will be there and
the `judgehost` container can be started without an error. Note that we run
`docker compose up -d` to start all containers in one go! We can start the DOMjudge
system automatically with one `docker compose up -d` command!

As a last note: the resetting of the password in the `./start.ro/60-passwords.sh`
script is done with the `console` commandline utility in the `domserver` container as
described by the
[DOMjudge manual](https://www.domjudge.org/docs/manual/8.0/config-basic.html?highlight=webapp%20bin%20console#resetting-the-password-for-a-user).

## References

- article 'Deploy Domjudge Using Docker Compose':
  https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b
- DOMjudge website https://www.domjudge.org
- DOMjudge manual https://www.domjudge.org/docs/manual/
- DOMjudge github repository https://github.com/DOMjudge/domjudge
- docker image for `domserver`: https://hub.docker.com/r/domjudge/domserver/
- docker image for `judgehost`: https://hub.docker.com/r/domjudge/judgehost/
- sources for docker images `domserver` `judgehost`:
  https://github.com/DOMjudge/domjudge-packaging/

```

```
