#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Build stage: Install necessary development tools for compilation and installation
FROM postgres:16 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
       git bison \
       build-essential \
       flex \
       postgresql-server-dev-16

RUN git clone https://github.com/apache/age.git && \
cd age && make && make install


# Final stage: Create a final image by copying the files created in the build stage
FROM postgres:16

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    locales git

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_COLLATE=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8

COPY --from=build /usr/lib/postgresql/16/lib/age.so /usr/lib/postgresql/16/lib/
COPY --from=build /usr/share/postgresql/16/extension/age--1.5.0.sql /usr/share/postgresql/16/extension/
COPY --from=build /usr/share/postgresql/16/extension/age.control /usr/share/postgresql/16/extension/
COPY docker-entrypoint-initdb.d/00-create-extension-age.sql /docker-entrypoint-initdb.d/00-create-extension-age.sql


# 安装pgvector
COPY pgvector-master /tmp/pgvector

RUN apt-get update && \
		apt-mark hold locales && \
		apt-get install -y --no-install-recommends build-essential postgresql-server-dev-16 && \
		git clone https://github.com/pgvector/pgvector.git && \
        cd pgvector && \
		make clean && \
		make OPTFLAGS="" && \
		make install && \
		mkdir /usr/share/doc/pgvector && \
		cp LICENSE README.md /usr/share/doc/pgvector && \
		rm -r /tmp/pgvector && \
		apt-get remove -y build-essential postgresql-server-dev-16 && \
		apt-get autoremove -y && \
		apt-mark unhold locales && \
		rm -rf /var/lib/apt/lists/*

CMD ["postgres", "-c", "shared_preload_libraries=age"]