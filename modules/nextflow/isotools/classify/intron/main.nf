/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_CLASSIFY_INTRON — Classify intronic intervals using iso-classify.
    Classifies introns from long-read data using genome, annotation, repeats,
    and optional SpliceAI BigWig files.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_CLASSIFY_INTRON {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(reads), path(intronic)
    tuple val(meta1), path(genome)
    tuple val(meta2), path(annotation)
    tuple val(meta3), path(repeats)
    tuple val(meta4), path(bigwigs)

    output:
    tuple val(meta), path("*.tsv")      , optional: true, emit: tsv
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def spliceai  = bigwigs ? "--bigwig $bigwigs" : ''
    def rps   = repeats ? "--repeats $repeats" : ''
    def iic       = intronic && intronic.size() > 0 ? "--iic $intronic" : ''
    """
    iso-classify intron \\
        --isoseq $reads \\
        --sequence $genome \\
        --toga $annotation \\
        --prefix ${prefix} \\
        $spliceai \\
        $rps \\
        $iic \\
        --outdir . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-classify: \$( iso-classify --version | sed 's/iso-classify //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-classify: \$( iso-classify --version | sed 's/iso-classify //g' )
    END_VERSIONS
    """
}
