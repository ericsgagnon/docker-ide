
ARG VERSION=dev

FROM dpage/pgadmin4:latest as pgadmin

# build caddy with a handful of useful plugins
FROM caddy:builder AS caddy-builder

RUN xcaddy build \
    --with github.com/hairyhenderson/caddy-teapot-module \
    --with github.com/abiosoft/caddy-json-schema \
    --with github.com/abiosoft/caddy-yaml \
    --with github.com/caddyserver/replace-response \
    --with github.com/greenpau/caddy-auth-portal

FROM ericsgagnon/ide-base:${VERSION} as base

# rstudio server #############################################################
FROM base as rstudio
# capture workspace in the image for reference
ENV WORKSPACE="/tmp/workspace/ide"
# Use auth=none by default to use external authentication and skip logins for each ide
ENV AUTH=none
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
FROM code-server as caddy-server

# RUN apt-get update \
#     && apt-get install -y \
#     debian-keyring \
#     debian-archive-keyring \
#     apt-transport-https \
#     && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc \
#     && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
#     && apt-get update \
#     && apt-get install -y caddy

COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy
COPY caddy-server/caddy-server-run /etc/services.d/caddy-server/run
COPY caddy-server/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80 443

# pgadmin ####################################################################

# Install the public key for the repository (if not done previously):
RUN curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add \
    && echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list \
    && apt-get update \
    && apt-get install -y \
    pgadmin4 \
    pgadmin4-web \
    gunicorn

# https://raw.githubusercontent.com/postgres/pgadmin4/master/requirements.txt

# RUN mkdir /usr/local/pgadmin4 \
#     && cd /usr/local/pgadmin4 \
#     && python -m venv /usr/local/pgadmin4 \
#     && source bin/activate \
#     && pip install \
#     pgadmin4 \
#     gunicorn 
 
RUN mkdir /usr/local/pgsql
COPY --from=pgadmin      /usr/local/pgsql-13  /usr/local/pgsql/pgsql-13
COPY --from=pgadmin      /usr/local/pgsql-12  /usr/local/pgsql/pgsql-12
COPY --from=pgadmin      /usr/local/pgsql-11  /usr/local/pgsql/pgsql-11
COPY --from=pgadmin      /usr/local/pgsql-10  /usr/local/pgsql/pgsql-10
COPY --from=pgadmin      /usr/local/pgsql-9.6 /usr/local/pgsql/pgsql-9.6

# /usr/pgadmin4/venv/bin/python3 /usr/pgadmin4/web/setup.py
# mkdir -p /var/log/pgadmin /var/lib/pgadmin

# ENV PATH=/usr/pgadmin4/bin:${PATH}

# EXPOSE 5050

# Configure the webserver, if you installed pgadmin4-web:
# /usr/pgadmin4/bin/setup-web.sh

COPY --from=dpage/pgadmin4:latest /pgadmin4       /pgadmin4
COPY --from=dpage/pgadmin4:latest /venv           /venv
# COPY --from=dpage/pgadmin4:latest /entrypoint.sh  /usr/local/pgadmin/entrypoint.sh
# COPY --from=dpage/pgadmin4:latest /pgadmin4       /usr/local/pgadmin/pgadmin4
# COPY --from=dpage/pgadmin4:latest /venv           /usr/local/pgadmin/venv
# COPY --from=dpage/pgadmin4:latest /entrypoint.sh  /usr/local/pgadmin/entrypoint.sh

# RUN /usr/local/pgadmin/venv/bin/python3 -m pip install --no-cache-dir gunicorn 

# RUN cd /usr/local \
#     && python -m pip install --upgrade pip \
#     && python -m venv pgadmin \
#     && source pgadmin4/bin/activate \
#     && 
#     && git clone https://github.com/postgres/pgadmin4 \
#     && 
#     && python -m venv --system-site-packages --without-pip venv \
# /usr/local/pgadmin4/venv/bin/python -m pip install --upgrade pip
# --no-cache-dir -r ./requirements.txt 

python3 -m venv --system-site-packages --without-pip / && \
/venv/bin/python3 -m pip install --no-cache-dir -r requirements.txt

git clone https://github.com/postgres/pgadmin4

cd /usr/local/pgadmin4 \
&& python -m venv venv \
&& source venv/bin/activate \
&& cd venv \
&& wget https://raw.githubusercontent.com/postgres/pgadmin4/master/requirements.txt \
&& pip install -r requirements.txt \
&& pip install gunicorn \
&& cd /usr/local/pgadmin4 \
&& /usr/local/pgadmin4/venv/bin/gunicorn \
--timeout 86400 \
--bind 0.0.0.0:5050 \
-e SCRIPT_NAME=/pgadmin \
--pythonpath=/usr/local/pgadmin4 \
-w 1 \
--threads 25 \
--access-logfile - \
-c gunicorn_config.py \
run_pgadmin:app


/venv/bin/gunicorn --timeout 86400 --bind 0.0.0.0:5050 -w 1 --threads 25 --access-logfile - -c gunicorn_config.py run_pgadmin:app

su - liveware
sudo mkdir /var/lib/pgadmin
sudo mkdir /var/log/pgadmin
sudo chown -R liveware:liveware /var/log/pgadmin
sudo chown -R liveware:liveware /var/lib/pgadmin
sudo chown liveware:liveware /pgadmin4/config_distro.py

export PGADMIN_SETUP_EMAIL='admin@example.com'
export PGADMIN_SETUP_PASSWORD='password'
/venv/bin/python3 run_pgadmin.py
cd /pgadmin4 && /venv/bin/gunicorn --timeout 86400 --bind 0.0.0.0:5050 -w 1 --threads 25 --access-logfile - -c gunicorn_config.py run_pgadmin:app

# jupyterlab #################################################################

# cloudbeaver ################################################################


# apt-get update \
# && apt-get install -y \
# debian-keyring \
# debian-archive-keyring \
# apt-transport-https \
# && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | apt-key add - \
# && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-xcaddy.list \
# && apt-get update \
# && apt-get install -y xcaddy

# https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fgreenpau%2Fcaddy-auth-jwt&p=github.com%2Fcaddyserver%2Fjsonc-adapter&p=github.com%2Fmholt%2Fcaddy-l4&p=github.com%2Fcaddyserver%2Freplace-response&idempotency=87871957022723



# nginx for it's wsgi for pgadmin4
# curl -1sLf  "https://nginx.org/keys/nginx_signing.key" | apt-key add - \
# && echo "deb https://nginx.org/packages/mainline/ubuntu/ focal nginx" > /etc/apt/sources.list.d/nginx.list \
# && echo "deb-src https://nginx.org/packages/mainline/ubuntu/ focal nginx" >> /etc/apt/sources.list.d/nginx.list \
# && apt-get update \
# && apt-get install -y nginx 

# # ...or... just use gunicorn?
# apt-get update \
# && apt-get install -y gunicorn \

# {gunicorn} /venv/bin/python3 /venv/bin/gunicorn --timeout 86400 --bind [::]:80 -w 1 --threads 25 --access-logfile - -c gunicorn_config.py run_pgadmin:app


