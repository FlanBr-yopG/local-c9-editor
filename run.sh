#!/bin/bash

container=c9
image=yopgflanbr-node
version=0.0.8

main() {
  cat > Dockerfile <<'EOFdf'
FROM node
ENV NODE_ENV=production
RUN yum -y install git || apt-get -y install git
RUN mkdir /home/node/app
RUN mkdir /w; chown node /w /home/node/app
USER node
WORKDIR /home/node/app
RUN git init; git remote add origin git://github.com/c9/core.git; git fetch origin; \
    git checkout e5f6d5c4a801f8b8c76aa7eb212d321785d63612; \
    scripts/install-sdk.sh
RUN pwd
ENTRYPOINT ["node", "server.js"]
CMD ["-w", "/w"]
EOFdf
  pwd ;
  local already_image=$(docker images -f=reference="$image:$version" --format '{{.ID}}')
  [[ $already_image ]] && echo "NOTE: Image '$image:$version' already exists; not re-building." \
  || {
    rm -rf tmp &>/dev/null || true ;
    mkdir tmp ; cp Dockerfile tmp/ ;
    cd tmp ; docker build --rm -t "$image:$version" . ;
  }
  pwd
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

