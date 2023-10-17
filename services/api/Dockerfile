# a dockerfile for a fastapi server

# Use the official Python image.
# https://hub.docker.com/_/python
FROM python:3.8-slim

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
ARG COMMITHASH
ENV COMMITHASH=$COMMITHASH
COPY requirements.txt ./

# Install production dependencies.
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . ./

# Run the fastapi service
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4000"]