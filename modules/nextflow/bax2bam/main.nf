/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAX2BAM —  Convert BAX to BAM format. Outputs BAM files with scraps and subreads.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


process BAX2BAM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bax2bam:0.0.9--0' :
        'quay.io/biocontainers/bax2bam:0.0.9--0' }"

    input:
    tuple val(meta), path(baxs)

    output:
    tuple val(meta), path("*.subreads.bam"), emit: subreads
    tuple val(meta), path("*.scraps.bam"), emit: scraps
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def bxs = baxs.join(' ')
    def bam = meta.id + '.bam'
    """
    bax2bam \\
      -o ${bam} \\
      $bxs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bax2bam: \$(bax2bam --version 2>&1 | sed 's/^.*bax2bam //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch *.subreads.bam
    touch *.scraps.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bax2bam: \$(bax2bam --version 2>&1 | sed 's/^.*bax2bam //; s/ .*\$//')
    END_VERSIONS
    """
}
