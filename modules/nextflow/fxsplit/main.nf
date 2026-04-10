/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process FXSPLIT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/fxsplit:latest' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("chunks/gz/*.gz")      , optional: true, emit: fastx_gz
    tuple val(meta), path("chunks/fx/*.f*")      , optional: true, emit: fastx
    path  "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args   ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def chunks        = task.ext.chunks ?: 400000
    def gzip          = reads.name.endsWith('.gz') ? true : false
    """
    fxsplit \\
        $args \\
        -f $reads \\
        -c $chunks \\
        -t $task.cpus \\
        -C \\
        --suffix ${prefix}

    if [ ${meta.singleton} == true ]; then
        for f in chunks/*fasta.gz; do
            if [ -f "\$f" ]; then
                mv "\$f" "\${f%}.singleton.fasta.gz"
            fi
        done

        for f in chunks/*fastq.gz; do
            if [ -f "\$f" ]; then
                mv "\$f" "\${f%}.singleton.fastq.gz"
            fi
        done

        for f in chunks/*fasta; do
            if [ -f "\$f" ]; then
                mv "\$f" "\${f%}.singleton.fasta"
            fi
        done

        for f in chunks/*fastq; do
            if [ -f "\$f" ]; then
                mv "\$f" "\${f%}.singleton.fastq"
            fi
        done
    fi

    if [ $gzip == true ]; then
        mkdir chunks/gz
        mv chunks/*fast*.gz chunks/gz
    else
        mkdir chunks/fx
        mv chunks/*fast* chunks/fx
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fxsplit: \$( fxsplit --version | head -n 1 | sed 's/fxsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def gzip   = reads.name.endsWith('.gz') ? true : false
    """
    mkdir chunks

    if [ $gzip == true ]; then
        mkdir chunks/gz
        touch chunks/*fast*.gz
        mv chunks/*fast*.gz chunks/gz
    else
        mkdir chunks/fx
        touch chunks/*fasta
        touch chunks/*fastq
        mv chunks/*fasta chunks/fx
        mv chunks/*fastq chunks/fx
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fxsplit: \$( fxsplit --version | head -n 1 | sed 's/fxsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
