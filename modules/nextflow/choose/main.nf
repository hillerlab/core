/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CHOOSE — Select fields from text files using the Rust choose CLI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CHOOSE {
    tag "${meta.id}"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/choose:1.3.7' }"


    input:
    tuple val(meta), path(input)
    val selections

    output:
    tuple val(meta), path("*.choose.tsv"), emit: output
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    def selected_fields = selections instanceof List
        ? selections.collect { it.toString() }.join(' ')
        : selections.toString()

    """
    choose \\
        ${args} \\
        ${selected_fields} \\
        -o '\t'
        < "${input}" \\
        > "${input.simpleName}.choose.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        choose: \$(choose --version | awk '{print \$2}')
    END_VERSIONS
    """
}
