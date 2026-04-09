# Dockerfile для локального запуска
FROM node:20-alpine AS builder

RUN npm install -g pnpm
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . ./

# Переменные окружения для сборки (значения из .env.development)
ARG REACT_APP_REDIRECT_URI=http://localhost:3000
ARG REACT_APP_CLIENT_ID=g61164be3dd7521a6511ce97adc6bb
ARG REACT_APP_CLIENT_SECRET=b2828c65b7
ENV REACT_APP_REDIRECT_URI=$REACT_APP_REDIRECT_URI
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID
ENV REACT_APP_CLIENT_SECRET=$REACT_APP_CLIENT_SECRET

RUN pnpm run build

# Образ для запуска
FROM node:20-alpine

RUN npm install -g serve
WORKDIR /app

# Копируем только собранное приложение
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["serve", "-s", "dist", "-l", "3000"]