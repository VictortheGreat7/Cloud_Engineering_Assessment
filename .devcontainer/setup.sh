#!/bin/bash

echo "🚀 Setting up World Clock Application development environment..."

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend && pip install -r requirements.txt && cd ..

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend && npm install && cd ..

# Install kubelogin for AKS authentication
echo "🔐 Installing kubelogin..."
curl -LO https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
rm -rf bin kubelogin-linux-amd64.zip

echo "✅ Development environment setup complete!"
echo ""
echo "📝 Quick Start:"
echo "  - Run backend:  cd backend && python app.py"
echo "  - Run frontend: cd frontend && npm run dev"
echo "  - Build Docker: docker build -t <image-name> <directory>"
echo ""
echo "🌍 Happy coding!"
