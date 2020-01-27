FROM golang:alpine AS terraform-bundler-build

RUN apk --no-cache add git unzip && \
    go get -d -v github.com/hashicorp/terraform && \
    cd src/github.com/hashicorp/terraform/ && \
    git checkout v0.12.18 && \
    cd /go && \
    go install ./src/github.com/hashicorp/terraform/tools/terraform-bundle

COPY terraform-bundle.hcl .

RUN terraform-bundle package -os=linux -arch=amd64 terraform-bundle.hcl && \
    cp *.zip terraform-bundle.zip