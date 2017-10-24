FROM node
ENV NODE_ENV=production
# Avoid "Error: Cannot find module 'amd-loader'":
RUN npm i -g npm@4.6.1 > /tmp/npm_i_g_npm_4_6_1.log 2>&1
RUN bash -c 'which git || { yum -y install git || apt-get -y install git ; }'
RUN mkdir /home/node/app; chown node /home/node/app
RUN mkdir /w; chown node /w
USER node
WORKDIR /home/node/app
ARG latest_c9_core_commit
RUN git init; git remote add origin git://github.com/c9/core.git; git fetch origin; \
    git checkout $latest_c9_core_commit > /tmp/git_checkout.log 2>&1 ; \
    scripts/install-sdk.sh > /tmp/scripts_install_sdk.log 2>&1 ; \
    git reset HEAD --hard;
USER root
RUN npm i -g npm > /home/node/app/npm_i_g_npm.log 2>&1
USER node
# Stop c9 from forcing authentication:
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' configs/standalone.js
# NOTE: Expose c9 core's default port:
EXPOSE 8181
ENTRYPOINT ["node", "server.js", "-w", "/w", "--listen", "0.0.0.0"]
# CMD ["-a", "user1:pass1", "--debug"]
CMD ["--debug"]
