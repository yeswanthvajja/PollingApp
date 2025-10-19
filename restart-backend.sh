#!/bin/bash

echo "======================================"
echo "Restarting Polling App Backend"
echo "======================================"

# Kill existing Spring Boot process
echo "Stopping existing backend..."
pkill -f "com.polling.PollingApplication"
sleep 2

# Clean and rebuild
echo "Rebuilding application..."
mvn clean compile

# Start the application
echo "Starting backend..."
mvn spring-boot:run
