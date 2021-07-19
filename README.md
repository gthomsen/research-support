# Overview

Simple, lightweight container image configured with tools useful for doing
research on a macOS laptop.  This provides a stateless container that maps
a portion of the host's file system into the container so that tools can be
applied to the host's data.  The image build process provides customization
of the container's user so that UID/GID mappings are simple and sidesteps the
issue of files created in the container are unusable on the host.  A wrapper
script is provided to simplify launching the container and mapping directories
from the host.

This approach is intended for adding Linux-based tools in a reproducible manner
that avoids the headaches of macOS-based package management systems
(e.g. MacPorts or Homebrew).  While the implementation was driven by the macOS
ecosystem, there is nothing macOS-specific in the tooling that would preven it
from being used on Windows or Linux.

## Packages Provided

The following packages are available in the support container image:

1. [`pdfgrep`](https://pdfgrep.org/) - Flexible PDF search

# How to Use

Instructions for building a local container and using it are in the *Quick and
Easy* section below.  Details on how to configure things are below.

## Quick Setup

Build the container image with the name expected by the launcher script,
`research-support`, and launch the container.  Replace
`/path/to/map/into/container` with the desired path.

``` shell
$ docker build -t research-support .
$ ./launch-container /path/to/map/into/container
```

Exit the container's shell (`exit` or `Ctrl+D`) to shutdown the container.

The container is run as a non-privileged user (`user`) with UID and GID of
`501` and `20` (the first user and `staff` group in macOS).  See below to
build the container with a customized user.

## Customization

The defaults are setup so that the container image is compatible with the first
user and `staff` group on macOS, which may not match the system launching the
research support container.  The container's user's UID and GID are configurable
during the image build process, exposed via the `UID` and `GID` build variables.
Changing them is as simple as:

``` shell
# customize the default user to use UID/GID 1001.
$ docker build -t research-support \
               --build-arg UID=1001 \
               --build-arg GID=1001 \
               .
```

While this tool is not intended for multiple users, the image layers are
arranged so that the user customization is done last so that all intermediate
layers can be shared.  This allows for multiple images, each providing a unique
user configuration, without needlessly wasting disk space.

# Design Decisions

There are many ways to develop on an macOS system.  The sections below attempt
to capture some of the design decisions that influenced why this approach was
taken.

## Flexible Support

I want to do research with the tools, not fight to configure and integrate them
into my workflow.  The approach taken should extent the development environment
in a seamless-as-possible manner.

Being able to integrate new and custom tools into the support environment must
be supported.  While larger package managers provide this capability, it isn't
always well integrated into the system (e.g. Homebrew) or quickly tracking new
releases (e.g. MacPorts, Cygwin, etc).  Most package managers do not provide
an easy manner to incorporate relatively unknown software (e.g. a random Github
repository) without having significant skills to integrate it into said
ecosystem.  Translating `tar xvf ... ; ./configure && make && sudo make install`
sequences into a container image build file is straight forward, albeit
requiring some advanced knowledge of building and configuring one's own
software.

## Reproducibility

Reproducibility is a primary motivator for this approach.  Being able to
reconsistute the research environment with minimal fuss is a high priority as is
being able to track its evolution and pedigree.  A container-based approach
satisfies both of those design goals through the image build file.

## Container vs Virtual Machines

The choice between containers or virtualization mostly boils down to ease of
configuration.  Full separation between the host and the support environment is
antithetical to the primary design goal of seamless extension.  Development on
an macOS system already requires privileges for the primary user.

With those things in mind, the decision between containers and virtual machines
is driven by two things: 1) easy of configuration and 2) ease of use.

Containers may be relatively new to some researchers, though once you climb a
relatively flat learning curve, they fit within most workflows and can be
moved between systems with minimal effort.  Providing a wrapper script to launch
containers removes one of the larger hurdles (for some value of large) and
simplifies integrating it into a day-to-day workflow.

Virtual machines have been around for much longer and are likely more familiar,
though require significantly more setup work.  This goes for both automated
approaches (Puppet, Vagrant, Packer, etc) which require non-trivial dependencies
and skills to configure properly, as well as more manual approaches (list of
instructions) which are error-prone and time intensive.

Last, but not least, running virtual machines on Apple's silicon is in a nacent
state when this was setup (summer 2021).  Virtual Box does not support ARM and
Parallels is commercial software.  Docker Desktop has supported Apple silicon
for nearly six months and is stable.

## Docker vs Other Container Runtimes

While there may be other container runtimes available on macOS, they aren't
nearly as ubiquitous as Docker is.  While Docker requires privileges to execute,
this is not a huge issue for those developing on macOS to begin with as users
typically have administrative privileges.

That said, it is trivial to support other container runtimes by updating the
following:

1. Change the build command from `docker build` as appropriate.
2. Supply an alternative launcher command to the `launch-container.sh` script
   via the `-l <launcher>` option.
