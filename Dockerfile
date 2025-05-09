# Build stage: Install necessary development tools for compilation and installation
FROM postgres:16 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
       git ca-certificates bison \
       build-essential \
       flex \
       postgresql-server-dev-16

RUN git clone https://github.com/apache/age.git && \
cd age && make && make install


# Final stage: Create a final image by copying the files created in the build stage
FROM postgres:16

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    locales git ca-certificates

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
		rm -r ../pgvector && \
		apt-get remove -y build-essential postgresql-server-dev-16 && \
		apt-get autoremove -y && \
		apt-mark unhold locales && \
		rm -rf /var/lib/apt/lists/*

CMD ["postgres", "-c", "shared_preload_libraries=age"]
