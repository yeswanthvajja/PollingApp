FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci


COPY . .


ARG VITE_API_URL
ENV VITE_API_URL=http://35.193.17.6:8080/api


RUN npm run build


FROM nginx:1.27-alpine


COPY nginx.conf /etc/nginx/conf.d/default.conf


COPY --from=build /app/dist /usr/share/nginx/html


EXPOSE 80


HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1


CMD ["nginx", "-g", "daemon off;"]
