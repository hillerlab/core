/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQTOOLS_ENCODE — Encode FASTQ reads into the columnar BINSEQ (CBQ) format.
    A paired FASTQ set collapses into a single .cbq carrying both mates. The BINSEQ
    mode is inferred from the .cbq output extension, so no --mode flag is needed.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQTOOLS_ENCODE {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqtools:latest' }"

    input:
    tuple val(meta), path(reads)
    val delete_input

    output:
    tuple val(meta), path("*.cbq"), emit: cbq
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bqtools \\
        encode \\
        -o ${prefix}.cbq \\
        -T $task.cpus \\
        $args \\
        $reads

    if [ ${delete_input} == "true" ]; then
        # Resolve symlinks and delete actual files
        for file in $reads; do
            if [ -L "\$file" ]; then
                realpath=\$(readlink -f "\$file")
                rm -f "\$realpath"
            else
                rm -f "\$file"
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.cbq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqtools: \$(bqtools --version | sed 's/bqtools //g')
    END_VERSIONS
    """
}
