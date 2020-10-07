FROM node:lts
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
RUN apt-get update
RUN apt-get install stress-ng -y
COPY . .
EXPOSE 30005
CMD [ "npm", "start" ]
