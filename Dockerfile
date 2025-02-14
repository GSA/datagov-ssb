FROM hashicorp/terraform:1.1.5 AS upstream

# Github actions runs on Ubuntu-latest, use the same thing here
FROM ubuntu:24.04
COPY --from=upstream /bin/terraform /bin/terraform


# Install the ca-certificate package and git
RUN apt-get update && apt-get install -y ca-certificates git

# Add the zscaler certificate to the trusted certs
# GSA man-in-the-middles SSL with this root certificate
COPY .docker/zscaler_cert.pem /usr/local/share/ca-certificates/zscaler.crt
RUN update-ca-certificates

WORKDIR /bin
ENTRYPOINT ["/bin/terraform"]
CMD ["help"]
