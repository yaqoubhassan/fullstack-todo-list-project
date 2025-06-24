#!/bin/bash
echo "Starting Todo List Application..."
docker-compose up --build -d
echo "Application started! Access it at http://localhost"
echo "Run 'docker-compose logs -f' to see logs"