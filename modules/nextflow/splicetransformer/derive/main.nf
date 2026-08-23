/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICETRANSFORMER_DERIVE — Derive splice event scores from SpliceTransformer predictions.
    Computes splicetransformer effect scores by comparing SpliceTransformer predictions against
    annotated splice sites from a reference annotation.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICETRANSFORMER_DERIVE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/splicetransformer:latest' }"

    input:
    tuple val(meta), path(genome)
    tuple val(meta1), path(annotation)
    tuple val(meta2), path(splicetransformer)

    output:
    tuple val(meta), path("*.derived.tsv"), emit: scores
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    splicetransformer derive \\
        $args \\
        -t ${task.cpus} \\
        --bigwig-dir ${splicetransformer} \\
        --sequence ${genome} \\
        --regions ${annotation} \\
        --prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer derive: $( splicetransformer derive --version | sed 's/splicetransformer derive //g' )
    END_VERSIONS
    """

    stub:
    """
    touch *.derived.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer derive: $( splicetransformer derive --version | sed 's/splicetransformer derive //g' )
    END_VERSIONS
    """
}
