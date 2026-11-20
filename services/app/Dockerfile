# agentes.chat app on Railway: the upstream image, pinned by digest, with a start script that makes
# the first account claimable only with a secret link (OWNER_CLAIM_SHA256) and keeps odd deploy-form
# values from stopping the server (STANDARD 8.29).
ARG AGENTES_IMAGE=ghcr.io/agentes-chat/agentes:0.1.10@sha256:934922e7e48e2922bf77ab5ee0a5f32c82035dc7632ec7ec3c78fe8b1b14cae6
FROM ${AGENTES_IMAGE}
USER root
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
USER bun
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
