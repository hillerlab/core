/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process BEDTOBIGBED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bigtools:0.5.6--hc1c3326_1':
        'biocontainers/bigtools:0.5.6--hc1c3326_1' }"

    input:
    tuple val(meta), path(bed)
    path chrom_sizes
    path autosql

    output:
    tuple val(meta), path("*.bb"), optional: true, emit: bigbed
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def asq = autosql ? "--autosql $autosql" : ''
    """
    bigtools bedtobigbed \\
        $args \\
        $asq \\
        $bed \\
        $chrom_sizes \\
        ${prefix}.bb

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bigtools: \$(bigtools --version | sed -e "s/bigtools v//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bb

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bigtools: \$(bigtools --version | sed -e "s/bigtools v//g")
    END_VERSIONS
    """
}
