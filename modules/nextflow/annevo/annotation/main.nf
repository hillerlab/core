/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ANNEVO_ANNOTATION — One-step ANNEVO annotation (prediction + decoding).

    Useful for small genomes and for checking upstream behaviour. Prefer
    ANNEVO_PREDICTION → ANNEVO_DECODING for scalable runs so the GPU is not
    held during CPU decoding.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ANNEVO_ANNOTATION {
    tag "$meta.id"
    label 'process_high'
    label 'process_gpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/annevo:latest' }"

    input:
    tuple val(meta), path(fasta)
    val lineage

    output:
    tuple val(meta), path("*.gff3"), emit: gff
    path "versions.yml",             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = [task.ext.args ?: '', meta.annevo_args ?: ''].findAll { it }.join(' ')
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def model   = task.ext.model ?: (meta.model ?: "/opt/annevo/saved_model/ANNEVO_${lineage}.pt")
    def workers = Math.max(1, (task.cpus as int) - 1)
    """
    annevo annotation \\
        -g ${fasta} \\
        -m ${model} \\
        -l ${lineage} \\
        -o ${prefix}.gff3 \\
        -t ${task.cpus} \\
        --num_workers ${workers} \\
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
