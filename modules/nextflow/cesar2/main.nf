/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CESAR2 — Generate chromosome size files from genome FASTA.
    Extracts sequence lengths from a FASTA genome and outputs a chrom.sizes
    file required by many UCSC tools.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CESAR2 {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' : 
        'ghcr.io/hillerlab/cesar2:latest' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*aln*"), emit: cesar2
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    cesar \\
        $args \\
        --max-memory ${task.memory} \\
        $fasta
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cesar: \$(cesar --version | sed -e "s/cesar v//g")
    END_VERSIONS
    """

    stub:
    """
    touch *aln*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cesar: \$(cesar --version | sed -e "s/cesar v//g")
    END_VERSIONS
    """
}
