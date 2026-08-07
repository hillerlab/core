/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TALON_INITIALIZE_DATABASE — Build the TALON SQLite database from the reference
    annotation. Runs once per reference. The database is retained for reproducibility
    and inspection; it is not a quantification product.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TALON_INITIALIZE_DATABASE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/talon:6.0.1--pyhdfd78af_0' :
        'biocontainers/talon:6.0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(annotation)   // reference annotation GTF
    val build                           // genome build label (must match annotation/create-GTF)
    val annotation_name                 // annotation label (must match create-GTF/filter)

    output:
    tuple val(meta), path("*.db"), emit: db
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    talon_initialize_database \\
        --f ${annotation} \\
        --g ${build} \\
        --a ${annotation_name} \\
        ${args} \\
        --o ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """
}
