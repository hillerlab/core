/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process LONGREAD_SPLIT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/longread-rs:latest' }"

    input:
    tuple val(meta), path(transcript)

    output:
    tuple val(meta), path("chunks/chunk_*.transcript.tsv"), emit: chunks
    tuple val(meta), path("chunks/chunks.tsv"),             emit: manifest
    path "versions.yml",                                    emit: versions

    script:
    """
    longread split \\
        --transcript ${transcript} \\
        --pbsim-chunks ${params.pbsim_chunks} \\
        --pass-count ${params.pass_count} \\
        --outdir chunks \\
        --prefix ${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_chunk_0001.transcript.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """
}
