FROM harbor-repo.vmware.com/dockerhub-proxy-cache/library/golang:alpine AS terraform-bundler-build

RUN apk --no-cache add git unzip && \
    git clone https://github.com/hashicorp/terraform && \
    cd terraform/ && \
    git checkout v0.14.11 && \
    cd tools/terraform-bundle/ && \
    go build -o /usr/bin/terraform-bundle
