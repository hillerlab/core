/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICETRANSFORMER_CHUNK — Chunk genomic sequences for parallel SpliceTransformer prediction.
    Splits large genomes into smaller chunks to enable parallel processing
    across multiple CPUs while avoiding memory issues.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICETRANSFORMER_CHUNK {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/splicetransformer:latest' }"

    input:
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path("chunks/*.fa"),    optional: true, emit: fasta
    tuple val(meta), path("chunks/*.fa.gz"), optional: true, emit: fasta_gz
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    splicetransformer chunk \\
        $args \\
        -t ${task.cpus} \\
        --sequence ${genome}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer chunk: \$( splicetransformer chunk --version | sed 's/splicetransformer chunk //g' )
    END_VERSIONS
    """

    stub:
    """
    touch chunks/*.fa
    touch chunks/*.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer chunk: \$( splicetransformer chunk --version | sed 's/splicetransformer chunk //g' )
    END_VERSIONS
    """
}
