/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GAWK_JOIN — Concatenate multiple files into one using gawk.
    Joins multiple input files into a single output file with optional
    sorting for BED files.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process GAWK_JOIN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0':
        'biocontainers/gawk:5.3.0' }"

    input:
    tuple val(meta), path(files, stageAs: "input/*")
    val extension

    output:
    tuple val(meta), path("*.${extension}") , optional: true, emit: output
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    gawk 1 input/* > ${prefix}.${extension}

    if [[ ! -s "${prefix}.${extension}" ]]; then
        rm ${prefix}.${extension}
    else
      if [[ ${extension} == "bed" ]]; then
          sort -k1,1 -k2,2n ${prefix}.${extension} > ${prefix}.sorted.${extension}
          mv ${prefix}.sorted.${extension} ${prefix}.${extension}
      fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | sed 's/^.*awk version //; s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | sed 's/^.*awk version //; s/ .*//')
    END_VERSIONS
    """
}               
