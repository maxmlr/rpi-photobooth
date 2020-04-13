FROM tiangolo/uwsgi-nginx-flask:python3.7

COPY ./boot/api /app
RUN rm -f /app/main.py && ln -s /app/api.py /app.main.py
