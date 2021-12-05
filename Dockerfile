FROM python:3

RUN apt-get -y update && apt-get install -y python
RUN apt-get update && apt-get install git

COPY ./code/requirements.txt ./usr/src/app/

WORKDIR /usr/src/app

RUN pip install -r requirements.txt

CMD jupyter-lab --port 8404 --ip 0.0.0.0 --no-browser --allow-root
