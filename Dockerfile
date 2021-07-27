
ARG VERSION=dev

FROM ericsgagnon/ide-base:${VERSION} as base

# rstudio server #############################################################
FROM base as rstudio
# capture workspace in the image for reference
ENV WORKSPACE="/tmp/workspace/ide"
COPY . ${WORKSPACE}/

# modified from rocker's install_rstudio.sh script
# https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y gdebi-core \
    && cd /tmp \
    && export RSTUDIO_VERSION=$(wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "(?<=rstudio-server-)[0-9]\.[0-9]\.[0-9]+" | sort | tail -n 1) \
    && export RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
    && wget -O rstudio-server.deb $RSTUDIO_URL \
    && apt-get install -y ./rstudio-server.deb

COPY rstudio-server/rsession-profile    /etc/rstudio/rsession-profile
COPY rstudio-server/rstudio-server-run  /etc/services.d/rstudio-server/run
EXPOSE 8787

# FROM rstudio as shiny

# WIP: maybe add shiny-server
# RUN cd /tmp \
#     && export SHINY_SERVER_VERSION=$(wget -qO- https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION) \
#     && wget -O shiny-server.deb "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb" \
#     && apt-get update && apt-get install -y ./shiny-server.deb
# EXPOSE 3838

# code server ################################################################
FROM rstudio as code-server

RUN apt-get update && apt-get upgrade -y \
    && curl -fsSL https://code-server.dev/install.sh | bash -s -- --method=standalone --prefix=/usr/local

COPY code-server/code-server-run /etc/services.d/code-server/run
ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery
ENV ITEM_URL=https://marketplace.visualstudio.com/items
EXPOSE 8080

# caddy (proxy server) #######################################################
RUN apt-get update \
    && apt-get install -y \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update \
    && apt-get install -y caddy

COPY caddy-server/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 443

