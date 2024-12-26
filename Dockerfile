# Use Node.js base image
FROM node:18

# Install PM2 globally
RUN npm install pm2 -g

# Set working directory
WORKDIR /app

# Download the zip file from the S3 bucket using the pre-signed URL
RUN apt-get update && apt-get install -y curl unzip && \
    curl -o /tmp/code.zip "https://abhijeettestingbucket2209.s3.ap-south-1.amazonaws.com/loan-management-system3443.zip?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEE8aCmFwLXNvdXRoLTEiRzBFAiEAsuKKN01qx9628P1pFup9jhlZMtepnb1mR6vdoF1cwh8CIAsNuuyPA32UY4OwAPP0vpMxPLL4XwsU5HHqOmks8XBLKuADCCgQARoMNTE0ODAyMTc0OTY1IgyDsj8YQcj9JwRJFKgqvQMlTkY0%2F7XMUq9JNGwtn8zRXIuqdsdSwxQW%2F7krPP0%2FK9U7%2BsuoBJPYNUwQuq7Y4mhQ3c0qOUis0ZBEG%2FJjiuRKC0DLBkVYrnfXiAOrHHfrLIB5MiOVnRYU4Yywm5uBMbE12qsy6i5pI%2FBQsKpcGbwLoVfnYSCAZV2Iv%2Bw2yHPOsXaTQO0KRjCEFMeTriDG2LSvAmxFKhwguuBNI1Y6GkbypKKX3V4J69nn82S3VnaDRgQF%2BYkiEzY42So7GZ36ygVeLbX5%2BEIi3%2BEJOKGhmo78UCF80sglUMt5R9EcT1UDlp4AgXvsXCsHvGwjXkQN6rnCNCM28aDygHgInbZhgCGoC5Alj%2BHLaMcvehqp8KqzZhIuz5UCXWfEZ4BiVgOD16%2BACOa2j1EivT9KfH47AHU788rHHaoxSputyCxJi9nd9BliJllUgcgaX4C8yi6P7z0dd7SYVIa3MqGnqVxGpGVUd7ogDkfTIt8Q%2FjbpmC2L6bcjcSaWFOus8vFBdyovtr0HgU8nlgBDXI8dLjxQM5x7A8%2FDXBDJdKxBlb4Y38kLLXxh13ST3WY%2FGY4E409zEZAfWaaTFRnSVjt%2BCOZ9MKzws7sGOuQCU%2F7LLrsq%2FCRT2NGTbouDccCrl1aPa28vhVFmGg7wnbdlvGX4xoA9Oi8f1P9cE9TYIRD7M2YH%2FDryBnoQghuHDZisSj8S6mqcm4IDf%2B2jXNJ9hmAyQQGsBTVHB2BSskKkFA1nuv6h0G38fToI%2BCc4q44AaQu%2BSwT2xhd%2Fa9dRZbQw4ZUBOjRrhvNwhZ4%2Fecb%2B3%2F75CnJx36qYb7ILJlwxrKR7Fx4bYAvBLc6pFkm5ST9UE18wMSi%2F7p5P7WPwXzkpuobfbkDTs6piwb7CFGfXGkOgsiDzfExMCIHAFoSNn0VB2Xy3z2S9tfz7GxnXVIsx3VQCum55kBfZh%2BJkGo6%2F8pMoeQ7wSNmfOareHRFHF1JR5dU8LxlpEbOQRSNf3dBr0eXfTpmxpYUInGlLwLf9UZ%2FeoblOqTFAX0se7pTsQ3QCaaqU5TlVH7ruq%2FUr%2FuK8yoL89izaFSqj4PJqfmFnjPWxQIk%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXPXEZZP2RTXQENOD%2F20241226%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20241226T063429Z&X-Amz-Expires=32400&X-Amz-SignedHeaders=host&X-Amz-Signature=67e673d7553fb6dcdfea82a597bba2aaf05529b5e58931adc7a19e68cb24445a" && \
    unzip /tmp/code.zip -d /app && rm /tmp/code.zip

# Create a startup script
RUN echo '#!/bin/bash\n\
cd "$(find /app -mindepth 1 -maxdepth 1 -type d)" || exit 1\n\
\n\
# Install dependencies and build applications\n\
if [ -d "./exchange-engine" ]; then\n\
  cd exchange-engine || exit 1\n\
  npm install && npm run build\n\
  pm2 start ecosystem.config.js\n\
  cd - || exit 1\n\
fi\n\
\n\
if [ -d "./exchange-surface" ]; then\n\
  cd exchange-surface || exit 1\n\
  npm install && npm run publish\n\
  pm2 start ecosystem.config.js\n\
  cd - || exit 1\n\
fi\n\
\n\
# Update .env files\n\
update_env_file() {\n\
  local env_file=$1\n\
  sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|" "$env_file"\n\
  sed -i "s|REDIS_PORT=.*|REDIS_PORT=6379|" "$env_file"\n\
  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=|" "$env_file"\n\
  sed -i "s|BUILD_FOLDER=.*|BUILD_FOLDER=/app/loan-management-system3443/|" "$env_file"\n\
}\n\
\n\
if [ -f "./exchange-engine/.env" ]; then\n\
  update_env_file "./exchange-engine/.env"\n\
else\n\
  echo "Warning: .env file not found in exchange-engine directory."\n\
fi\n\
\n\
if [ -f "./exchange-surface/.env" ]; then\n\
  update_env_file "./exchange-surface/.env"\n\
else\n\
  echo "Warning: .env file not found in exchange-surface directory."\n\
fi\n\
\n\
pm2 logs' > /app/start-apps.sh && chmod +x /app/start-apps.sh

# Expose necessary ports
EXPOSE 8080 5000

# Set the entry point to the shell script
CMD ["/bin/bash", "/app/start-apps.sh"]
