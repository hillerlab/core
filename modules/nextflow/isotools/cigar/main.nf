/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_CIGAR — Rescuing missed 3' splice junctions by CIGAR matching.
    Additional arguments may change results  (--clip-cutoff {}, -E {} and --wiggle {}).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_CIGAR {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta1), path(bai)
    tuple val(meta2), path(genome)
    tuple val(meta3), path(annotation)

    output:
    tuple val(meta), path("*.align.bam"), path("*.align.bam.bai"),        optional: true, emit: aligned
    tuple val(meta), path("*.extended.bam"), path("*.extended.bam.bai"),  optional: true, emit: extended
    path "versions.yml",                                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    """
    iso-cigar \\
        $args \\
        --bam $bam \\
        --annotation $annotation \\
        --sequence $genome \\
        --split-bam \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-cigar: \$( iso-cigar --version | sed 's/iso-cigar //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-cigar: \$( iso-cigar --version | sed 's/iso-cigar //g' )
    END_VERSIONS
    """
}
