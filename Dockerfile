FROM ruby:2.6-alpine
ENV PACKAGES build-base tzdata
WORKDIR /app
RUN apk update && \
    apk upgrade && \
    apk add $PACKAGES && \
    rm -fr /var/cache/apk/* && \
    apk del build-base
RUN gem install minbox
CMD ["minbox", "server", "localhost", "25"]
