FROM node:16

# Install required packages
RUN apt-get update && \
   apt-get install -y libfuzzy-dev libicu-dev redis-server && \
   rm -rf /var/lib/apt/lists/*

# Move files into place
COPY . /opt/hubot
WORKDIR /opt/hubot

# Create a hubot user
RUN useradd -ms /bin/bash hubot
RUN chown -fR hubot /opt/hubot
USER hubot

# Install dependencies
RUN npm install

ENTRYPOINT ["/bin/sh", "-c", "npm run start"]