/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process RSYNC_SSH {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '':
        'ghcr.io/hillerlab/rsync_ssh:latest' }"

    input:
    tuple val(meta), path(input)
    val user
    val server
    val target_dir

    output:
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${input.name}"
    """
    ssh \\
    ${user}@${server} \\
    mkdir -p ${target_dir}

    rsync \\
    -av \\
    ${input} \\
    ${user}@${server}:${target_dir}/${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rsync: \$(rsync --version | head -n1 | sed 's/rsync version //g; s/  .*//')
        ssh: \$(ssh --version | sed 's/OpenSSH_//g')
    END_VERSIONS
    """

    stub:
    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rsync: \$(rsync --version | head -n1 | sed 's/rsync version //g; s/  .*//')
        ssh: \$(ssh --version | sed 's/OpenSSH_//g')
    END_VERSIONS
    """
}
