FROM traefik:v3.1

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

CMD ["traefik"]