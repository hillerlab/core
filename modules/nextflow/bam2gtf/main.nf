/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAM2GTF — Turn a genome-aligned (spliced) BAM into a transcript GTF, one transcript
    per primary read: each read's CIGAR is walked so that N operations split exons. Used
    by the SQANTI3 transcript-modeler path to reuse the pipeline's existing alignment
    instead of re-mapping (SQANTI3 QC accepts a GTF, not a BAM). No collapsing is done;
    SQANTI3 corrects and classifies the resulting models.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BAM2GTF {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.23--h96c455f_0' :
        'biocontainers/samtools:1.23--h96c455f_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.models.gtf"), emit: gtf
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // INFO: -F 2308 drops unmapped(4) + secondary(256) + supplementary(2048), so each
    //       output transcript comes from exactly one primary alignment. CIGAR ops that
    //       consume reference (M/=/X/D) extend the current exon; N ends it (intron).
    """
    samtools view -F 2308 ${bam} \\
      | awk 'BEGIN{ OFS="\\t" }
        {
          qn=\$1; flag=\$2; chr=\$3; pos=\$4+0; cig=\$6
          if (chr=="*" || cig=="*") next
          strand = (int(flag/16)%2) ? "-" : "+"
          refpos = pos; exstart = pos; ne = 0; num = ""
          L = length(cig)
          for (k=1; k<=L; k++) {
            c = substr(cig, k, 1)
            if (c ~ /[0-9]/) { num = num c; continue }
            n = num + 0; num = ""
            if (c=="M" || c=="=" || c=="X" || c=="D") { refpos += n }
            else if (c=="N") { ne++; es[ne]=exstart; ee[ne]=refpos-1; refpos += n; exstart = refpos }
          }
          ne++; es[ne]=exstart; ee[ne]=refpos-1
          attr = "gene_id \\"" qn "\\"; transcript_id \\"" qn "\\";"
          print chr, "bam", "transcript", pos, refpos-1, ".", strand, ".", attr
          for (i=1; i<=ne; i++) print chr, "bam", "exon", es[i], ee[i], ".", strand, ".", attr
        }' > ${prefix}.models.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n1 | sed 's/samtools //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.models.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n1 | sed 's/samtools //' )
    END_VERSIONS
    """
}
