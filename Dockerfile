FROM node:8.9.4
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 30005
CMD [ "npm", "start" ]
