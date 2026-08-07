/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRANSCRIPTCLEAN — Reference-based correction of mismatches, microindels and
    noncanonical splice junctions in a splice-aware genome alignment, ahead of TALON
    annotation. Correction only — never fabricates or quantifies transcripts.

    TranscriptClean is not distributed on Bioconda/PyPI, so there is no biocontainer or
    Galaxy Singularity image for it. We use the pinned community image that bundles it
    (it also carries samtools and TALON). No image is built here.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TRANSCRIPTCLEAN {
    tag "$meta.id"
    label 'process_medium'

    container 'veupathdb/longreadrnaseq:1.0.0'

    input:
    tuple val(meta),  path(bam)          // coordinate-sorted, splice-aware genome BAM
    path genome                          // reference genome FASTA
    tuple val(meta2), path(splice_jns)   // optional high-confidence SJs ([meta, []] when absent)
    tuple val(meta3), path(variants)     // optional known variants VCF ([meta, []] when absent)

    output:
    tuple val(meta), path("*_clean.sam")   ,                 emit: sam
    tuple val(meta), path("*_clean.fa")    , optional: true, emit: fasta
    tuple val(meta), path("*_clean.log")   , optional: true, emit: log
    tuple val(meta), path("*_clean.TE.log"), optional: true, emit: te_log
    path "versions.yml"                    ,                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def sj     = splice_jns ? "--spliceJns ${splice_jns}" : ''
    def var    = variants   ? "--variants ${variants}"    : ''
    """
    # INFO: TranscriptClean requires a SAM (splice-aware). Convert the aligned BAM first.
    samtools view -h -@ ${task.cpus} -o ${prefix}.input.sam ${bam}

    TranscriptClean.py \\
        --sam ${prefix}.input.sam \\
        --genome ${genome} \\
        --threads ${task.cpus} \\
        ${sj} \\
        ${var} \\
        --deleteTmp \\
        --outprefix ${prefix} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: \$( TranscriptClean.py --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo 'NA' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_clean.sam
    touch ${prefix}_clean.fa
    touch ${prefix}_clean.log
    touch ${prefix}_clean.TE.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: NA
    END_VERSIONS
    """
}
