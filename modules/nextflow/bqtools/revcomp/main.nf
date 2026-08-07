/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQTOOLS_REVCOMP — Reverse complement the sequences in a BINSEQ file,
    preserving its format and configuration. Both mates by default; use
    --mate 1|2 via ext.args for one mate only. The output variant is inherited
    from the input file.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQTOOLS_REVCOMP {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqtools:latest' }"

    input:
    tuple val(meta), path(bins)

    output:
    tuple val(meta), path("${prefix}.revcomp.*"), emit: bins
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def ext = (bins instanceof List ? bins[0] : bins).name.tokenize('.').last()
    """
    bqtools \\
        revcomp \\
        $bins \\
        -o ${prefix}.revcomp.${ext} \\
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
    touch ${prefix}.revcomp.cbq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """
}
