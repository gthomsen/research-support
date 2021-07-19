# default to the latest Ubuntu LTS (21.04) available.
ARG DISTRIBUTION_TAG=hirsute

FROM ubuntu:${DISTRIBUTION_TAG}

# create a generic user that maps to the first user on an OS X installation.
# note that the 'staff' group typically maps to GID 20.
ARG USERNAME=user
ARG UID=501
ARG GID=20

# enable the user to regexp search through PDFs with pdfgrep.
RUN \
    apt-get update && \
    apt install -y pdfgrep && \
    rm -rf /var/lib/apt/lists/*

# add the user with appropriate UID/GID.
#
# NOTE: we do this last, so we benefit from cached layers.  changing the user
#       configuration is more likely than the container's contents.
#
RUN \
    useradd -m -u ${UID} -g ${GID} ${USERNAME}

# run as a non-privileged user.
USER ${USERNAME}

# default to an interactive shell in the user's home directory.
WORKDIR /home/${USERNAME}
ENTRYPOINT ["/bin/bash", "-i"]
