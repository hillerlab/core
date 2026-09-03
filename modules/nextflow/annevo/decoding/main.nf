/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ANNEVO_DECODING — Convert ANNEVO nucleotide predictions into GFF3.

    CPU-only. Keep this process separate from prediction so GPU allocations
    can be released as soon as the H5 file is written.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ANNEVO_DECODING {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/annevo:latest' }"

    input:
    tuple val(meta), path(fasta), path(predictions)

    output:
    tuple val(meta), path("*.gff3"), emit: gff
    path "versions.yml",             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = [task.ext.args ?: '', meta.annevo_decoding_args ?: ''].findAll { it }.join(' ')
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    annevo decoding \\
        -g ${fasta} \\
        -p ${predictions} \\
        -o ${prefix}.gff3 \\
        -t ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annevo: \$( annevo --version | sed 's/annevo //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gff3

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annevo: \$( annevo --version | sed 's/annevo //g' )
    END_VERSIONS
    """
}
