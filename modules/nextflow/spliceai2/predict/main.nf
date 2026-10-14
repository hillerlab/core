/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPLICEAI2_PREDICT — Predict splice sites for one sequence chunk.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SPLICEAI2_PREDICT {
    tag "$meta.id"
    label 'process_low'
    label 'process_gpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/spliceai2:latest' }"

    input:
    tuple val(meta), path(fasta)
    path models
    val species

    output:
    tuple val(meta), path("spliceai/*.donor_plus.wig"),     emit: donor_plus
    tuple val(meta), path("spliceai/*.donor_minus.wig"),    emit: donor_minus
    tuple val(meta), path("spliceai/*.acceptor_plus.wig"),  emit: acceptor_plus
    tuple val(meta), path("spliceai/*.acceptor_minus.wig"), emit: acceptor_minus
    tuple val(meta), path("spliceai/*.wig"),                emit: all
    path "versions.yml",                                    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    spliceai2 predict --no-compile \\
        $args \\
        --sequence "${fasta}" \\
        --models "${models}" \\
        --species "${species}" \\
        --outdir spliceai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2: \$( spliceai2 --version | sed 's/^spliceai2 //g' )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p spliceai
    touch spliceai/stub.donor_plus.wig spliceai/stub.donor_minus.wig \\
          spliceai/stub.acceptor_plus.wig spliceai/stub.acceptor_minus.wig

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai2: \$( spliceai2 --version | sed 's/^spliceai2 //g' )
    END_VERSIONS
    """
}
