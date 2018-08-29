FROM debian:stretch
#######
# ENV #
#######
ENV ODOO_BRANCH=11.0 \
    WKHTMLTOPDF_VERSION=0.12.4 \
    WKHTMLTOPDF_CHECKSUM='049b2cdec9a8254f0ef8ac273afaf54f7e25459a273e27189591edc7d7cf29db' \
    OPENERP_SERVER=/etc/biznavi-server.conf \
    BIZNAVI_SOURCE_DIR=/opt/biznavi \
    ADDONS_DIR=/opt/biznavi/addons \
    BACKUPS_DIR=/opt/biznavi/backups \
    LOGS_DIR=/opt/biznavi/logs \
    BIZNAVI_DATA_DIR=/opt/biznavi/data

################
# dependencies #
################
RUN set -x; \
    apt-get -qq update \
    && apt-get -yqq upgrade \
    && apt-get install -yqq --no-install-recommends \
        python3 ruby-compass \
        fontconfig libfreetype6 libxml2 libxslt1.1 libjpeg62-turbo zlib1g \
        libfreetype6 liblcms2-2 libtiff5 tk tcl libpq5 \
        libldap-2.4-2 libsasl2-2 libx11-6 libxext6 libxrender1 \
        locales-all zlibc \
        bzip2 ca-certificates curl gettext-base git gnupg2 nano \
        openssh-client postgresql-client telnet xz-utils \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 /dev/stdin --no-cache-dir \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -yqq nodejs \
    && apt-get -yqq purge python2.7 \
    && apt-get -yqq autoremove \
    && rm -Rf /var/lib/apt/lists/*

# Special case to get latest Less
RUN ln -s /usr/bin/nodejs /usr/local/bin/node \
    && npm install -g less \
    && rm -Rf ~/.npm /tmp/*

# Special case to get bootstrap-sass, required by Odoo for Sass assets
RUN gem install --no-rdoc --no-ri --no-update-sources bootstrap-sass --version '<4' \
    && rm -Rf ~/.gem /var/lib/gems/*/cache/

# Special case for wkhtmltox
RUN curl -SLo wkhtmltox.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.tar.xz" | sha256sum -c - \
    && tar --strip-components 1 -C /usr/local/ -xf wkhtmltox.tar.xz \
    && rm wkhtmltox.tar.xz \
    && wkhtmltopdf --version

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libevent-dev \
        libjpeg-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        python3-dev \
        zlib1g-dev \
        git \
    && pip install openupgradelib \
    && git clone https://cenoq-dev:28004668@bitbucket.org/cenoq-dev/biznavi5.git $BIZNAVI_SOURCE_DIR \
    && pip install --no-cache-dir -r /opt/biznavi/biznavi_requirements.txt \
    && python3 -m compileall -q /usr/local/lib/python3.5/ || true \
    && apt-get purge -yqq build-essential '*-dev' \
    && apt-mark -qq manual '*' \
    && rm -Rf /var/lib/apt/lists/*

###############################################
# config, scripts, repos, autoinstall modules #
###############################################
COPY install-biznavi-saas.sh /
COPY biznavi.conf $OPENERP_SERVER
COPY odoo-backup.py /usr/local/bin/
COPY reset-admin-passwords.py /
COPY ./biznavi-supervisor.conf /opt/biznavi/
COPY ./biznavi-init.conf /opt/biznavi/
COPY ./biznavi.service /opt/biznavi/

#####################################
# odoo source, user, docker folders #
#####################################
RUN adduser --system --quiet --shell=/bin/bash --group biznavi && \
    chown -R biznavi:biznavi $BIZNAVI_SOURCE_DIR && \
    mkdir -p $BIZNAVI_DATA_DIR && chown biznavi:biznavi $BIZNAVI_DATA_DIR && \
    chown biznavi:biznavi $OPENERP_SERVER && \
    mkdir -p $BACKUPS_DIR && chown biznavi:biznavi $BACKUPS_DIR && \
    mkdir -p $LOGS_DIR && chown biznavi:biznavi $LOGS_DIR

RUN apt-get -qq update && \
    bash -x install-biznavi-saas.sh
# RUN apt-get -qq update && \
#     chmod +x /usr/local/bin/odoo-backup.py && \
#     chown biznavi:biznavi $OPENERP_SERVER && \
#     CLONE_IT_PROJECTS_LLC=yes \
#     CLONE_OCA=yes \
#     INIT_ODOO_CONFIG=docker-container \
#     UPDATE_ADDONS_PATH=yes \
#     ADD_AUTOINSTALL_MODULES="['ir_attachment_force_storage', 'base_session_store_psql']" \
#     ADD_IGNORED_DATABASES="['session_store']" \
#     bash -x install-odoo-saas.sh

########################
# docker configuration #
########################
COPY ./entrypoint.sh /
RUN chown biznavi:biznavi /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8069 8072
USER biznavi
VOLUME ["/opt/biznavi/data", \
       "/opt/biznavi/backups", \
       "/opt/biznavi/logs"]
# /opt/addons/extra is used for manually added addons.
# Expected structure is:
# /opt/addons/extra/REPO_OR_GROUP_NAME/MODULE/__openerp__.py
#
# we don't add /opt/odoo-source, /opt/addons, /opt/config to VOLUME in order to allow modify theirs content in inherited dockers

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/biznavi/odoo-bin"]