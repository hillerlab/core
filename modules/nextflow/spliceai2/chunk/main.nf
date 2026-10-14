/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICEAI2_CHUNK — Chunk genomic sequences for parallel SpliceAI2 prediction.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICEAI2_CHUNK {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/spliceai2:latest' }"

    input:
    tuple val(meta), path(genome)
    val compression

    output:
    tuple val(meta), path("chunks/chunks/*.fa"),    optional: true, emit: fasta
    tuple val(meta), path("chunks/chunks/*.fa.gz"), optional: true, emit: fasta_gz
    path "versions.yml",                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def gzip = compression ? '--gzip' : ''
    """
    spliceai2 chunk \\
        $args \\
        $gzip \\
        --threads ${task.cpus} \\
        --sequence "${genome}" \\
        --outdir chunks

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2 chunk: \$( spliceai2 chunk --version | sed 's/spliceai2 chunk //g' )
    END_VERSIONS
    """

    stub:
    def extension = compression ? 'fa.gz' : 'fa'
    """
    mkdir -p chunks/chunks
    touch chunks/chunks/stub.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2 chunk: \$( spliceai2 chunk --version | sed 's/spliceai2 chunk //g' )
    END_VERSIONS
    """
}
