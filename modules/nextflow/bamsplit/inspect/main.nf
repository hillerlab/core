/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAMSPLIT_INSPECT — Describe a BAM file and what a split of it would look
    like. Reports header contents, sort order, index state and predicted output
    counts per routing mode. Writes no BAM files; emits a text or JSON report.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BAMSPLIT_INSPECT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/bamsplit:latest' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${prefix}.txt")  , optional: true, emit: report
    tuple val(meta), path("${prefix}.json") , optional: true, emit: json
    path  "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def json   = args.contains('--json') || task.ext.json
    def ext    = json ? 'json' : 'txt'
    def json_flag = json && !args.contains('--json') ? '--json' : ''
    """
    bamsplit \\
        inspect \\
        $args \\
        $bam \\
        -t $task.cpus \\
        $json_flag \\
        > ${prefix}.${ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt
    touch ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
