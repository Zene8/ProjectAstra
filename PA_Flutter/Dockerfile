FROM cirrusci/flutter:stable as build
WORKDIR /app
COPY pubspec.* ./ 
RUN flutter pub get
COPY . . 
RUN flutter build web --release

FROM nginx:stable-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
