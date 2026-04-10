/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process ISOTOOLS_NMD {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("nmd/*reads.bed")       , optional: true, emit: reads
    tuple val(meta), path("nmd/*nmd.bed")         , optional: true, emit: nmd
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-nmd \\
        $args \\
        --bed $bed \\
        --threads ${task.cpus} \\
        --prefix ${prefix} \\
        --outdir nmd

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-nmd: \$( iso-nmd --version | sed 's/iso-nmd //g' )
    END_VERSIONS
    """

    stub:
    """
    touch nmd/*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-nmd: \$( iso-nmd --version | sed 's/iso-nmd //g' )
    END_VERSIONS
    """
}
