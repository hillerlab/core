/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DESALT_ALIGN — Align reads to a genome using deSALT
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process DESALT_ALIGN {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/desalt:latest' }"


    input:
    tuple val(meta), path(reads)
    tuple val(meta1), path(index)
    tuple val(meta2), path(gtf)

    output:
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def annotation = gtf ? "--gtf ${gtf}" : ''

    """
    deSALT \\
        aln \\
        ${args} \\
        ${annotation} \\
        --thread ${task.cpus} \\
        --output ${meta.id}.sam \\
        ${index} \\
        ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deSALT: \$(deSALT | grep 'Version' | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deSALT: \$(deSALT | grep 'Version' | awk '{print \$2}')
    END_VERSIONS
    """
}
