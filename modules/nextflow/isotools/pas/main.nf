/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_PAS_CALLER — Call polyadenylation sites using iso-pas.
    Identifies poly(A) sites by analyzing forward and reverse strand peaks
    from RNA-seq data.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_PAS_CALLER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed), path(_1), path(_2)
    tuple val(meta1), path(annotation)
    tuple val(meta2), path(forward_peaks)
    tuple val(meta3), path(reverse_peaks)

    output:
    tuple val(meta), path("*.tsv")       , optional: true, emit: descriptor
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-pas \\
        $args \\
        --refs $annotation \\
        --query $bed \\
        --threads ${task.cpus} \\
        --prefix ${prefix} \\
        -F $forward_peaks \\
        -R $reverse_peaks

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-pas: \$( iso-pas --version | sed 's/iso-pas //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-pas: \$( iso-pas --version | sed 's/iso-pas //g' )
    END_VERSIONS
    """
}
