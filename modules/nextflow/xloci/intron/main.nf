/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    XLOCI_INTRON — Extract intronic loci from genome and RNA-seq reads.
    Identifies novel intronic transcription by comparing genome sequences
    against RNA-seq reads.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process XLOCI_INTRON {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/xloci:latest' }"

    input:
    tuple val(_1), path(genome)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fa")      , optional: true, emit: fasta
    tuple val(meta), path("*.tsv")     , optional: true, emit: tsv
    path  "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    """
    xloci \\
        $args \\
        -f intron \\
        -o . \\
        -s $genome \\
        -r $reads \\
        -t $task.cpus \\
        --prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        xloci: \$( xloci --version | head -n 1 | sed 's/xloci //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        xloci: \$( xloci --version | head -n 1 | sed 's/xloci //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
