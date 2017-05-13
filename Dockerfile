FROM aleksaubry/swift-docker:xenial-3.0.1

ADD ./ /app
WORKDIR /app

RUN swift build --config release

ENV PATH /app/.build/release:$PATH

RUN chmod -R a+w /app && chmod -R 777 /app

RUN useradd -m myuser
USER myuser

CMD .build/release/App --env=production --workdir="/app"
