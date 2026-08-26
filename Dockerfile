FROM python:3.12-slim

WORKDIR /app

COPY server.py .

EXPOSE 8000

HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=3)"

CMD ["python", "server.py"]
