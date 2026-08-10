# Stage 1: build k6 with local xk6-judge extension
FROM golang:1.25@sha256:6ca9eb0b32a4bd4e8c98a4a2edf2d7c96f3ea6db6eb4fc254eef6c067cf73bb4 AS builder

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
FROM grafana/k6:latest@sha256:5221b620a4f874faff6e32ba597aa667c058391fe4898b1c6f6377f062c6cdec

COPY --from=builder /k6 /usr/bin/k6

ENTRYPOINT ["k6"]
