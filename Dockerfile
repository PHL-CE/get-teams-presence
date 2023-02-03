# syntax=docker/dockerfile:1

FROM python:3.10

ARG client_id
ARG email
ARG sb_conn_string
ARG queue_name

WORKDIR /gtp

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN cd $VIRTUAL_ENV \
    && git clone https://github.com/RPi-Distro/RTIMULib/ RTIMU \
    && cd RTIMU/Linux/python \
    && python setup.py build \
    && python setup.py install \
    && apt install libopenjp2-7

COPY ./python .

RUN apt-get update 
RUN apt-get -y install cmake
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

ENV client_id=$client_id
ENV email=$email
ENV sb_conn_string=$sb_conn_string
ENV queue_name=$queue_name

CMD ["python3", "get-teams-presence.py"]