FROM ruby:3.3-alpine AS builder

WORKDIR /app

RUN apk add --no-cache bash sqlite-dev

COPY Gemfile ./
RUN bundle install

COPY app.rb ./

FROM ruby:3.3-alpine AS runtime

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/app.rb .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:3000/health || exit 1

CMD ["ruby", "app.rb"]