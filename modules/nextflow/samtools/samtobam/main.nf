/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process SAMTOOLS_SAMTOBAM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.23--h96c455f_0' :
        'biocontainers/samtools:1.23--h96c455f_0' }"

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("*.bam")                       , optional: true, emit: bam
    tuple val(meta), path("*.bai")                       , optional: true, emit: bai
    path "versions.yml"                                  , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def keep_temp = task.ext.keep_temp ?: false
    def bam = "${sam.baseName}.bam"
    def bai = "${bam}.bai"
    """
    samtools \\
    view \\
    $args \\
    -@ ${task.cpus} \\
    -b $sam | \\
    samtools \\
    sort \\
    -@ ${task.cpus} \\
    -o $bam

    samtools \\
    index \\
    -@ \\
    {task.cpus} \\
    $bam

    if [ $keep_temp == false ]; then
        if [ -L $sam ]; then
            realpath=\$(readlink -f $sam)
            rm -f "\$realpath"
        else
            rm -f $sam
        fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def bam = sam.baseName + ".bam"
    def bai = bam + ".bai"
    """
    touch ${bam}
    touch ${bai}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
