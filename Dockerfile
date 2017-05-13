# Based on instructions from
# https://gist.github.com/alexaubry/bea6f9b626e71b48ae6065664748bc97

FROM aleksaubry/swift-docker:xenial-3.0.1

ADD ./ /app
WORKDIR /app

# Install PostgreSQL
RUN apt-get update
RUN apt-get install -y libpq-dev

# Build Swift
RUN swift build --config release

ENV PATH /app/.build/release:$PATH

RUN chmod -R a+w /app && chmod -R 777 /app

RUN useradd -m myuser
USER myuser

CMD .build/release/App --env=production --workdir="/app"
