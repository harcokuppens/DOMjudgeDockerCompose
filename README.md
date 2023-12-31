
# Running DOMjudge in docker

### Table of contents

* [Running DOMjudge in docker](#running-domjudge-in-docker)
  * [Intro](#intro)
  * [About DOMjudge](#about-domjudge)
  * [Quick Start](#quick-start)
    * [Prerequisites](#prerequisites)
    * [Start DOMjudge quickly using git and docker](#start-domjudge-quickly-using-git-and-docker)
    * [Persistency, migration and starting fresh.](#persistency,-migration-and-starting-fresh.)
  * [Overview](#overview)
  * [Stability](#stability)
  * [Migration](#migration)
  * [Resources, performance and deployment](#resources,-performance-and-deployment)
* [Background information](#background-information)
  * [REST interface](#rest-interface)
  * [How credentials are generated/resetted](#how-credentials-are-generated/resetted)
  * [Implementation details of credentials generation/resetting](#implementation-details-of-credentials-generation/resetting)
    * [Old manual method](#old-manual-method)
    * [New automated method](#new-automated-method)
  * [References](#references)
  
## Intro 
This github repository supplies the setup to immediately install and start [DOMjudge](https://www.domjudge.org) in docker.
The `docker-compose.yml` file in this repository is an improved version of the initial version 
described in the article [Deploy Domjudge Using Docker Compose](https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b).  The improvements are:
 
 * automatic starting of the system with one command `docker compose up -d`
 * easy `admin` password management which can be easily done by a system administrator who does not need to know the details of the system
 * improved persistency; we will not lose data when doing `docker compose down`.
 * better stability with automatic restarting
 * easy migration to another server  

## About DOMjudge

DOMjudge is an automated judge system to run programming contests. It has a mechanism to submit problem
solutions, have them judged fully automatically, and provides (web)interfaces for teams, the jury, and the
general public.

## Quick Start

### Prerequisites

To run DOMjudge 

* At least one machine running Linux, with root access is required.
* On this Linux machine `Docker` must be installed, because want to run DOMjudge using `Docker`.
* DOMjudge uses Linux Control Groups or cgroups for process isolation in the judgehost container. Hence, in the Linux kernel `cgroups` must be enabled. To enable `cgroups` edit grub config to add cgroup memory and swap accounting to the boot options:
   * Edit `/etc/default/grub` and change the default commandline to 
   
            GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1 \
                                        systemd.unified_cgroup_hierarchy=0"   
   * Then run `update-grub` and reboot. After rebooting check that `/proc/cmdline` actually contains the added kernel options.


### Start DOMjudge quickly using git and docker 

Run DOMjudge using docker:

    git clone https://github.com/harcokuppens/DOMjudgeDockerCompose.git
    cd domjudge
    docker compose up -d

After a few minutes DOMjudge is running:

* You can access it at http://localhost:12345 . 
* To administrate the server you can login with the `admin` user.
* The password of the `admin` is written in the local bind mount folder in `./passwords/admin.pw`. 
* To reset the `admin` password one can delete the file `./passwords/admin.pw` and execute `docker compose restart`. Then a new `./passwords/admin.pw` file will be generated with a new password.

The DOMjudge system is up and running, and you can start using it. To start reading how to use DOMjudge start reading the  [DOMjudge team manual](https://www.domjudge.org/docs/manual/main/team.html). After you understand how the system works you can start creating a new contest with your specific problems by reading the [Configuring the system](https://www.domjudge.org/docs/manual/main/config-basic.html) section of the [DOMjudge manual](https://www.domjudge.org/docs/manual/).

### Persistency, migration and starting fresh.
For persistency all data stored in the DOMjudge database is kept in a local folder `./mariadb` by using a bind mount. If we delete all containers by running `docker compose down` and recreate new containers when running `docker compose up -d` then still all our configuration and data persist and are used in the newly created containers.  Also the `admin` password in `./passwords/admin.pw` persists. This also allows us to move the installation to another server by just moving the docker folder.

Note: when you want to start with a fresh database, then you can do this by doing `docker compose down` and deleting the `./mariadb` folder. However it is then also important to delete the `./passwords` folder, because the passwords in that folder will not be in the new database anymore. So you should also trigger generating new passwords in the new database and in the `./passwords` folder by also deleting the `./passwords` folder before doing `docker compose up -d`.

## Overview 

The DOMjudge docker installation consists of multiple containers working together.
These containers can all be started with `docker compose up`.
The docker compose configuration is in `docker-compose.yml` and has the following images:

 * `domserver` container
 
     Main server which has the following responsibilities:
     - running as a central control server to run the contests 
     - it uses the `mariadb` container to store its data
     - and it uses the `judgehost` containers as workers to run the
       contest submissions. You can have as many judgehost containers
       as you want.
     - providing the web interface for the users. It lets an admin
       user setup the contests, and let users in teams submit
       solutions to the problems in the contest. The web interface
       also shows you an overview of the statistics of the contest. 
       
     When first started the domserver automatically generates
     a password for an admin account that gets stored  
       
 * `mariadb` container    
     
      Container which has the responsibility to run the database.
      The database  contains all the contest data and configuration
      of the DOMjudge system.

 * `judgehost` container
   
      Container which has the responsibility to execute the submissions.
      You can have as many judgehost containers as you want.
      The judgehost container uses a REST API to communicate
      with the `domserver`. 
                

## Stability

The configuration in `docker-compose.yml`  makes the containers automatically restart if they crash.


## Migration 


To make the installation more persistent and make moving to another server easy,
the `docker-compose.yml` uses a bind mount of the container's folder
`/var/lib/mysql/` to the local `./mariadb/` folder.  
The local `./mariadb/` folder then contains all the data and configuration 
which is stored in the database. 

To move the installation to another server we now only just have 
to move the docker folder and create and start new containers with `docker
compose`. The new containers will have the same data and configuration
as on the old server. 

## Resources, performance and deployment

In this section we discuss how using Docker we can match the resource requirement for running DOMjudge.
 
The DOMjudge manual [says](https://www.domjudge.org/docs/manual/main/overview.html#requirements-and-contest-planning):

> One (virtual) machine is required to run the DOMserver. The minimum amount of judgehosts is also one, but
> preferably more: depending on configured timelimits, and the amount of testcases per problem, judging one
> solution can tie up a judgehost for several minutes, and if there’s a problem with one judgehost it can be
> resolved while judging continues on the others.
> 
> As a rule of thumb, we recommend one judgehost per 20 teams.
> 
> DOMjudge scales easily in the number of judgehosts, so if hardware is available, by all means use it. But
> running a contest with fewer machines will equally work well, only the waiting time for teams to receive an
> answer may increase.
> 
> Each judgehost should be a dedicated (virtual) machine that performs no other tasks. For example, although
> running a judgehost on the same machine as the domserver is possible, it’s not recommended except for
> testing purposes.
> 
> DOMjudge supports running multiple judgedaemons in parallel on a single judgehost machine. This might be
> useful on multi-core machines.

The DOMjudge manual talks about required `machines`, but on a multicore machine each CPU core can be regarded as a machine, as long shared use of other resources such as disk I/O does not affect each other's run times.

The Docker documentation [says](https://docs.docker.com/config/containers/resource_constraints/):

> By default, a container has no resource constraints and can use as much of a given resource as the host's kernel scheduler allows.

In the `docker-compose.yml` configuration we setup one container for the `domserver`, one container for the `mariadb` server, and two containers each running a `judgehost`, where each `judgehost` gets its own dedicated CPU set by the `DAEMON_ID` environment variable. So 2 CPU's are reserved for the `judgehost` containers, and the remaining CPUs are available for the `domserver` and `mariadb` containers.  If your docker host has more CPU's available then you could add even more `judgehost` containers in your 
`docker-compose.yml` configuration. 

If your Docker host does not have  enouchg cores to supply the required number of machines in the Domjudge manual, that is one judgehost per 20 teams, you could decide to run an extra docker host which would run the extra needed `judgehost` containers. This extra docker host would only run `judgehost` containers which connect to `domserver` running on the primary docker host.

The primary host runs both  `domserver` and `judgehost` containers which is fine as long as shared use of other resources then the CPU does not affect each other's run times.  Be aware of this, because it could happen those submissions to the `judgehost` containers could require so much memory that memory on the docker host becomes a bottleneck. This lack of memory then also affects the `domserver` making the DOMjudge system unresponsive. To prevent this from happening one can [limit the maximum memory usage by submissions](https://www.domjudge.org/docs/manual/main/configuration-reference.html#memory-limit). An alternative approach is providing more resources by having the `domserver` and `mariadb` containers deployed on a separate docker host than the `judgehost` containers. If the docker host running the `judgehost` containers doesn't host any other containers, then one can just run a single `judgehost` container with the `DAEMON_ID` environment variable set to the empty string, meaning that that container may use all CPUs, RAM and other resources of the docker host.


# Background information 


## REST interface



The `domserver` container provides a REST interface  that requires user/password authentication using HTTP Basic authentication.

The `judgehost` containers use the REST interface to communicate with the `domserver` container.  

The DOMjudge system allows team members to submit solutions via the web interface, however, it also provides a `submit` command to do the submit from the commandline. This commandline utility internally uses the REST api.


The DOMjudge  documentation website says https://www.domjudge.org/docs/manual/main/develop.html

	DOMjudge comes with a fully featured REST API. It is based on the CCS Contest API specification 
	to which some DOMjudge-specific API endpoints have been added. Full documentation on the available 
	API endpoints can be found at http(s)://yourhost.example.edu/domjudge/api/doc.
	
	DOMjudge also offers an OpenAPI Specification ver. 3 compatible JSON file, which can be found 
	at http(s)://yourhost.example.edu/domjudge/api/doc.json.

When having DOMjudge running in docker this means that the REST API is documented at:

* http://localhost:12345/api/doc.json   using OpenAPI Specification JSON file
* http://localhost:12345/api/doc/   using CCS Contest API specification
 
Below is an example of how to query user info with the `curl` commandline tool:

    $ curl --user admin:ADMINPASSWORD http://localhost:12345/api/v4/user

Note: in the above urls we use `localhost:12345` because in `docker-compose.yml` we map port `80` of the `domserver` container to the local port `12345`.

## How credentials are generated/resetted

To administrate the `domserver` container we need the credentials of an `admin` user. 
The `judgehost` containers use the credentials from the `judgehost` user to communicate using the REST interface with the `domserver` container.  

After all DOMjudge docker containers are started:

* The password of the `admin` can be found in the local bind mount folder in `./passwords/admin.pw`. 
* The password of the `judgehost` can be found in the local bind mount folder in `./passwords/judgehost.pw`. 

If you want to reset the password of either `admin` or `judgehost` you just remove the `.pw` file that user, and restart the DOMjudge docker containers with the command: `docker compose restart`. By restarting it will generate for the missing `.pw` file a new file with a new password. 

This method allows a system administrator to quickly and easily get the initial passwords for `admin` and `domserver`, and allows him to quickly reset either of these passwords without having to know anything about the DOMjudge system.


## Implementation details of credentials generation/resetting


### Old manual method

When the `domserver` container is started for the first time it automatically generates the credentials for both the `admin` as the `judgehost` for you. The `judgehost` credentials need to be passed to the `judgehost` containers.  
The article [Deploy Domjudge Using Docker Compose](https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b) says that you first have to start only the `domserver` container. Fetch the generated REST password from the  `domserver` container and then
assign it to the `JUDGEDAEMON_PASSWORD` environment variable in the `docker-compose.yml` file. Only after having done that you can start the `judgehost` containers. 

### New automated method

Instead of doing this cumbersome manual method, this repository automates this password exchange process.  In `docker-compose.yml` we 

* bind mount the local directory `./passwords/` to the directory `/passwords/` for both the `domserver` and the `judgehost` containers. 

* bind mount the local directory `./start.ro/` to the directory `/scripts/start.ro/` for only the `domserver`.


Latter bind adds an extra start script `./start.ro/60-passwords.sh` to the `domserver` container. This start script provides the following extra functionality:

* Resetting password for the `admin` and or `judgehost` user if no entry for that user is found in the `/passwords/` folder.
* Storing the resetted password in  the `/passwords/` folder.
* After the script is run there should be two password files `/passwords/admin.pw` and `/passwords/judgehost.pw`.

This means that on the first startup of the DOMjudge container, the local `./passwords/` will be empty, causing new passwords to be generated.
One can then easily read the passwords from the local `./passwords/` folder.

It also means that if for some reason we want to reset the password of the `admin` and or `judgehost` user we only have to delete that user's `.pw` file and restart the containers. On restart no entry for the `.pw` file is detected and it will regenerated with a new password.

This method allows a system administrator to quickly and easily get the initial passwords for `admin` and `domserver`, and allows him to quickly reset either of these passwords without having to known anything about the DOMjudge system.

Finally, it also allows us to set the `JUDGEDAEMON_PASSWORD_FILE` environment variable for the `judgehost` containers in the `docker-compose.yml` configuration file to the value `./passwords/judgehost.pw`. When a `judgehost` container starts it can then automatically retrieve the credentials to communicate with the `domserver`. On the first start of the containers, it can happen that the  `judgehost` container tries to read the  `./passwords/judgehost.pw` file which is not yet generated by the `domserver` container. In that case, the  `judgehost` container will exit by this error, and restart. At some point, the  `./passwords/judgehost.pw` will be there and the `judgehost` container can be started without an error. Note that we run `docker compose up -d` to start all containers in one go! We can start the DOMjudge system automatically with one `docker compose up -d` command!


As a last note: the resetting of the password in the `./start.ro/60-passwords.sh` script is done with the `console` commandline utility in the `domserver` container as described by the [DOMjudge manual](https://www.domjudge.org/docs/manual/8.0/config-basic.html?highlight=webapp%20bin%20console#resetting-the-password-for-a-user).


## References

- article 'Deploy Domjudge Using Docker Compose': https://medium.com/@lutfiandri/deploy-domjudge-using-docker-compose-7d8ec904f7b
- DOMjudge website https://www.domjudge.org
- DOMjudge manual https://www.domjudge.org/docs/manual/
- DOMjudge github repository https://github.com/DOMjudge/domjudge
- docker image for `domserver`: https://hub.docker.com/r/domjudge/domserver/    
- docker image for `judgehost`: https://hub.docker.com/r/domjudge/judgehost/
- sources for docker images `domserver` `judgehost`:  https://github.com/DOMjudge/domjudge-packaging/
