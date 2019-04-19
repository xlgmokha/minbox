FROM ruby:2.6-alpine
WORKDIR /opt/minbox
EXPOSE 25
VOLUME ["/opt/minbox/tmp"]
ENV PACKAGES build-base tzdata
RUN apk update && \
    apk upgrade && \
    apk add $PACKAGES && \
    gem install minbox && \
    rm -fr /var/cache/apk/* && \
    apk del build-base
CMD ["minbox", "server", "localhost", "25", "--output=stdout file"]
