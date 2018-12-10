# Copyright 2017-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

# For more information on creating a Dockerfile
# https://docs.docker.com/compose/gettingstarted/#step-2-create-a-dockerfile
# https://github.com/awslabs/amazon-sagemaker-examples/master/advanced_functionality/pytorch_extending_our_containers/pytorch_extending_our_containers.ipynb
# SageMaker PyTorch image
FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
# FROM 520713654638.dkr.ecr.us-east-2.amazonaws.com/sagemaker-pytorch:0.4.0-cpu-py3


ARG PYTHON_VERSION=3.6
RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         nginx \
         jq \
         wget \
         git \
         curl \
         vim \
         ca-certificates \
         libjpeg-dev \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*


RUN curl -o ~/miniconda.sh -O  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION numpy pyyaml scipy ipython mkl mkl-include cython typing && \
     # /opt/conda/bin/conda install -y -c pytorch magma-cuda90 && \
     /opt/conda/bin/conda install -y -c pytorch pytorch && \
     /opt/conda/bin/conda clean -ya

ENV PATH /opt/conda/bin:$PATH

RUN pip install sagemaker flask gevent gunicorn

RUN git clone https://github.com/pytorch/fairseq.git && \
    cd fairseq && \
    git checkout 672977c1bc3fd0d37c91ab0a2828c56bbd2b0769 && \
    pip install -r requirements.txt && \
    python setup.py build develop


# Copy workaround script for incorrect hostname
COPY lib/changehostname.c /
COPY lib/start_with_right_hostname.sh /usr/local/bin/start_with_right_hostname.sh
RUN chmod +x /usr/local/bin/start_with_right_hostname.sh


ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE

ENV PATH="/opt/ml/code:${PATH}"

# /opt/ml and all subdirectories are utilized by SageMaker, we use the /code subdirectory to store our user code.
# COPY /fairseq /opt/ml/code
COPY fairseq /opt/ml/code

# this environment variable is used by the SageMaker PyTorch container to determine our user code directory.
# ENV SAGEMAKER_SUBMIT_DIRECTORY /opt/ml/code

# this environment variable is used by the SageMaker PyTorch container to determine our program entry point
# for training and serving.
# For more information: https://github.com/aws/sagemaker-pytorch-container
# ENV SAGEMAKER_PROGRAM sagemaker_translate.py

WORKDIR /opt/ml/code

# ENV SAGEMAKER_SERVING_MODULE sagemaker_translate:main

# ENTRYPOINT ["bash"]

ENTRYPOINT ["bash", "-m", "start_with_right_hostname.sh"]