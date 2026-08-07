/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQTOOLS_SPLIT — Split a BINSEQ file into per-pattern files.
    Patterns come from a pattern file (plain text, FASTA or TSV with alias);
    records matching no pattern land in an unmatched file. Per-pattern output
    files are named after the pattern alias.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQTOOLS_SPLIT {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqtools:latest' }"

    input:
    tuple val(meta), path(bins)
    tuple val(meta1), path(patterns)

    output:
    tuple val(meta), path("${prefix}_split/*"), emit: bins
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    bqtools \\
        split \\
        $bins \\
        --file $patterns \\
        --basepath ${prefix}_split \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_split
    touch ${prefix}_split/unmatched.cbq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """
}
