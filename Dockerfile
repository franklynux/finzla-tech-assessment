FROM python:3.12-slim

WORKDIR /app

COPY server.py .

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

EXPOSE 8000

HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1

CMD ["python", "server.py"]
