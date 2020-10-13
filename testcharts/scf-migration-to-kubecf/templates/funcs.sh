#!/bin/bash


get_resource() {
    kubectl get --output=name --namespace={{.Values.namespaces.kubecf}} "${@}"
}

check_resource_count() {
    local resource="${1}"
    test -n "$(get_resource "${resource}")"
}

check_qjob_ready() {
    local qjob="QuarksJob/${1}"
    local output='--output=jsonpath={.status.completed}'
    test true == "$(get_resource "${qjob}" "${output}")"
}

wait_for_condition() {
    local condition="${1}"
    shift
    local resource
    for resource in "${@}" ; do
        retry kubectl wait --for="${condition}" --namespace={{.Values.namespaces.kubecf}} --timeout=600s "${resource}"
    done
}

function wait_ns {
    while ! ( kubectl get pods --namespace "$1" | gawk '{ if ((match($2, /^([0-9]+)\/([0-9]+)$/, c) && c[1] != c[2] && !match($3, /Completed/)) || !match($3, /STATUS|Completed|Running/)) { print ; exit 1 } }' )
    do
        sleep 10
    done
}

wait_for_endpoint() {
    local endpoint="${1}"
    local output='--output=jsonpath={.subsets.*.addresses.*.ip}'
    test -n "$(get_resource "${endpoint}" "${output}")"
}