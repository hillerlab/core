/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process APARENT_PREDICT {
    tag "$meta.id $meta.chunk"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '':
        'ghcr.io/hillerlab/containers/aparent:latest' }"

    input:
    tuple val(meta), path(chunk_tsv)
    tuple val(meta1), path(weights)

    output:
    tuple val(meta), path("aparent/*.aparent.bed")          , optional: true, emit: bed
    tuple val(meta), path("aparent/*.aparent.forward.bg")   , optional: true, emit: bg_forward
    tuple val(meta), path("aparent/*.aparent.reverse.bg")   , optional: true, emit: bg_reverse
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.chunk}"
    """
    aparent predict \\
        $args \\
        --bed $chunk_tsv \\
        --outdir aparent \\
        --prefix $prefix \\
        --model $weights

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aparent: \$(aparent --version 2>&1 | sed 's/aparent //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.chunk}"
    """
    mkdir -p aparent
    touch aparent/${prefix}.aparent.forward.bed 
    touch aparent/${prefix}.aparent.reverse.bed
    touch aparent/${prefix}.aparent.bg

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aparent: \$(aparent --version 2>&1 | sed 's/aparent //')
    END_VERSIONS
    """
}
