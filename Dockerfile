FROM python:3.10-slim

WORKDIR /app

COPY . .

RUN pip install Flask==2.3.2

EXPOSE 5000

CMD ["python", "app.py"]
