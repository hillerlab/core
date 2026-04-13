/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    JOIN_JUNCTIONS — Merge and filter splice junction files from STAR.
    Combines multiple SJ.out.tab files from different samples and filters
    by minimum junction length and coverage.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process JOIN_JUNCTIONS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/join_junctions:latest' }"

    input:
    tuple val(meta), path(junctions)
    val min_junction_len
    val min_junction_coverage

    output:
    tuple val(meta), path("*.tab"),                  emit: filtered_junctions
    tuple val(meta), path("*.tab"), env('LINE_COUNT'), emit: filtered_junctions_count
    path "versions.yml",                             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def junction_files = junctions.join(' ')

    """
    join_junctions \\
    -j ${junction_files} \\
    -l ${min_junction_len} \\
    -m ${min_junction_coverage} \\
    -o .
    LINE_COUNT=\$(wc -l < ALL_SJ_out_filtered.tab)
    export LINE_COUNT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //')
        join_junctions: \$(join_junctions --version | sed 's/join_junctions //')
    END_VERSIONS
    """

    stub:
    """
    touch ALL_SJ_out_filtered.tab
    export LINE_COUNT=0

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //')
        join_junctions: \$(join_junctions --version | sed 's/join_junctions //')
    END_VERSIONS
    """
}
