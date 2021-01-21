FROM python:3.7-slim

RUN pip install --upgrade pip

RUN pip install kfserving>=0.2.1 \
    argparse>=1.4.0 \
    pillow==7.1.0 \
    keras_image_helper==0.0.1

COPY image_transformer.py image_transformer.py 

ENTRYPOINT ["python", "image_transformer.py"]
