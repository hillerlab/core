/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CESAR2 —  A method to realign coding exons or genes to DNA sequences using a 
    Hidden Markov Model. Substantially improves the identification of splice sites 
    that have shifted over a larger distance, which improves the accuracy of detecting 
    the correct exon boundaries. Second, CESAR 2.0 provides a new gene mode that 
    re-aligns entire genes at once
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
