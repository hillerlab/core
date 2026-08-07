/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TALON_ANNOTATE — Run the TALON annotator: match labelled reads to the reference
    database, assigning known/novel transcript models. Emits the updated database and
    the per-read annotation table (read-level provenance). The read annotation is NOT a
    count matrix and `talon_abundance` is intentionally never run (annotation-only).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TALON_ANNOTATE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/talon:6.0.1--pyhdfd78af_0' :
        'biocontainers/talon:6.0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(labeled_sam)   // labelled SAM (TALON_LABEL_READS output)
    path db                              // TALON database (from TALON_INITIALIZE_DATABASE)
    val build                            // genome build label (must match init/create-GTF)
    val platform                         // sequencing platform string for the config

    output:
    tuple val(meta), path("*_annotated.db")            ,                 emit: db
    tuple val(meta), path("*_talon_read_annot.tsv")    , optional: true, emit: read_annotation
    tuple val(meta), path("*_QC.log")                  , optional: true, emit: log
    path "versions.yml"                                ,                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # INFO: TALON config CSV: dataset_name,description,platform,sam_file (absolute path).
    sam_full=\$( readlink -f ${labeled_sam} )
    echo "${meta.id},${meta.id},${platform},\${sam_full}" > ${prefix}_config.csv

    # INFO: copy the database first so the annotator mutates a local copy (reproducible run).
    cp ${db} ${prefix}_annotated.db

    talon \\
        --f ${prefix}_config.csv \\
        --db ${prefix}_annotated.db \\
        --build ${build} \\
        --threads ${task.cpus} \\
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
    touch ${prefix}_annotated.db
    touch ${prefix}_talon_read_annot.tsv
    touch ${prefix}_QC.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """
}
