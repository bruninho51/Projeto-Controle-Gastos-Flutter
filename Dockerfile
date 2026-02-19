FROM ghcr.io/cirruslabs/flutter:3.41.1 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

RUN flutter --version
RUN flutter build web --release

FROM nginx:1.28-alpine

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
