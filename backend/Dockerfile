FROM node:20

# Set the working directory
WORKDIR /app

# Copy only package.json + lock file for install
COPY package*.json ./

# Install deps (inside image)
RUN npm install

# Copy everything else (will be overridden by volume)
COPY . .

# Expose port
EXPOSE 8000

# Use CMD only as fallback (docker-compose overrides this anyway)
CMD ["npm", "run", "dev"]
