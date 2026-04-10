/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process SAMTOOLS_MERGE_BAM {
    tag "$meta.id"
    label 'process_low_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.23--h96c455f_0' :
        'biocontainers/samtools:1.23--h96c455f_0' }"

    input:
    tuple val(meta), path(bams, stageAs: "bam/*")

    output:
    tuple val(meta), path("${meta.id}.bam")              , optional: true, emit: bam
    tuple val(meta), path("${meta.id}.bam.bai")          , optional: true, emit: bai
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args  ?: ''
    def keep_temp = task.ext.keep_temp ?: false
    """
    samtools merge \\
        -@ ${task.cpus} \\
        -f $args \\
        ${meta.id}.bam \\
        bam/*.bam

    # INFO: index the merged BAM
    samtools index \\
        -@ ${task.cpus} \\
        ${meta.id}.bam

    # INFO: clean up intermediate sorted BAMs and their indices
    if [ $keep_temp == true ]; then
        rm -rf bam/
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.bam
    touch ${meta.id}.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
