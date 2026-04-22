/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_ADAPTER — Detect and optionally remove adapter sequences from
    soft-clipped regions of long-read BAM alignments.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_ADAPTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta1), path(bai)

    output:
    tuple val(meta), path("*.without_adapters.bam"), path("*.bai"), optional: true, emit: files
    tuple val(meta), path("*.without_adapters.bam"),                optional: true, emit: bam
    tuple val(meta), path("*.bai"),                                 optional: true, emit: bai
    path "versions.yml",                                            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-adapter \\
        $args \\
        --threads ${task.cpus} \\
        --out-bam . \\
        $bam 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-adapter: \$( iso-adapter --version | sed 's/iso-adapter //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.without_adapters.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-adapter: \$( iso-adapter --version | sed 's/iso-adapter //g' )
    END_VERSIONS
    """
}
