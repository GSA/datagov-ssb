FROM alpine:3.20 AS tofu

ADD install-opentofu.sh /install-opentofu.sh
RUN chmod +x /install-opentofu.sh
RUN apk add gpg gpg-agent
RUN ./install-opentofu.sh --install-method standalone --install-path / --symlink-path -

## This is your stage:

# Github actions runs on Ubuntu-latest, use the same thing here
FROM ubuntu:24.04
COPY --from=tofu /tofu /bin/tofu

# Install the ca-certificate package and git
RUN apt-get update && apt-get install -y ca-certificates git

# Add the zscaler certificate to the trusted certs
# GSA man-in-the-middles SSL with this root certificate
COPY .docker/zscaler_cert.pem /usr/local/share/ca-certificates/zscaler.crt
RUN update-ca-certificates

WORKDIR /bin
ENTRYPOINT ["/bin/tofu"]
CMD ["help"]
