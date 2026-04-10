/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process DEACON_UNION {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'biocontainers/deacon:0.13.2--h7ef3eeb_1' }"

    input:
    tuple val(meta), path(indexes)

    output:
    tuple val(meta), path("*.idx"), emit: index
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    deacon \\
        index \\
        union \\
        $args \\
        $indexes > ${prefix}.idx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.idx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """
}
