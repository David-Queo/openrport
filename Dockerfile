# Build rportd. go-sqlite3 requires CGO (unlike `make build`, which sets CGO_ENABLED=0).
FROM golang:1.19-alpine AS builder

RUN apk add --no-cache git gcc musl-dev sqlite-dev

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=1
RUN go build -ldflags "-s -w" -o /out/rportd -v ./cmd/rportd \
	&& /out/rportd --version

FROM alpine:3.19

RUN apk add --no-cache ca-certificates sqlite-libs \
	&& adduser -D -H -u 1000 -g "rport" rport \
	&& mkdir -p /var/lib/rport /var/log/rport \
	&& chown -R rport:rport /var/lib/rport /var/log/rport

COPY --from=builder /out/rportd /usr/local/bin/rportd

USER rport
WORKDIR /var/lib/rport

# Agents / API ports are set in rportd.conf; common defaults exposed for docs.
EXPOSE 8080 3000

ENTRYPOINT ["rportd"]
CMD ["-c", "/etc/rportd.conf"]
