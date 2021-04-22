#!/bin/sh
echo "$(hostname -i) $SERVER_NAME"  >> /etc/hosts
echo "This is $SERVER_NAME listening on port $LISTEN_PORT!!" > /usr/share/nginx/html/index.html
exit 0