# Based on instructions from https://git.io/v9FmJ

FROM aleksaubry/swift-apns:3.1.0

ADD ./ /app
WORKDIR /app

# Install PostgreSQL
RUN apt-get update
RUN apt-get install -y libpq-dev

# Build Swift
RUN swift build -c release

ENV PATH /app/.build/release:$PATH

RUN chmod -R a+rwx /app

RUN useradd -m myuser
USER myuser

CMD .build/release/App --env=production --workdir="/app"
