/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_TRUNCATION_DETECTOR — Detect 3'UTR truncation events using iso-utr.
    Identifies potential 3'UTR truncation sites by comparing query and reference
    transcript annotations.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_TRUNCATION_DETECTOR {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed), path(_1), path(_2)

    output:
    tuple val(meta), path("*.tsv")       , optional: true, emit: descriptor
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-utr \\
        $args \\
        --ref $bed \\
        --query $bed \\
        --threads ${task.cpus} \\
        --prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-utr: \$( iso-utr --version | sed 's/iso-utr //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-utr: \$( iso-utr --version | sed 's/iso-utr //g' )
    END_VERSIONS
    """
}
