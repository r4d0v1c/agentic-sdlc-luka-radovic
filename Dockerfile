FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir pytest==8.3.5

COPY src/ src/
COPY tests/ tests/

CMD ["pytest", "tests/", "-v", "--tb=short"]
