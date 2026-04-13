/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BIGWIGMERGE — Merge multiple BigWig files using bigtools.
    Combines multiple coverage BigWig files into a single output file
    using the bigtools bigwigmerge utility.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BIGWIGMERGE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bigtools:0.5.6--hc1c3326_1':
        'biocontainers/bigtools:0.5.6--hc1c3326_1' }"

    input:
    tuple val(meta), path(bigwigs)

    output:
    tuple val(meta), path("*.bw"), emit: bigwig
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bigtools bigwigmerge \\
        $args \\
        $bigwigs \\
        ${prefix}.bw

    if [ ${params.bigtools_bigwigmerge_keep_bigwigs} == false ]; then
      if [ -L ${bigwigs} ]; then
          realpath=\$(readlink -f ${bigwigs})
          rm -f "\$realpath"
      else
          rm -f ${bigwigs}
      fi
    fi
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bigtools: \$(bigtools --version | sed -e "s/bigtools v//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bw

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bigtools: \$(bigtools --version | sed -e "s/bigtools v//g")
    END_VERSIONS
    """
}
