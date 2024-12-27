# Use Node.js base image
FROM node:18

# Install PM2 globally
RUN npm install pm2 -g

# Set working directory
WORKDIR /app

# Install necessary tools and download code from S3
RUN apt-get update && apt-get install -y curl unzip && \
  curl -o /tmp/code.zip "https://abhijeettestingbucket23.s3.ap-south-1.amazonaws.com/loan-management-system3443.zip?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGgaCmFwLXNvdXRoLTEiRzBFAiBUSiQh0YniaQSMqi3ylaGOcy39Xn%2F0ZmjziRtK9pwphAIhALwGJB3a5quPvIiP2cclGGS5S7Q%2Bu4zxajida%2F2%2FvRbBKuADCEEQARoMNTE0ODAyMTc0OTY1IgwxEErO1bGo%2FxYdrrAqvQNq7A3s3duHBqRWoq4R7UqFVJWWpydtjrmO14LlbDFPcMtZ58Ipv%2Fj7zvk5tGCpJd8y1aB9dJzVo9ttJheyuAvrsNYbH7uSlfria9%2FD9kqaUF1MBLZW5FTipDG70dHYdTZHKUvYqT3eFvQb2sXCdssa5EBY8vw4sEeA%2BTKZoh4iBLxFgjCiG2WjLgXs6zl7H0CZG4HU9DJALrhppQt7XPmTa%2BgH5USz28zekOcrBejugojR%2F4EtOJPztUA144pFwANqf%2FGmiVcMzRx9b9mE1yvftEWVD8u0Yf03R%2BDTec8y2wGnwmnAB0SA%2B5GeYuvKYYgezruayjvFzg1eD7P2CqRdbUNfeKz90%2FMVujRhFlGduoUtlR4Ok8Dngqx0UpcoiTPjTUhXyZkF0lBYWBdr8qhzpZR7lHSHVG5vtQ%2BlSFKR10hjNcKkwYF%2Ft%2F9nRkwnDJKnYpwuMPaA2vxuEQyMosJkxa83t2cX2biYf%2FKJxEQpMGQ%2BQw7i5Mf%2FR0OZ7nK09ejfELY%2BIt4oww%2F9s3E3rtScEBbg5En7BH%2BRvQc08tXgRNvb92vjZz0YKBiQzYl4WuSvvqs6LPVpEUfm3bwPMMugubsGOuQCiK0JRAX6laGnrAuzQTjraxMpkxCjOCdJuEdIZ86WrrxQv1cebEjN65EshrSmHQSg7dCY3zfGrXzaGZnnO5%2FOdN0XUcPV3QdCSWVxOkeiwGfVcJ4stcXI53iKBE%2FaK314X42kw2v1VK2ZEi4%2FS837mcMOIWlh8DkD%2B6LDWNyle6GZvS%2F0HTzPk4h7svGe9J%2F0cD1zslqNVf77sPJMCrYL6O8T7%2FTFp9v6G%2FoC2coYWW04047122eRw02aqJk3ztBa%2BFoqcb5FkWgNvd%2BglmCchaMdfH1dYzFwX4G0Vh0nRV4QGeizN7hrTK1FxHmNhGD2ZQcCv04IQHtg0KMH%2B9hmtWX6l77dgRW3Vr4W9W%2FluDyN6Q0nG09W65A9pcn3EwvB%2FuC%2Bxuz0NXenGKsf8T3bX7VI0BvG1gUaND9Kdade38ztpVvbRt4oRuc1%2Fvqgjvdd4FtoJ0aoTooSgiJXM0fBhys8hvg%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXPXEZZP2YZDAE76A%2F20241227%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20241227T080027Z&X-Amz-Expires=43200&X-Amz-SignedHeaders=host&X-Amz-Signature=ce465b06697b1ddaa8da47598704098e0d9b24e89d31c18f7b4e5457e67db170" && \
  unzip /tmp/code.zip -d /app && rm /tmp/code.zip

# Create a startup script using a clean multiline format
RUN echo '#!/bin/bash\nset -e\n\nredis_password="nextDefault"\n\n# Navigate to application directory\ncd /app/loan-management-system3443 || exit 1\n\n# Install dependencies and build applications\nif [ -d "./exchange-engine" ]; then\n  cd exchange-engine\n  echo "Installing and building exchange-engine..."\n  npm install && npm run build\n  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-engine"\n  cd ..\nelse\n  echo "Warning: exchange-engine directory not found!"\nfi\n\nif [ -d "./exchange-surface" ]; then\n  cd exchange-surface\n  echo "Installing and building exchange-surface..."\n  npm install && npm run publish\n  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-surface"\n  cd ..\nelse\n  echo "Warning: exchange-surface directory not found!"\nfi\n\n# Update .env files\nupdate_env_file() {\n  local env_file=$1\n  sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|" "$env_file"\n  sed -i "s|REDIS_PORT=.*|REDIS_PORT=6379|" "$env_file"\n  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_password|" "$env_file"\n  sed -i "s|BUILD_FOLDER=.*|BUILD_FOLDER=/app/loan-management-system3443/|" "$env_file"\n}\n\nif [ -f "./exchange-engine/.env" ]; then\n  echo "Updating .env for exchange-engine..."\n  update_env_file "./exchange-engine/.env"\nelse\n  echo "Warning: .env file not found in exchange-engine directory."\nfi\n\nif [ -f "./exchange-surface/.env" ]; then\n  echo "Updating .env for exchange-surface..."\n  update_env_file "./exchange-surface/.env"\nelse\n  echo "Warning: .env file not found in exchange-surface directory."\nfi\n\n# Show logs\npm2 logs' > /app/start-apps.sh

# Make the script executable
RUN chmod +x /app/start-apps.sh

# Expose necessary ports
EXPOSE 8080 5000

# Set the entry point to the shell script
CMD ["/bin/bash", "/app/start-apps.sh"]
