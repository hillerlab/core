/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PSLTOOLS_STATS — Get statistics about PSL files.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PSLTOOLS_STATS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/psltools:latest' }"

    input:
    tuple val(meta), path(psl)

    output:
    tuple val(meta), path("*.json")       , optional: true, emit: json
    tuple val(meta), path("*.tsv")        , optional: true, emit: tsv
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--json") ? ".json" : ".tsv"
    """
    psltools stats \\
        $args \\
        --psl $psl \\
        > ${prefix}.stats$extension

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.stats.tsv
    touch ${prefix}.stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        psltools: \$( psltools --version | sed 's/psltools //g' )
    END_VERSIONS
    """
}
