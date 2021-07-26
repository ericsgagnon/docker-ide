
ARG VERSION=dev

FROM ericsgagnon/ide-base:${VERSION} as base

# this may not be necessary but may give insight on source files
ENV WORKSPACE="/tmp/workspace/rstudio-server"
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
    # && wget -O rstudio-server.deb https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb \

# WIP: maybe add shiny-server
# RUN cd /tmp \
#     && export SHINY_SERVER_VERSION=$(wget -qO- https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION) \
#     && wget -O shiny-server.deb "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb" \
#     && apt-get update && apt-get install -y ./shiny-server.deb

COPY rsession-profile /etc/rstudio/rsession-profile

COPY rstudio-server-run /etc/services.d/rstudio-server/run

EXPOSE 8787

EXPOSE 3838






