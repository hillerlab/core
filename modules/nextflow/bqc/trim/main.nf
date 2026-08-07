/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQC_TRIM — Shorten CBQ reads by position, quality, terminal Ns or poly tails.
    Requires at least one trimming operation via ext.args (e.g. --quality-tail,
    --trim-terminal-n, --poly-g); `bqc trim` refuses to run without one.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQC_TRIM {
    tag "$meta.id"
    label 'custom_process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqc:latest' }"

    input:
    tuple val(meta), path(cbq)

    output:
    tuple val(meta), path("*.trimmed.cbq"), emit: reads
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bqc \\
        trim \\
        $cbq \\
        -o ${prefix}.trimmed.cbq \\
        -T $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqc: \$(bqc --version | sed 's/bqc //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.trimmed.cbq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqc: \$(bqc --version | sed 's/bqc //g')
    END_VERSIONS
    """
}
