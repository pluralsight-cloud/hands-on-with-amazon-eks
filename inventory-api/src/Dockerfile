# FROM node:10
FROM public.ecr.aws/docker/library/node:16-alpine
WORKDIR /usr/src/app
COPY package*.json ./

RUN npm install
COPY . .
EXPOSE 5001
CMD node app.js