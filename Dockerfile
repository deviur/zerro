FROM node:20-alpine

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install pnpm
RUN npm install -g pnpm@10.33.2

# install app dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# add app
COPY . ./

# start app
CMD ["pnpm", "run", "dev", "--", "--host", "0.0.0.0"]
