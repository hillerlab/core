/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENEPRED_PRUNE — Prune BED/GTF/GFF files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GENEPRED_LINT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/genepred:latest' }"

    input:
    tuple val(meta), path(file)

    output:
    tuple val(meta), path("*.pruned.bed"), emit: bed
    path "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    genepred \\
        lint \\
        $args \\
        --prune \\
        $file > ${prefix}.pruned.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genepred: \$( genepred --version | sed 's/genepred //g' )
    END_VERSIONS
    """

    stub:
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pruned.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genepred: \$( genepred --version | sed 's/genepred //g' )
    END_VERSIONS
    """
}
