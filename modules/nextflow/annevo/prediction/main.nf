/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ANNEVO_PREDICTION — Nucleotide-level ANNEVO inference.

    Thin wrapper around `annevo prediction`. GPU is used when `-profile gpu`
    exposes a device; otherwise PyTorch falls back to CPU. Does not insert
    biological defaults such as `--overlap_pred`.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ANNEVO_PREDICTION {
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
    tuple val(meta), path("*.h5"), emit: predictions
    path "versions.yml",           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = [task.ext.args ?: '', meta.annevo_args ?: ''].findAll { it }.join(' ')
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def model   = task.ext.model ?: (meta.model ?: "/opt/annevo/saved_model/ANNEVO_${lineage}.pt")
    def workers = Math.max(1, (task.cpus as int) - 1)
    """
    annevo prediction \\
        -g ${fasta} \\
        -m ${model} \\
        -l ${lineage} \\
        -p ${prefix}.h5 \\
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
    touch ${prefix}.h5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        annevo: \$( annevo --version | sed 's/annevo //g' )
    END_VERSIONS
    """
}
