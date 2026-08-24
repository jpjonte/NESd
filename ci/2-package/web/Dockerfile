FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
# web build must be copied to /web first
COPY web /usr/share/nginx/html
