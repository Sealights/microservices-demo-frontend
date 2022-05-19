docker build -t frontend .
docker tag frontend:latest 159616352881.dkr.ecr.eu-west-1.amazonaws.com/microservices-demo-frontend:latest
docker push 159616352881.dkr.ecr.eu-west-1.amazonaws.com/microservices-demo-frontend:latest
