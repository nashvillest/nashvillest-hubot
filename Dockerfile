FROM node:24-trixie AS deps
WORKDIR /opt/hubot
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:24-trixie-slim
ENV NODE_ENV=production
WORKDIR /opt/hubot
COPY --from=deps --chown=node:node /opt/hubot/node_modules ./node_modules
COPY --chown=node:node . .
USER node
ENTRYPOINT ["bin/start.sh"]
