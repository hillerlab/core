/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MINIMAP2_ALIGN — Align long reads to a reference using Minimap2.
    Fast aligner for long reads (PacBio, ONT) that supports splice-aware
    alignment using junction BED and splice scores.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process MINIMAP2_ALIGN {
    tag "$meta.id chunk $meta.chunk"
    label 'process_medium_fast'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/minimap2:2.30--h577a1d6_0' }"

    input:
    tuple val(meta), path(reads)
    tuple val(meta1), path(reference)
    tuple val(meta2), path(splice_scores)
    tuple val(meta3), path(junc_bed)

    output:
    tuple val(meta), path("*.sam")                       , optional: true, emit: sam
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''

    def singleton = meta.singleton ? ".singleton" : ""
    def sam = "${meta.id}.${meta.chunk}${singleton}.sam"
    def spsc = splice_scores ? "--spsc=${splice_scores}" : ''
    def junc = junc_bed ? "--junc-bed ${junc_bed}" : ''
    """
    minimap2 \\
        $args \\
        $spsc \\
        $junc \\
        -t $task.cpus \\
        ${reference} \\
        ${reads} \\
        -o $sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """

    stub:
    def singleton = meta.singleton ? ".singleton" : ""
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.chunk}${singleton}"
    """
    touch ${prefix}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
