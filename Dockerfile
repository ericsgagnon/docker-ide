
ARG VERSION=dev

FROM dpage/pgadmin4:latest         as pgadmin
FROM dbeaver/cloudbeaver:latest    as cloudbeaver       

# build caddy with a handful of useful pluginsny y h
FROM caddy:builder AS caddy-builder

RUN xcaddy build \
    --with github.com/hairyhenderson/caddy-teapot-module \
    --with github.com/abiosoft/caddy-json-schema \
    --with github.com/abiosoft/caddy-yaml \
    --with github.com/abiosoft/caddy-exec \
    --with github.com/caddyserver/replace-response \
    --with github.com/greenpau/caddy-auth-portal

FROM ericsgagnon/ide-base:${VERSION} as base

# SHELL [ "/bin/bash", "-c" ]

# caddy (proxy server) #######################################################
FROM base as caddy-server

COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy
COPY caddy-server/Caddyfile        /etc/caddy/Caddyfile
COPY caddy-server/site/*           /var/www/html/
COPY caddy-server/site/images/*    /var/www/html/images/

COPY caddy-server/caddy-server-run /etc/s6-overlay/s6-rc.d/caddy-server/run
RUN SERVICE_NAME=caddy-server && echo longrun > /etc/s6-overlay/s6-rc.d/${SERVICE_NAME}/type && touch /etc/s6-overlay/s6-rc.d/user/contents.d/${SERVICE_NAME}

EXPOSE 80 443

# rstudio server #############################################################
FROM caddy-server as rstudio
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

COPY rstudio-server/rsession-profile    /etc/rstudio/rsession-profile
COPY rstudio-server/rstudio-server-run  /etc/s6-overlay/s6-rc.d/rstudio-server/run
RUN SERVICE_NAME=rstudio-server && echo longrun > /etc/s6-overlay/s6-rc.d/${SERVICE_NAME}/type && touch /etc/s6-overlay/s6-rc.d/user/contents.d/${SERVICE_NAME}

# code server ################################################################
FROM rstudio as code-server

RUN apt-get update && apt-get upgrade -y \
    && curl -fsSL https://code-server.dev/install.sh | bash -s 
    # && curl -fsSL https://code-server.dev/install.sh | bash -s -- --method=standalone --prefix=/usr/local

COPY code-server/code-server-run  /etc/s6-overlay/s6-rc.d/code-server/run
RUN SERVICE_NAME=code-server && echo longrun > /etc/s6-overlay/s6-rc.d/${SERVICE_NAME}/type && touch /etc/s6-overlay/s6-rc.d/user/contents.d/${SERVICE_NAME}

# ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery
# ENV ITEM_URL=https://marketplace.visualstudio.com/items
# ENV EXTENSIONS_GALLERY='{ "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery", "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index", "itemUrl": "https://marketplace.visualstudio.com/items" }'
# ENV EXTENSIONS_GALLERY='{ "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery", "itemUrl": "https://marketplace.visualstudio.com/items" }'
# https://marketplace.visualstudio.com/_apis/public/gallery
# https://marketplace.visualstudio.com/api/public
# export EXTENSIONS_GALLERY='{"serviceUrl": "https://extensions.coder.com/api"}'

# pgadmin ####################################################################
COPY --from=pgadmin      /pgadmin4            /usr/local/pgadmin4
COPY pgadmin/pgadmin-run    /etc/s6-overlay/s6-rc.d/pgadmin/run
RUN SERVICE_NAME=pgadmin && echo longrun > /etc/s6-overlay/s6-rc.d/${SERVICE_NAME}/type && touch /etc/s6-overlay/s6-rc.d/user/contents.d/${SERVICE_NAME}

RUN cd /usr/local/pgadmin4 \
    && python -m venv venv \
    && . venv/bin/activate \
    && cd venv \
    && wget https://raw.githubusercontent.com/postgres/pgadmin4/master/requirements.txt \
    && pip install -r requirements.txt \
    && pip install gunicorn
# RUN curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg \
#     && sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update' \
#     && apt-get update && apt-get install -y pgadmin4

# cloudbeaver ################################################################

COPY --from=cloudbeaver  /opt/cloudbeaver  /opt/cloudbeaver
COPY --from=cloudbeaver  /opt/java         /opt/java
RUN mkdir -p /etc/skel/.local/share/cloudbeaver
COPY cloudbeaver/cloudbeaver-run /etc/services.d/cloudbeaver/run
COPY cloudbeaver/cloudbeaver-run    /etc/s6-overlay/s6-rc.d/cloudbeaver/run
RUN SERVICE_NAME=cloudbeaver && echo longrun > /etc/s6-overlay/s6-rc.d/${SERVICE_NAME}/type && touch /etc/s6-overlay/s6-rc.d/user/contents.d/${SERVICE_NAME}

