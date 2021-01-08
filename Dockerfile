FROM node:lts
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
#RUN apt-get update
#RUN apt-get install stress-ng -y
COPY . .
RUN dd if=/dev/zero of=/usr/src/app/workloads/payload/1GB.zip bs=1024 count=0 seek=1048576
EXPOSE 30005
CMD [ "npm", "start" ]
