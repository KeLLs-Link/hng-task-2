# Dockerfile
FROM node:18-alpine

WORKDIR /app

# copy package.json first for caching
COPY package.json package-lock.json* ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
