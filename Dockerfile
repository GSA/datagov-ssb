FROM hashicorp/terraform:1.1.5 as upstream

FROM alpine/k8s:1.20.7

COPY --from=upstream /bin/terraform /bin/terraform

RUN apk update
RUN apk upgrade
# Install git so we can use it to grab Terraform modules
RUN apk add --update git

WORKDIR /bin
ENTRYPOINT ["/bin/terraform"]
CMD ["help"]
