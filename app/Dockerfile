FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

FROM node:24-alpine

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build /app/node_modules ./node_modules
COPY package*.json ./
COPY app.js .

USER appuser

EXPOSE 3000

CMD ["node", "app.js"]
