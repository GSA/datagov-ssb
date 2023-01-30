FROM hashicorp/terraform:1.1.5 as upstream

RUN apk update
RUN apk upgrade
# Install git so we can use it to grab Terraform modules
RUN apk add --update git

WORKDIR /bin
ENTRYPOINT ["/bin/terraform"]
CMD ["help"]
