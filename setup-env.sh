#!/bin/bash

# Setup script for Taskflow Backend environment variables

echo "🚀 Setting up environment variables for Taskflow Backend..."

# Check if .env file already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Do you want to overwrite it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

# Copy env.example to .env
if [ -f "env.example" ]; then
    cp env.example .env
    echo "✅ Created .env file from env.example"
    echo ""
    echo "📝 Please edit the .env file with your actual values:"
    echo "   - JWT_SECRET: Set a strong secret key for production"
    echo "   - AWS credentials: Use real credentials for production"
    echo "   - Database URL: Set your production database URL"
    echo ""
    echo "🔒 Remember: Never commit the .env file to version control!"
else
    echo "❌ env.example file not found!"
    exit 1
fi

echo "🎉 Environment setup complete!" 