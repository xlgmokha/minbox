FROM ruby:2.6-alpine
ENV PACKAGES build-base tzdata
RUN apk update && \
    apk upgrade && \
    apk add $PACKAGES && \
    rm -fr /var/cache/apk/* && \
    apk del build-base
WORKDIR /opt/minbox
EXPOSE 25
VOLUME ["/opt/minbox/tmp"]
RUN gem install minbox
CMD ["minbox", "server", "localhost", "25", "--output=stdout file"]
