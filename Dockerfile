FROM odoo:16.0
#FROM odoo:17.0

ARG DEV_MODE
ENV PIPENV_ARG=${DEV_MODE:+--dev}

# Install system libs
USER root
RUN apt update
RUN apt install -y git

# Install packages
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3
RUN pip install --upgrade pip
RUN pip install pipenv
COPY ./Pipfile ./Pipfile
COPY ./Pipfile.lock ./Pipfile.lock
RUN pipenv install --system --deploy --ignore-pipfile $PIPENV_ARG

USER odoo