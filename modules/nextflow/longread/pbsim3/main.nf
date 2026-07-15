/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process LONGREAD_PBSIM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/longread-rs:latest' }"

    input:
    tuple val(meta), path(sequences), path(isoform_depth), path(manifest)

    output:
    tuple val(meta), path("${meta.id}.pbsim.transcript.tsv"), emit: transcript
    path "versions.yml",                                      emit: versions

    script:
    """
    longread pbsim \\
        --sequences ${sequences} \\
        --isoform-depth ${isoform_depth} \\
        --manifest ${manifest} \\
        --output ${meta.id}.pbsim.transcript.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pbsim.transcript.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """
}
