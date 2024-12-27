# Use Node.js base image
FROM node:18

# Install PM2 globally
RUN npm install pm2 -g

# Set working directory
WORKDIR /app

# Install necessary tools and download code from S3
RUN apt-get update && apt-get install -y curl unzip && \
  curl -o /tmp/code.zip "https://abhijeettestingbucket23.s3.ap-south-1.amazonaws.com/loan-management-system3443.zip?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGcaCmFwLXNvdXRoLTEiSDBGAiEA9Xqh6nzsmmdp4tn9FtguJm57t4PFaJj%2B9PdfoqUxUSoCIQDc1HvAXT%2BTMLb778s2P32WtiJcGhAL4oCS%2FFGLezvo3irgAwhAEAEaDDUxNDgwMjE3NDk2NSIMl6OPx8f0cksVkModKr0DbN21qlqXzTyWKn4aofybDlB%2FZP70wVDsJrp5gq6nkkhLUSPdWZp2lqkSXxKeEE3rxeO28tIybJXP%2BqwXGmCEbpC2IuEKRp5rGo7%2B1gDuI248MPN4fvGhv3ixxQEBKyKZ7n0dfPJ8%2FZ%2B4xnZ%2F5oxpz2TNpFcJ5HEMZNcmszd3V5Flxpk%2FeaB%2F36NGqpd2tWMDoOokkOaTogF0uzmwyOpIHMJ6KBzir5uFL7s%2BUZ1DLXbEM%2FLjHeRPOyZ3UcgqNNb0u69Bs0a71WyisykL1UL1YgwmWOHIkBMwqoCE0fsHX%2FnO2KFgVA0q%2B76kpmmqkvndkq7udpN2r22MBJiO7rhGaeQrGr7lV6RhZHhYOmTFJYm9ZRO8yN3XTFnP7s%2FrZANMJOuMj4HBnHIkw%2BrQEL1HS9%2FJrRBoihZLvq8Wkh3Nm7EZ%2B4ZjONH4kKpVSuSmeARG3Ap6x5aG3u4G9wFyWLY6AvikSLVaE878Q2iiyGioJoOt%2BUq988vJd27ipUa2c5ZoQ8gwxcl9m7jACyZLNkxNl9Tv1067M7r00YbSZmbcfse6z%2BSPGoCDTiv7MDrzHHrs5Piv%2BwyzRooGK%2BqetjDLoLm7BjrjAt%2BKWgCOxaE9rmzw0sdDCfRb%2BcTe2hx7%2BfybQz6cP0XryLAJb6dw06GpECuZRo%2FnKfq5TLbv66Mw5RX6QNiPcuB63rNhkQMsq8ZZS2JFUf6ZvYtiNrhb2z0eqNTWrPdGBrRwERIVVi1hX%2BIfJ7PVA5%2B%2FZrsXcVnUwQk%2FYJYk7z38TOyCam%2BC4THXHcyzuEr2kr0jLXOfljj4d3l3Te8jBhqZy%2FoRUf%2B8tXKXAT5iSyXjP%2F4P0Z7KnAvK%2FmSmIvF4a02jKM9C5K2rtbM%2BNte%2Fv96M6YcFjyomz1XC9mUFXtQhZpfJYD9dxrIorZTChJNxZpQ%2Bok%2FaxX4AlyyoMZxBMrPoVkqVzcMnB3UsAkUctcBBByy9rOek%2BhOJpsD6QJyDwujJGRe6eGFj7yuFuAbYYtHZz95QMD1OCUl%2FpAScP674yAS4E4dFlGSqtXboJ8xrndbe9SjRgpN50i2QrZdVdUUufY0%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXPXEZZP2UYON5VVW%2F20241227%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20241227T070212Z&X-Amz-Expires=43200&X-Amz-SignedHeaders=host&X-Amz-Signature=b0fa1ae122cc4b83f37fb37a1a7ee32520db2a36a64b68fc4941b2ec28707357" && \
  unzip /tmp/code.zip -d /app && rm /tmp/code.zip

# Create a startup script using a clean multiline format
RUN echo '#!/bin/bash\nset -e\n\nredis_password="testing"\n\n# Navigate to application directory\ncd /app/loan-management-system3443 || exit 1\n\n# Install dependencies and build applications\nif [ -d "./exchange-engine" ]; then\n  cd exchange-engine\n  echo "Installing and building exchange-engine..."\n  npm install && npm run build\n  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-engine"\n  cd ..\nelse\n  echo "Warning: exchange-engine directory not found!"\nfi\n\nif [ -d "./exchange-surface" ]; then\n  cd exchange-surface\n  echo "Installing and building exchange-surface..."\n  npm install && npm run publish\n  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-surface"\n  cd ..\nelse\n  echo "Warning: exchange-surface directory not found!"\nfi\n\n# Update .env files\nupdate_env_file() {\n  local env_file=$1\n  sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|" "$env_file"\n  sed -i "s|REDIS_PORT=.*|REDIS_PORT=6379|" "$env_file"\n  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_password|" "$env_file"\n  sed -i "s|BUILD_FOLDER=.*|BUILD_FOLDER=/app/loan-management-system3443/|" "$env_file"\n}\n\nif [ -f "./exchange-engine/.env" ]; then\n  echo "Updating .env for exchange-engine..."\n  update_env_file "./exchange-engine/.env"\nelse\n  echo "Warning: .env file not found in exchange-engine directory."\nfi\n\nif [ -f "./exchange-surface/.env" ]; then\n  echo "Updating .env for exchange-surface..."\n  update_env_file "./exchange-surface/.env"\nelse\n  echo "Warning: .env file not found in exchange-surface directory."\nfi\n\n# Show logs\npm2 logs' > /app/start-apps.sh

# Make the script executable
RUN chmod +x /app/start-apps.sh

# Expose necessary ports
EXPOSE 8080 5000

# Set the entry point to the shell script
CMD ["/bin/bash", "/app/start-apps.sh"]
