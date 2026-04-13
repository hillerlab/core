/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DEACON_FILTER — Filter reads using a Deacon transcript index.
    Removes reads that map to a reference index, keeping only novel
    transcripts for downstream analysis.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process DEACON_FILTER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'biocontainers/deacon:0.13.2--h7ef3eeb_1' }"

    input:
    tuple val(meta), path(reads)
    tuple val(meta1), path(index)

    output:
    tuple val(meta), path("*.deacon.fastq.gz"), emit: reads
    tuple val(meta), path("*.deacon.log")     , emit: log
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def out_fq1 = "--output ${prefix}_1.deacon.fastq.gz"
    def out_fq2 = "--output2 ${prefix}_2.deacon.fastq.gz"
    """
    deacon \\
        filter \\
        --threads $task.cpus \\
        $out_fq1 \\
        $out_fq2 \\
        $args \\
        $index \\
        $reads \\
        > ${prefix}.deacon.log 2>&1

    if [ ${params.deacon_keep_fastp_fastq} == false ]; then
        # Resolve symlinks and delete actual files
        for file in $reads; do
            if [ -L "\$file" ]; then
                realpath=\$(readlink -f "\$file")
                rm -f "\$realpath"
            else
                rm -f "\$file"
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.idx
    touch ${prefix}_1.deacon.fastq.gz
    touch ${prefix}_2.deacon.fastq.gz
    touch ${prefix}.deacon.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """
}
