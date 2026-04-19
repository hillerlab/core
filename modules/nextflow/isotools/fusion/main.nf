/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_FUSION — Detect gene fusion events using iso-fusion.
    Identifies fusion transcripts by comparing query transcripts against
    a reference genome annotation.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_FUSION {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed)
    tuple val(meta1), path(reference)

    output:
    tuple val(meta), path("*/fusions.bed")       , optional: true, emit: fusion
    tuple val(meta), path("*/fusions.free.bed")  , optional: true, emit: free_fusion
    tuple val(meta), path("*/fusions.tsv")       , optional: true, emit: descriptor
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def queries   = (bed instanceof List) ? bed.join(',') : bed
    """
    iso-fusion \\
        $args \\
        --ref $reference \\
        --query $queries \\
        --threads ${task.cpus} \\
        --prefix ${prefix}

    if [ -f ${prefix}/fusions.fakes.bed ]; then
        cat ${prefix}/fusions.fakes.bed >> ${prefix}/fusions.free.bed
    fi

    if [ -f ${prefix}/fusions.review.bed ]; then
        cat ${prefix}/fusions.review.bed >> ${prefix}/fusions.free.bed
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-fusion: \$( iso-fusion --version | sed 's/iso-fusion //g' )
    END_VERSIONS
    """

    stub:
    def prefix    = task.ext.prefix ?: "${meta.id}_${meta.chr}"
    """
    touch ${prefix}/*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-fusion: \$( iso-fusion --version | sed 's/iso-fusion //g' )
    END_VERSIONS
    """
}
