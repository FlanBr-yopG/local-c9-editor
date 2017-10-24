FROM node
ENV NODE_ENV=production
RUN npm i -g npm@4.6.1
RUN yum -y install git || apt-get -y install git
RUN mkdir /home/node/app; chown node /home/node/app
RUN mkdir /w; chown node /w
USER node
WORKDIR /home/node/app
RUN git init; git remote add origin git://github.com/c9/core.git; git fetch origin; \
    git checkout e5f6d5c4a801f8b8c76aa7eb212d321785d63612; \
    scripts/install-sdk.sh; \
    git reset HEAD --hard;
USER root
RUN npm i -g npm
USER node
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' configs/standalone.js # Stops c9 from forcing authentication.
ENTRYPOINT ["node", "server.js", "-w", "/w", "--listen", "0.0.0.0"]
# CMD ["-a", "user1:pass1", "--debug"]
CMD ["--debug"]
