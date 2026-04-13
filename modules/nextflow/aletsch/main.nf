/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ALETSCH — Assemble RNA-seq transcripts using Aletsch.
    Long-read RNA-seq transcript assembler that generates GTF annotations
    and expression profiles from BAM files.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ALETSCH {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aletsch:1.1.3--hdbdd923_0' :
        'biocontainers/aletsch:1.1.3--hdbdd923_0' }"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.gtf")       , emit: gtf
    tuple val(meta), path("*profile")    , emit: profile
    tuple val(meta), env('LINE_COUNT')     , emit: assembled_transcripts
    tuple val(meta), path(bam), path(bai), emit: bam
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def library_type = meta.strandedness ?: 'unstranded'

    """
    # Create necessary directories
    mkdir -p ${prefix}_profile
    mkdir -p ${prefix}_gtf

    # Create sample info file
    echo "${bam}\t${bai}\t${library_type}" > ${prefix}.info

    # Run Aletsch profile generation
    aletsch \\
        --profile \\
        -i ${prefix}.info \\
        -p ${prefix}_profile \\
        $args

    # Run Aletsch assembly
    aletsch \\
        -i ${prefix}.info \\
        -o ${prefix}_gtf/${prefix}.gtf \\
        -p ${prefix}_profile \\
        -d ${prefix}_gtf \\
        $args

    # Move output to current directory
    mv ${prefix}_gtf/${prefix}.gtf ${prefix}.gtf
    mv ${prefix}_profile ${prefix}.profile

    LINE_COUNT=\$(grep -w 'transcript' ${prefix}.gtf | wc -l)
    export LINE_COUNT

    rm -rf ${prefix}_gtf/

    if [ ${params.aletsch_keep_bam} == false ] && [ ${params.star_make_coverage} == false ]; then
        # Resolve symlinks and delete actual files
        if [ -L "${bam}" ]; then
            realpath=\$(readlink -f "${bam}")
            rm -f "${bam}"
            if [ -n "\$realpath" ]; then
                rm -f "\$realpath"
            fi
        else
            rm -f "${bam}"
        fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aletsch: \$(aletsch --version 2>&1 | sed 's/^.*aletsch //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.renamed.gtf

    export LINE_COUNT=0

    mkdir -p ${prefix}.profile
    touch ${prefix}.profile/0.profile

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aletsch: \$(aletsch --version 2>&1 | sed 's/^.*aletsch //; s/ .*\$//')
    END_VERSIONS
    """
}
