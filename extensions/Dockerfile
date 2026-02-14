# Stage 1: build k6 with local xk6-judge extension
FROM golang:1.26@sha256:c83e68f3ebb6943a2904fa66348867d108119890a2c6a2e6f07b38d0eb6c25c5 AS builder

# Install xk6
ENV PATH="/go/bin:${PATH}"
RUN go install go.k6.io/xk6/cmd/xk6@latest

# Copy our local extensions
COPY xk6-judge ./xk6-judge

# Build custom k6 binary including the local extensions
RUN /go/bin/xk6 build \
    --with xk6-judge=./xk6-judge \
    --output /k6

# Stage 2: minimal runtime image
FROM grafana/k6:latest@sha256:ef816d99a6697f914811f99c09e7481df6989d55dec382e4d4ee49311f812459

COPY --from=builder /k6 /usr/bin/k6

ENTRYPOINT ["k6"]
