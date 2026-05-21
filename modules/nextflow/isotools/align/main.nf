/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_ALIGN — Select long reads whose pass-1 split alignment suggests a
    re-align with a larger minimap2 intron cap, and emit them as FASTA / FASTQ / names.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_ALIGN {
    tag "$meta.id"
    label 'custom_process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.fragments.fasta"),   optional: true, emit: fasta
    tuple val(meta), path("*.report.tsv"),        optional: true, emit: report
    path "versions.yml",                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    """
    iso-align \\
        $args \\
        --threads ${task.cpus} \\
        --bam $bam \\
        --output ${prefix}.fragments.fasta \\
        --output-format fasta \\
        --report ${prefix}.report.tsv

    if [ ! -s ${prefix}.fragments.fasta ]; then
        rm ${prefix}.fragments.fasta 
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-align: \$( iso-align --version | sed 's/iso-align //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fragments.fasta
    touch ${prefix}.report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-align: \$( iso-align --version | sed 's/iso-align //g' )
    END_VERSIONS
    """
}
