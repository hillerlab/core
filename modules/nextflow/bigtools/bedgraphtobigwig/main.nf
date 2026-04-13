/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BEDGRAPHTOBIGWIG — Convert BedGraph to BigWig using bigtools.
    Transforms BedGraph coverage files into indexed BigWig binary format
    for efficient visualization in genome browsers.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BEDGRAPHTOBIGWIG {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bigtools:0.5.6--hc1c3326_1':
        'biocontainers/bigtools:0.5.6--hc1c3326_1' }"

    input:
    tuple val(meta), path(bedgraph)
    path chrom_sizes

    output:
    tuple val(meta), path("*.bw"), emit: bigwig
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bigtools bedgraphtobigwig \\
        $args \\
        $bedgraph \\
        $chrom_sizes \\
        ${prefix}.bw

    if [ ${params.bigtools_keep_bedgraph} == false ]; then
      if [ -L ${bedgraph} ]; then
          realpath=\$(readlink -f ${bedgraph})
          rm -f "\$realpath"
      else
          rm -f ${bedgraph}
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
