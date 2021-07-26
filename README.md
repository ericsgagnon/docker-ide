# docker-ide

docker image with nvidida's cuda libraries, variety of languages, and using s6 to run a selection of my preferred ide's. 

- code server: https://github.com/cdr/code-server
- rstudio server: https://www.rstudio.com/products/rstudio/#rstudio-server, https://github.com/rocker-org/rocker-versioned2
- shiny server : 
- jupyterlab: 
- cloudbeaver: 
- pgadmin: 

The image has many stages. It is ultimately based on ericsgagnon/buildpack-deps-cuda, which mimics buildpack-deps from nvidia/cudagl. From there ericsgagnon/ide-base has multiple stages: base (unminimizing, adding common os libraries for building, installing s6), databases ()

A rough sequence:  

- nvidia/cudagl: starting point 
- ericsgagnon/buildpack-deps-cuda: mimics buildpack-deps from nvidia/cudagl
- ericsgagnon/ide-base:base: uminimizes, apt-gets common os build libraries, nss wrapper, and installs s6
- ericsgagnon/ide-base:databases: installs popular os db drivers, clients, etc.
- ericsgagnon/ide-base:languages: installs a variety of languages (python, R, java, go), and configures s6 to install others at container start (rust/cargo, node/npm/nvm)
- ericsgagnon/ide-base:final: installs a handful of client tools for working in dev environments (docker, kubectl, helm, rclone, mc, argo, argocd, github cli, tekton, sourcegraph cli)  
- ericsgagnon/ide: 

# Justification  

Why an omnibus ide image? Because containers are a great way to have arbitrarily complex work environemnts and because the individual ide's make up only a very small part of the total space. By using a volume for /home, users can maintain their own environments through upgrades with minimal disruption (usually due to breaking changes in how individual ide's configure themselves).  

