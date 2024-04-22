# Use the official Node.js 16 image 
FROM node:16  

LABEL Sakura="amulthantharate@gmail.com"

WORKDIR /app

COPY package*.json /app/

RUN npm install

COPY . /app/

EXPOSE 3000

CMD ["npm", "start"]