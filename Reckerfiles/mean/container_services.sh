#!/bin/bash

# Write here sctript for spawning services in the container
if [[ \
    "${_USERNAME-}" \
    && "${_SSH_PUBLIC_KEY-}" \
    && -f "/home/${_USERNAME-}/.ssh/authorized_keys"
]]; then
    grep -q "${_SSH_PUBLIC_KEY-}" .ssh/authorized_keys >&/dev/null \
    || echo "${_SSH_PUBLIC_KEY//__/ }" \
        >> "/home/${_USERNAME-}/.ssh/authorized_keys"
fi

service sshd start
service mongod start
