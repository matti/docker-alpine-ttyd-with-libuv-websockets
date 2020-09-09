FROM alpine:3.12 as builder

RUN apk add --no-cache sudo
ENV PACKAGER="Robot <robot@mailinator.com" \
  USERNAME="packager"

RUN apk update && apk --no-cache add \
  alpine-sdk

RUN adduser -g abuild --disabled-password $USERNAME
RUN echo "$USERNAME:$USERNAME" | chpasswd
RUN echo "$USERNAME     ALL=(ALL) ALL" > /etc/sudoers
RUN echo 'PACKAGER="$PACKAGER"' > /etc/abuild.conf

RUN addgroup $USERNAME abuild

RUN mkdir -p /var/cache/distfiles
RUN chmod a+w /var/cache/distfiles
RUN chgrp abuild /var/cache/distfiles
RUN chmod g+w /var/cache/distfiles
RUN chmod 777 /home/packager

COPY app /app
RUN chown $USERNAME -R /app

# ---
COPY --from=mattipaksula/alpine-libwebsockets-with-libuv:3.12 / /tmp
RUN apk add /tmp/libwebsockets-4.0.20-r0.apk --allow-untrusted
RUN apk add /tmp/libwebsockets-dev-4.0.20-r0.apk --allow-untrusted
# ---

WORKDIR /app
USER $USERNAME
RUN abuild-keygen -a -i
RUN abuild -r

RUN ls /home/packager/packages/x86_64
FROM scratch
COPY --from=builder /home/packager/packages/x86_64 /
