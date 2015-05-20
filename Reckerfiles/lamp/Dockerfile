FROM centos:centos6
ADD _upload /tmp/_upload
ADD container_build.sh /tmp/container_build.sh
ADD container_services.sh /etc/container_services.sh
RUN \
    echo -e "#!/bin/bash\n\
[[ -f /etc/container_services.sh ]] \
    && chmod +x /etc/container_services.sh \
    && /etc/container_services.sh \n\
while true; do sleep 10; done\n\
" > /etc/container_init.sh
RUN \
    chmod +x /etc/container_init.sh /tmp/container_build.sh \
    && /tmp/container_build.sh \
    && /bin/rm /tmp/container_build.sh \
    && /bin/rm -r /tmp/_upload
