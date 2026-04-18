/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_ORPHAN — Identify orphan transcripts using iso-orphan.
    Finds transcripts in the query that do not overlap with any reference
    transcript and separates them from matched transcripts.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_ORPHAN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed)
    tuple val(meta1), path(reference)
    tupel val(meta2), path(splice_scores)

    output:
    tuple val(meta), path("*/*.hq.bed")             , optional: true, emit: hq
    tuple val(meta_scraps), path("*/*.scraps.bed")  , optional: true, emit: scraps
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def scores    = splice_scores ? "--splicing-scores $splice_scores" : ''

    meta_scraps = meta.clone()
    meta_scraps.id = meta.id + '.scraps'
    """
    iso-orphan \\
        $args \\
        $scores \\
        --ref $reference \\
        --query tmp.bed \\
        --all \\
        --threads ${task.cpus} \\
        --prefix ${prefix} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-orphan: \$( iso-orphan --version | sed 's/iso-orphan //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch orphans/${prefix}.hq.bed
    touch orphans/${prefix}.scraps.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-orphan: \$( iso-orphan --version | sed 's/iso-orphan //g' )
    END_VERSIONS
    """
}
