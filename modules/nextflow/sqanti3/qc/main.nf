/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SQANTI3_QC — Structural QC and classification of collapsed transcript models
    against a reference annotation and genome. Classification only (no filter/rescue).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process SQANTI3_QC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sqanti3:6.0.1--hdfd78af_0' :
        'biocontainers/sqanti3:6.0.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(models)      // collapsed transcript models (GTF/GFF)
    tuple val(meta2), path(ref_gtf)    // reference annotation (GTF)
    path ref_fasta                     // reference genome (FASTA)

    output:
    tuple val(meta), path("*_corrected.gtf")         ,                 emit: gtf
    tuple val(meta), path("*_classification.txt")    ,                 emit: classification
    tuple val(meta), path("*_junctions.txt")         ,                 emit: junctions
    tuple val(meta), path("*_corrected.fasta")       , optional: true, emit: corrected_fasta
    tuple val(meta), path("*_corrected.cds.gtf")     , optional: true, emit: corrected_gtf
    tuple val(meta), path("*_corrected.genePred")    , optional: true, emit: genepred
    tuple val(meta), path("*_SQANTI3_report.html")   , optional: true, emit: report
    tuple val(meta), path("*_SQANTI3_report.pdf")    , optional: true, emit: report_pdf
    tuple val(meta), path("*.qc_params.txt")         , optional: true, emit: params
    path "versions.yml"                              ,                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // INFO: the SQANTI3 6.0.1 biocontainer ships libbz2.so.1.0 but not the libbz2.so.1
    //       soname required by its bundled gtfToGenePred binary. Expose it through a
    //       symlink in a writable directory. No software is installed at runtime; the
    //       library already ships inside the image.
    """
    mkdir -p .libs
    if [ -e /usr/local/lib/libbz2.so.1.0 ] && [ ! -e /usr/local/lib/libbz2.so.1 ]; then
        ln -sf /usr/local/lib/libbz2.so.1.0 .libs/libbz2.so.1
    fi
    export LD_LIBRARY_PATH="\$PWD/.libs:\${LD_LIBRARY_PATH:-}"

    # INFO: TOGA references carry degenerate "lost gene" transcripts (a 3-bp entry with
    #       start/stop codons but no CDS). SQANTI3's `gtfToGenePred -genePredExt` rejects
    #       these ("CDS but no valid frames"). Drop start/stop-codon records from the
    #       reference: gtfToGenePred derives coding bounds from CDS, so real coding genes
    #       are unaffected while the degenerate markers no longer break the conversion.
    awk -F'\\t' '/^#/ || (\$3 != "start_codon" && \$3 != "stop_codon")' ${ref_gtf} > ref.sqanti.gtf

    # INFO: the classification, junction table and corrected GTF are the meaningful QC
    #       outputs. The optional HTML report is a separate R step that can fail on unusual
    #       isoform IDs (e.g. '#' in FLAIR/TOGA names, which R read.table treats as a
    #       comment) — don't let that kill the run once the classification has succeeded.
    set +e
    sqanti3_qc.py \\
        --isoforms ${models} \\
        --refGTF ref.sqanti.gtf \\
        --refFasta ${ref_fasta} \\
        -o ${prefix} \\
        -d . \\
        -t ${task.cpus} \\
        ${args}
    sqanti_rc=\$?
    set -e

    rm -rf .libs

    if [ -s ${prefix}_corrected.cds.gff3 ]; then
      mv ${prefix}_corrected.cds.gff3 ${prefix}_corrected.cds.gtf
    fi

    if [ ! -s ${prefix}_classification.txt ] || [ ! -s ${prefix}_junctions.txt ]; then
        echo "SQANTI3_QC failed before producing classification/junctions (exit \${sqanti_rc})" >&2
        exit \${sqanti_rc}
    fi
    if [ "\${sqanti_rc}" -ne 0 ]; then
        echo "WARNING: SQANTI3_QC exited \${sqanti_rc} after classification — likely the optional HTML report step; continuing with classification outputs." >&2
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sqanti3: \$( sqanti3_qc.py -v 2>&1 | sed 's/SQANTI3 //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_corrected.gtf
    touch ${prefix}_corrected.cds.gtf
    touch ${prefix}_corrected.fasta
    touch ${prefix}_classification.txt
    touch ${prefix}_junctions.txt
    touch ${prefix}.qc_params.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sqanti3: \$( sqanti3_qc.py -v 2>&1 | sed 's/SQANTI3 //' )
    END_VERSIONS
    """
}
