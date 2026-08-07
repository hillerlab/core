/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQTOOLS_DECODE — Convert BINSEQ back to FASTQ (interleaved).
    Paired files decode to a single interleaved FASTQ; pass `--prefix <p> -f q`
    via ext.args to split mates into separate _R1/_R2 files instead.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQTOOLS_DECODE {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqtools:latest' }"

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), path("${prefix}.fastq")  , optional: true, emit: fastq
    tuple val(meta), path("${prefix}_R1.fq")  , optional: true, emit: fastq_r1
    tuple val(meta), path("${prefix}_R2.fq")  , optional: true, emit: fastq_r2
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def fmt = args.contains('-f') || args.contains('--format') ? '' : '-f q'
    def out = args.contains('--prefix') ? '' : "-o ${prefix}.fastq"
    """
    bqtools \\
        decode \\
        $bins \\
        $fmt \\
        $out \\
        -T $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fastq
    touch ${prefix}_R1.fq
    touch ${prefix}_R2.fq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """
}
