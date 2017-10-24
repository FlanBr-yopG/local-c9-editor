#!/bin/bash

container=c9
image=yopgflanbr-node
version=0.0.17
latest_c9_core_commit=$(git ls-remote git://github.com/c9/core HEAD)

main() {
  cat > Dockerfile <<'EOFdf'
FROM node
ENV NODE_ENV=production
RUN npm i -g npm@4.6.1 # Avoids "Error: Cannot find module 'amd-loader'".
RUN yum -y install git || apt-get -y install git
RUN mkdir /home/node/app; chown node /home/node/app
RUN mkdir /w; chown node /w
USER node
WORKDIR /home/node/app
ARG latest_c9_core_commit
RUN git init; git remote add origin git://github.com/c9/core.git; git fetch origin; \
    git checkout $latest_c9_core_commit; \
    scripts/install-sdk.sh; \
    git reset HEAD --hard;
USER root
RUN npm i -g npm
USER node
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' configs/standalone.js # Stops c9 from forcing authentication.
EXPOSE 8181 # Default.
ENTRYPOINT ["node", "server.js", "-w", "/w", "--listen", "0.0.0.0"]
# CMD ["-a", "user1:pass1", "--debug"]
CMD ["--debug"]
EOFdf
  set -exu
  local already_image=$(docker images -f=reference="$image:$version" --format '{{.ID}}')
  [[ $already_image ]] && echo "NOTE: Image '$image:$version' already exists; not re-building." \
  || {
    rm -rf tmp &>/dev/null || true ;
    mkdir tmp ; cp Dockerfile tmp/ ;
    local pwd0=$(pwd)
    cd tmp ;
    docker build --rm -t "$image:$version" \
      --build-arg latest_c9_core_commit=$latest_c9_core_commit \
      . \
    ;
    cd "$pwd0"
  }
  local already_running=$(docker ps -f "name=$container" --format '{{.ID}}')
  [[ $already_running ]] && {
    if running_this_version; then
      echo "WARNING: Container '$container' is already running.";
    else
      echo "NOTE: Already running but badly. Stopping and re-running."
      docker rm -f $container
      already_running=''
    fi ;
  }
  local container_exists=$(docker ps -a -f "name=$container" --format '{{.ID}}')
  [[ $already_running ]] || {
    if [[ $container_exists ]] ; then
      echo "WARNING: Container '$container' already exists. Removing it now."
      docker rm -f $container
    fi ;
    echo "NOTE: Not already running. Starting it now."
    docker run -d --name $container -p 8181:8181 \
      -v $(pwd)/../..:/w "$image:$version" \
    ;
  }
}
running_this_version() {
  local what_runs=$(docker ps -a -f "name=$container" --format '{{.Image}}')
  [[ $what_runs == "$image:$version" ]] || {
    echo "NOTE: Already running '$container' container is the wrong version. Updating it from $what_runs to version $version.";
    return 1
  }
}

cd $(dirname $0) && main ;

