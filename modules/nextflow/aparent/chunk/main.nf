/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process APARENT_CHUNK {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/containers/aparent:latest' }"

    input:
    tuple val(meta), path(bed)
    tuple val(meta1), path(genome)

    output:
    tuple val(meta), path("chunks/*.tsv"), optional: true, emit: chunks
    path  "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    """
    aparent chunk \\
        -b $bed \\
        -g $genome \\
        -t $task.cpus \\
        -o ${prefix} \\
        --prefix ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aparent: \$( aparent --version | head -n 1 | sed 's/aparent //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p chunks
    touch chunks/${prefix}.00001.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aparent: \$( aparent --version | head -n 1 | sed 's/aparent //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
