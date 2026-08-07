/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TALON_FILTER_TRANSCRIPTS — Select which transcript MODELS belong in the final
    annotation. The thresholds (max fraction of trailing As, minimum supporting reads,
    minimum datasets) are internal reproducibility filters used to pick reliable models;
    the whitelist is a (gene_id, transcript_id) provenance list, NOT an abundance matrix.
    Optional: only runs when `params.talon_do_filter = true`.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TALON_FILTER_TRANSCRIPTS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/talon:6.0.1--pyhdfd78af_0' :
        'biocontainers/talon:6.0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(db)   // annotated TALON database (TALON_ANNOTATE output)
    val annotation_name         // annotation label (must match init/create-GTF)

    output:
    tuple val(meta), path("*_whitelist.csv"), emit: whitelist
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    talon_filter_transcripts \\
        --db ${db} \\
        -a ${annotation_name} \\
        ${args} \\
        --o ${prefix}_whitelist.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_whitelist.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """
}
