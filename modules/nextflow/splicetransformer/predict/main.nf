/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICETRANSFORMER_PREDICT — Predict splice junctions from genomic sequences.
    Uses SpliceTransformer deep learning model to identify splice sites and outputs
    BigWig files for donor/acceptor and forward/reverse strands.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICETRANSFORMER_PREDICT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/splicetransformer:latest' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("splicetransformer/*.donor_plus.wig"),     emit: donor_plus
    tuple val(meta), path("splicetransformer/*.donor_minus.wig"),    emit: donor_minus
    tuple val(meta), path("splicetransformer/*.acceptor_plus.wig"),  emit: acceptor_plus
    tuple val(meta), path("splicetransformer/*.acceptor_minus.wig"), emit: acceptor_minus
    tuple val(meta), path("splicetransformer/*.wig"),                emit: all
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    splicetransformer predict \\
        $args \\
        --outdir splicetransformer \\
        --sequence ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer predict: \$( splicetransformer predict --version | sed 's/splicetransformer predict //g' )
    END_VERSIONS
    """

    stub:
    """
    touch splicetransformer/*.wig

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        splicetransformer predict: \$( splicetransformer predict --version | sed 's/splicetransformer predict //g' )
    END_VERSIONS
    """
}
