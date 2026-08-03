/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSMETA — Multi-sample RNA-seq transcript meta-assembly.
    Simultaneously assembles RNA-seq reads of multiple samples into a unified set
    of transcripts (GTF) and a set of transcripts for each individual sample.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TRANSMETA {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/transmeta:latest' }"

    input:
    tuple val(meta), path(bams, stageAs: "bams/*")
    tuple val(meta1), path(annotation)

    output:
    tuple val(meta), path("transmeta_outdir/TransMeta.gtf"),            emit: gtf
    tuple val(meta), path("transmeta_outdir/TransMeta-[0-9]*.gtf"),     emit: meta_gtf
    tuple val(meta), path("transmeta_outdir/TransMeta.bam*.gtf"),       emit: sample_gtf
    tuple val(meta), path("transmeta_outdir/TransMeta-AG*.gtf"), optional: true, emit: ag_gtf
    path "versions.yml",                                                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    def strand = meta.single_end ?
        (meta.strandedness == 'reverse' ? 'single_reverse' : meta.strandedness == 'forward' ? 'single_forward' : 'single_unstranded') :
        (meta.strandedness == 'reverse' ? 'second' : meta.strandedness == 'forward' ? 'first' : 'unstranded')

    def annotation_arg = annotation ? "-g $annotation" : ''

    """
    ls bams/*.bam > bam.list

    TransMeta \\
        -B bam.list \\
        -s $strand \\
        -o transmeta_outdir \\
        -p $task.cpus \\
        $annotation_arg \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transmeta: \$(TransMeta -v 2>&1 | sed 's/^.*v[.]//; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p transmeta_outdir
    touch transmeta_outdir/TransMeta.gtf
    touch transmeta_outdir/TransMeta-0.gtf
    touch transmeta_outdir/TransMeta.bam1.gtf
    touch transmeta_outdir/TransMeta-AG.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transmeta: \$(TransMeta -v 2>&1 | sed 's/^.*v[.]//; s/ .*//')
    END_VERSIONS
    """
}
