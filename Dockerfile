
ARG VERSION=dev

FROM dpage/pgadmin4:latest         as pgadmin
FROM dbeaver/cloudbeaver:latest    as cloudbeaver       

# build caddy with a handful of useful pluginsny y h
FROM caddy:builder AS caddy-builder

RUN xcaddy build \
    --with github.com/hairyhenderson/caddy-teapot-module \
    --with github.com/abiosoft/caddy-json-schema \
    --with github.com/abiosoft/caddy-yaml \
    --with github.com/caddyserver/replace-response \
    --with github.com/greenpau/caddy-auth-portal

FROM ericsgagnon/ide-base:${VERSION} as base

# SHELL [ "/bin/bash", "-c" ]

# rstudio server #############################################################
FROM base as rstudio
# capture workspace in the image for reference
ENV WORKSPACE="/tmp/workspace/ide"
# Use auth=none by default to use external authentication and (try to) skip logins for each ide
ENV AUTH=none
COPY . ${WORKSPACE}/

# modified from rocker's install_rstudio.sh script
# https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y gdebi-core \
    && cd /tmp \
    && export RSTUDIO_URL=$(wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "https.*server.*bionic.*rstudio-server-.*\.deb" | sort | tail -n 1) \
    && wget -O rstudio-server.deb $RSTUDIO_URL \
    && apt-get install -y ./rstudio-server.deb \
    && mkdir -p /var/run/rstudio-server \
    && chmod 1777 /var/run/rstudio-server

    # && export RSTUDIO_VERSION=$(wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "(?<=rstudio-server-)[0-9]\.[0-9]\.[0-9]+" | sort | tail -n 1) \
    # && export RSTUDIO_DEB_FILE=$(wget -qO - https://rstudio.com/products/rstudio/download-server/debian-ubuntu/ | grep -oP "rstudio-server-.*\.deb" | sort | tail -n 1) \
    # && export RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
    # && export RSTUDIO_URL="https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/${RSTUDIO_DEB_FILE}" \

COPY rstudio-server/rsession-profile    /etc/rstudio/rsession-profile
COPY rstudio-server/rstudio-server-run  /etc/services.d/rstudio-server/run

# code server ################################################################
FROM rstudio as code-server

RUN apt-get update && apt-get upgrade -y \
    && curl -fsSL https://code-server.dev/install.sh | bash -s -- --method=standalone --prefix=/usr/local

COPY code-server/code-server-run /etc/services.d/code-server/run
ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery
ENV ITEM_URL=https://marketplace.visualstudio.com/items
#EXPOSE 8080

# caddy (proxy server) #######################################################
FROM code-server as caddy-server

COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy
COPY caddy-server/caddy-server-run /etc/services.d/caddy-server/run
COPY caddy-server/Caddyfile        /etc/caddy/Caddyfile
COPY caddy-server/site/*           /var/www/html/
COPY caddy-server/site/images/*    /var/www/html/images/

EXPOSE 80 443

# pgadmin ####################################################################

COPY --from=pgadmin      /pgadmin4            /usr/local/pgadmin4
COPY pgadmin/pgadmin-run /etc/services.d/pgadmin/run

RUN cd /usr/local/pgadmin4 \
    && python -m venv venv \
    && . venv/bin/activate \
    && cd venv \
    && wget https://raw.githubusercontent.com/postgres/pgadmin4/master/requirements.txt \
    && pip install -r requirements.txt \
    && pip install gunicorn

# cloudbeaver ################################################################

COPY --from=cloudbeaver  /opt/cloudbeaver  /opt/cloudbeaver
COPY --from=cloudbeaver  /opt/java         /opt/java
RUN mkdir -p /etc/skel/.local/share/cloudbeaver
COPY cloudbeaver/cloudbeaver-run /etc/services.d/cloudbeaver/run


# label-studio ###############################################################

RUN apt-get update \
    && apt-get install -y \
    uwsgi \
    git \
    libxml2-dev \
    libxslt-dev \
    zlib1g-dev \
    uwsgi \
    && python -m venv /opt/label-studio \
    && . /opt/label-studio/bin/activate \
    && pip install --upgrade pip \
    && pip install label-studio

# RUN apt-get update \
#     && apt-get install -y \
#     uwsgi \
#     git \
#     libxml2-dev \
#     libxslt-dev \
#     zlib1g-dev \
#     uwsgi \
#     && mkdir -p /opt/label-studio \
#     && cd /opt/label-studio \
#     && python -m venv env \
#     && . env/bin/activate \
#     && pip install --upgrade pip \
#     && pip install label-studio

# label_studio.core.settings.label_studio
