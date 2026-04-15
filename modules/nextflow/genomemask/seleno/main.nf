/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOMEMASK_SELENO — Masks selenocysteine codons of the genome using a 
    derived database of selenocysteine codons. Additional arguments may be 
    required (--output-format {} and --nucleotide {}).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GENOMEMASK_SELENO {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/genomemask:latest' }"

    input:
    tuple val(meta), path(genome)
    tuple val(meta1), path(selenocysteine)

    output:
    tuple val(meta), path("*.2bit")              , optional: true, emit: twobit
    tuple val(meta), path("*.fa")                , optional: true, emit: fasta
    tuple val(meta), path("*.fa.gz")             , optional: true, emit: fasta_gz
    path  "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    """
    genomemask \\
        $args \\
        --sequence $genome \\
        --selenocysteine $selenocysteine

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomemask: \$( genomemask --version | head -n 1 | sed 's/genomemask //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.2bit
    touch *.fa
    touch *.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomemask: \$( genomemask --version | head -n 1 | sed 's/genomemask //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
