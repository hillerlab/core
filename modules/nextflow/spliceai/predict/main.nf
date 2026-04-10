/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process SPLICEAI_PREDICT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/containers/spliceai:latest' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("spliceai/*.donor_plus.wig"),     emit: donor_plus
    tuple val(meta), path("spliceai/*.donor_minus.wig"),    emit: donor_minus
    tuple val(meta), path("spliceai/*.acceptor_plus.wig"),  emit: acceptor_plus
    tuple val(meta), path("spliceai/*.acceptor_minus.wig"), emit: acceptor_minus
    tuple val(meta), path("spliceai/*.wig"),                emit: all
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    spliceai predict \\
        $args \\
        --outdir spliceai \\
        --sequence ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai predict: \$( spliceai predict --version | sed 's/spliceai predict //g' )
    END_VERSIONS
    """

    stub:
    """
    touch spliceai/*.wig

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spliceai predict: \$( spliceai predict --version | sed 's/spliceai predict //g' )
    END_VERSIONS
    """
}
