/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TALON_CREATE_GTF — Export the transcript annotation from the TALON database. Always
    `--observed` (transcripts seen in >=1 dataset). When a whitelist is supplied the
    export is restricted to the selected models (filtered annotation); otherwise it is
    the unfiltered observed annotation. This is the TALON annotation product — no
    abundance/counts are exported.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TALON_CREATE_GTF {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/talon:6.0.1--pyhdfd78af_0' :
        'biocontainers/talon:6.0.1--pyhdfd78af_0' }"

    input:
    // INFO: whitelist is optional; pass [meta, db, []] to export the unfiltered observed GTF.
    tuple val(meta), path(db), path(whitelist)
    val build                 // genome build label (must match init/annotate)
    val annotation_name       // annotation label (must match init/filter)

    output:
    tuple val(meta), path("*_talon*.gtf"), emit: gtf
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def wl = whitelist ? "--whitelist ${whitelist}" : ''
    """
    talon_create_GTF \\
        --db ${db} \\
        -b ${build} \\
        -a ${annotation_name} \\
        --observed \\
        ${wl} \\
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
    touch ${prefix}_talon_observedOnly.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """
}
