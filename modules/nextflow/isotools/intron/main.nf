/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process ISOTOOLS_INTRON_RETENTION {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed), path(introns), path(_ignore)

    output:
    tuple val(meta), path("*.tsv")       , optional: true, emit: descriptor
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-intron \\
        $args \\
        --introns $introns \\
        --query $bed \\
        --threads ${task.cpus} \\
        --prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-intron: \$( iso-intron --version | sed 's/iso-intron //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-intron: \$( iso-intron --version | sed 's/iso-intron //g' )
    END_VERSIONS
    """
}
