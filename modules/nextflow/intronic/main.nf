/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process INTRONIC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/containers/intronic:latest' }"

    input:
    tuple val(meta), path(introns)

    output:
    tuple val(meta), path("*.meta.iic")      , optional: true, emit: iic
    path  "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    """
    if [ ! -s "$introns" ]; then
        touch ${prefix}.meta.iic
    else
        intronIC classify \\
          -q $introns \\
          -n ${prefix} \\
          $args

        if ! compgen -G "*.meta.iic" > /dev/null; then
            touch ${prefix}.meta.iic
        fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        intronIC: \$( intronIC --version | head -n 1 | sed 's/intronIC //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.meta.iic

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        intronIC: \$( intronIC --version | head -n 1 | sed 's/intronIC //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
} 
