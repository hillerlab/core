/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TALON_LABEL_READS — Flag each read with the fraction of trailing genomic As
    (internal-priming signal) so TALON annotation can screen artifacts. Labelling only.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TALON_LABEL_READS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/talon:6.0.1--pyhdfd78af_0' :
        'biocontainers/talon:6.0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(sam)   // splice-corrected SAM (TranscriptClean output)
    path genome                  // reference genome FASTA

    output:
    tuple val(meta), path("*_labeled.sam")     ,                 emit: sam
    tuple val(meta), path("*_read_labels.tsv") , optional: true, emit: read_labels
    path "versions.yml"                        ,                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    talon_label_reads \\
        --f ${sam} \\
        --g ${genome} \\
        --t ${task.cpus} \\
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
    touch ${prefix}_labeled.sam
    touch ${prefix}_read_labels.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$( talon --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """
}
