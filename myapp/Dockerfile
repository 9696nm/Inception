FROM debian:bookworm

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	bash \
	curl \
	ca-certificates && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /srcs

COPY srcs/ .

RUN chmod +x test.sh

CMD ["./test.sh"]
