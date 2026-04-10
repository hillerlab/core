/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process ISOSEQ_CLUSTER2 {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/isoseq:4.0.0--h9ee0642_0' :
        'biocontainers/isoseq:4.0.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.transcripts.bam")               , emit: bam
    tuple val(meta), path("*.transcripts.bam.pbi")           , emit: pbi
    tuple val(meta), path("*.transcripts.cluster_report.csv"), emit: cluster_report
    tuple val(meta), path("*.transcripts.hq.bam")            , optional: true, emit: hq_bam
    tuple val(meta), path("*.transcripts.hq.bam.pbi")        , optional: true, emit: hq_pbi
    tuple val(meta), path("*.transcripts.lq.bam")            , optional: true, emit: lq_bam
    tuple val(meta), path("*.transcripts.lq.bam.pbi")        , optional: true, emit: lq_pbi
    tuple val(meta), path("*.transcripts.singletons.bam")    , optional: true, emit: singletons_bam
    tuple val(meta), path("*.transcripts.singletons.bam.pbi"), optional: true, emit: singletons_pbi
    tuple val(meta), path("*.fofn")                          , emit: fofn
    path  "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reads = bam.size() > 1 ? "${bam.join(' ')}" : "${bam[0]}"
    def fofn = "${prefix}.flnc.fofn"
   """
    echo "$reads" | tr ' ' '\n' > $fofn

    isoseq \\
        cluster2 \\
        $fofn \\
        ${prefix}.transcripts.bam \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoseq: \$( isoseq cluster2 --version | head -n 1 | sed 's/isoseq cluster2 //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.transcripts.bam
    touch ${prefix}.transcripts.bam.pbi
    touch ${prefix}.transcripts.cluster_report.csv
    touch ${prefix}.flnc.fofn

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoseq: \$( isoseq cluster2 --version | head -n 1 | sed 's/isoseq cluster2 //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
