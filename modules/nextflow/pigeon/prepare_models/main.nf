/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PIGEON_PREPARE_MODELS — Sort and index a query transcript GFF for Pigeon classify.
    Emits the sorted GFF together with its .pgi index.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PIGEON_PREPARE_MODELS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbpigeon:26.2.0--h9ee0642_0' :
        'biocontainers/pbpigeon:26.2.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path("*.sorted.gtf"), path("*.sorted.gtf.pgi"), emit: gff
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    pigeon prepare \\
        ${args} \\
        ${gff}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigeon: \$( pigeon --version | head -n1 | sed 's/pigeon //' | sed 's/ (commit.*//' )
    END_VERSIONS
    """

    stub:
    """
    touch ${gff.baseName}.sorted.gtf
    touch ${gff.baseName}.sorted.gtf.pgi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigeon: \$( pigeon --version | head -n1 | sed 's/pigeon //' | sed 's/ (commit.*//' )
    END_VERSIONS
    """
}
