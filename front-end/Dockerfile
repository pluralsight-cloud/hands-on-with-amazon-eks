# FROM node:carbon-alpine
FROM public.ecr.aws/docker/library/node:10-alpine
WORKDIR /opt/forms
COPY package*.json ./
RUN npm install
COPY . ./
RUN npm run build

# FROM nginx:1.25-alpine
FROM public.ecr.aws/nginx/nginx:1.25
COPY --from=0 /opt/forms/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
