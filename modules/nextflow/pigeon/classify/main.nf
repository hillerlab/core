/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PIGEON_CLASSIFY — Classify a prepared query GFF against a prepared reference,
    producing SQANTI3-style classification and junction tables. Classification only
    (Pigeon filtering is a separate operation and is intentionally not run here).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PIGEON_CLASSIFY {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbpigeon:26.2.0--h9ee0642_0' :
        'biocontainers/pbpigeon:26.2.0--h9ee0642_0' }"

    input:
    tuple val(meta),  path(models_gff), path(models_pgi)                                // prepared query (sorted GFF + .pgi)
    tuple val(meta2), path(ref_gtf), path(ref_pgi), path(ref_fasta), path(ref_fai)      // prepared reference bundle

    output:
    tuple val(meta), path("*_classification.txt"), emit: classification
    tuple val(meta), path("*_junctions.txt")     , emit: junctions
    tuple val(meta), path("*.report.json")       , optional: true, emit: report
    tuple val(meta), path("*.summary.txt")       , optional: true, emit: summary
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // INFO: classification only — no --flnc / bulk full-length count file is supplied. This
    //       is an annotation-only workflow: Pigeon classifies the transcript models against
    //       the reference, it does not quantify them.
    """
    pigeon classify \\
        -j ${task.cpus} \\
        -d . \\
        -o ${prefix} \\
        ${args} \\
        ${models_gff} \\
        ${ref_gtf} \\
        ${ref_fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigeon: \$( pigeon --version | head -n1 | sed 's/pigeon //' | sed 's/ (commit.*//' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_classification.txt
    touch ${prefix}_junctions.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigeon: \$( pigeon --version | head -n1 | sed 's/pigeon //' | sed 's/ (commit.*//' )
    END_VERSIONS
    """
}
