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

wait_ns() {
    while ! ( kubectl get pods --namespace "$1" | gawk '{ if ((match($2, /^([0-9]+)\/([0-9]+)$/, c) && c[1] != c[2] && !match($3, /Completed/)) || !match($3, /STATUS|Completed|Running/)) { print ; exit 1 } }' )
    do
        sleep {{.Values.settings.grace_sleep_time}}
    done
}

wait_for_endpoint() {
    local endpoint="${1}"
    local output='--output=jsonpath={.subsets.*.addresses.*.ip}'
    test -n "$(get_resource "${endpoint}" "${output}")"
}

wait_kubecf() {
    sleep {{.Values.settings.grace_sleep_time}}

    # The following is just ./scripts/kubecf-wait.sh but with increased number of retrials to fit HA deployment times.
    source scripts/include/setup.sh

    require_tools kubectl retry

    green "Waiting for the BOSHDeployment to exist"
    RETRIES={{.Values.settings.retries}} DELAY=5 retry get_resource BOSHDeployment/kubecf

    green "Waiting for all deployments to be available"
    RETRIES={{.Values.settings.retries}} DELAY=5 retry check_resource_count deployments
    mapfile -t deployments < <(get_resource deployments)
    RETRIES={{.Values.settings.retries}} DELAY=5 wait_for_condition condition=Available "${deployments[@]}"

    wait_ns {{.Values.namespaces.kubecf}}
}

prepare_kubecf() {
    local checkout="${1}"
    if [ ! -d "kubecf" ]; then
        git clone --recurse-submodules https://github.com/cloudfoundry-incubator/kubecf
    fi

    cd kubecf

    git checkout "${checkout}" -b build
    git submodule update --init --recursive --depth 1

    {{- if not .Values.cap.enabled }}
    make kubecf-bundle

    CHART="output/kubecf-bundle-$(./scripts/version.sh).tgz"

    tar -xvf $CHART -C ./ > /dev/null
    {{- else }}
    helm repo add suse https://kubernetes-charts.suse.com/
    helm repo update
    {{- end }}
}