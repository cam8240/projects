FROM python:3.11-slim

WORKDIR /app

# Only copy requirements.txt first so Docker can cache this layer
COPY requirements.txt .

# Install dependencies (cached unless requirements.txt changes)
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
