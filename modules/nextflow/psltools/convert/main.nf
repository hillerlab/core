/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PSLTOOLS_CONVERT — Convert PSL to BED
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PSLTOOLS_CONVERT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/psltools:latest' }"

    input:
    tuple val(meta), path(psl)

    output:
    tuple val(meta), path("*.bed")       , optional: true, emit: bed
    tuple val(meta), path("*.bed.gz")    , optional: true, emit: bed_gz
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def type      = task.ext.type ?: '12'
    def gzip      = task.ext.gzip ? "--gzip" : ""
    """
    psltools convert \\
        $args \\
        $gzip \\
        --psl $psl \\
        --out ${prefix}.bed \\
        --type $type

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bed
    touch ${prefix}.bed.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """
}
