/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PSLTOOLS_SORT — Sort PSL files by chromosome, start, or other criteria.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PSLTOOLS_SORT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/psltools:latest' }"

    input:
    tuple val(meta), path(psl)

    output:
    tuple val(meta), path("*.psl")       , optional: true, emit: psl
    tuple val(meta), path("*.psl.gz")    , optional: true, emit: psl_gz
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    psltools sort \\
        $args \\
        --psl $psl \\
        --out ${prefix}.scores.psl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.psl
    touch ${prefix}.psl.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """
}
