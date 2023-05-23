FROM redis/redis-stack:latest as redisstack
FROM docker.io/bitnami/minideb:bullseye
LABEL maintainer="anyili <anyili0928@gmail.com>"

ENV HOME="/" \
    OS_ARCH="amd64" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    PATH="/opt/bitnami/redis-sentinel/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/lib/redis/modules"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages ca-certificates curl libssl1.1 procps
RUN mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ && \
    COMPONENTS=( \
      "redis-sentinel-7.0.11-1-linux-${OS_ARCH}-debian-11" \
    ) && \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
      fi && \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" && \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done
RUN apt-get autoremove --purge -y curl && \
    apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami

COPY --from=redisstack /opt/redis-stack/lib/*.so ${LD_LIBRARY_PATH}/

COPY rootfs /
RUN /opt/bitnami/scripts/redis-sentinel/postunpack.sh
ENV APP_VERSION="7.0.11" \
    BITNAMI_APP_NAME="redis-sentinel"

EXPOSE 26379

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/redis-sentinel/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/redis-sentinel/run.sh", \
    "--loadmodule", "/usr/lib/redis/modules/redisearch.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisgraph.so", \
    "--loadmodule", "/usr/lib/redis/modules/rejson.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisbloom.so"]
