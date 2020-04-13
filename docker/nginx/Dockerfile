FROM nginx:alpine AS base

LABEL maintainer="mmiller@bromberglab.org"

####################
FROM base AS builder

# install additional package dependencies
# ...

# copy local app
COPY ./app /app

WORKDIR /app

# run setup if required
RUN /bin/sh /app/setup.sh

# build image
FROM base

COPY --from=builder /app /app
COPY --from=builder /usr/local /usr/local

WORKDIR /var/www
