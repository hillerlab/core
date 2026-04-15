/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOMEMASK_NS — Masks N's in the genome using any nucleotide or random sequence.
    Output can be 2bit, fasta, or fasta.gz. Input sequence can also be any of them.
    Additional arguments may be required (--output-format {} and --nucleotide {}).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GENOMEMASK_NS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/genomemask:latest' }"

    input:
    tuple val(meta), path(genome)

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
    genomemask ns \\
        $args \\
        --sequence $genome

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
