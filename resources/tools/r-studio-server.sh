#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
PORT=""
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        -p=*|--port=*) PORT="${arg#*=}" ; shift ;; # TODO Does not allow --port 1234
        *) break ;;
    esac
done

if [ ! -f "/usr/lib/rstudio-server/bin/rserver" ]; then
    echo "Installing RStudio Server. Please wait..."
    cd $RESOURCES_PATH
    conda install -y r-base
    apt-get update
    wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.1335-amd64.deb -O ./rstudio.deb
    # ld library path makes problems
    LD_LIBRARY_PATH="" yes | gdebi --non-interactive ./rstudio.deb
    rm ./rstudio.deb
    # Rstudio Server cannot run via root -> create rstudio user
    # https://support.rstudio.com/hc/en-us/articles/200552306-Getting-Started
    # https://stackoverflow.com/questions/33625593/rstudio-server-unable-to-connect-to-service
    # https://support.rstudio.com/hc/en-us/articles/217027968-Changing-the-system-account-for-RStudio-Server
    useradd -m -d /home/rstudio rstudio
    usermod -aG sudo rstudio
else
    echo "RStudio Server is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    if [ -z "$PORT" ]; then
        read -p "Please provide a port for starting the application: " PORT
    fi

    echo "Starting Rstudio server on port "$PORT
    # Create tool entry for tooling plugin
    echo '{"id": "rstudio-link", "name": "RStudio", "url_path": "/tools/'$PORT'/", "description": "Development environment for R"}' > $HOME/.workspace/tools/rstudio-server.json
    cd $RESOURCES_PATH
    USER=rstudio /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --auth-none=1 --auth-validate-users=0 --www-port $PORT
    sleep 10
fi
