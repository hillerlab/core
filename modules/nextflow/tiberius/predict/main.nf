/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TIBERIUS_PREDICT — Ab initio Tiberius inference.

    Thin wrapper around `tiberius.py`. GPU is used when `-profile gpu`
    exposes a device; otherwise TensorFlow falls back to CPU. Scatter jobs
    should emit GTF only; GFF3 and protein/CDS FASTAs of a scattered run
    come from TIBERIUS_MERGE.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process TIBERIUS_PREDICT {
    tag "$meta.id"
    label 'process_high'
    label 'process_gpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/tiberius:latest' }"

    input:
    tuple val(meta), path(genome)
    val model_cfg

    output:
    tuple val(meta), path("*.gtf"),  emit: gtf
    tuple val(meta), path("*.gff3"), emit: gff,       optional: true
    tuple val(meta), path("*.prot"), emit: proteins,  optional: true
    tuple val(meta), path("*.cds"),  emit: codingseq, optional: true
    path "versions.yml",             emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = [task.ext.args ?: '', meta.tiberius_args ?: ''].findAll { it }.join(' ')
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def custom     = task.ext.model ?: (meta.model ?: '')
    def emit_gff3  = meta.tiberius_emit_gff3 == true
    def emit_prot  = meta.tiberius_protseq == true
    def emit_cds   = meta.tiberius_codingseq == true
    def out_files  = emit_gff3 ? "${prefix}.gtf ${prefix}.gff3" : "${prefix}.gtf"
    def prot_flag  = emit_prot ? "--protseq ${prefix}.prot" : ''
    def cds_flag   = emit_cds ? "--codingseq ${prefix}.cds" : ''
    """
    set -euo pipefail
    model_args=""
    if [ -n "${custom}" ]; then
        model_args="--model ${custom}"
    else
        yaml=\$(awk -F '\\t' -v a="${model_cfg}" '\$1==a {print \$2; exit}' /opt/tiberius/models.tsv)
        if [ -z "\$yaml" ]; then
            echo "Unknown --model_cfg alias '${model_cfg}'. Use a hiller_alias from /opt/tiberius/models.tsv." >&2
            awk -F '\\t' '\$1 !~ /^#/ && \$1 != "hiller_alias" {print \$1}' /opt/tiberius/models.tsv >&2
            exit 1
        fi
        model_args="--model_cfg /opt/tiberius/model_cfg/\$yaml"
    fi

    tiberius.py \\
        --genome ${genome} \\
        \${model_args} \\
        --out ${out_files} \\
        ${prot_flag} \\
        ${cds_flag} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiberius: \$( python3 -c "import tiberius; print(tiberius.__version__)" )
    END_VERSIONS
    """

    stub:
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def emit_gff3 = meta.tiberius_emit_gff3 == true
    def emit_prot = meta.tiberius_protseq == true
    def emit_cds  = meta.tiberius_codingseq == true
    """
    touch ${prefix}.gtf
    ${emit_gff3 ? "touch ${prefix}.gff3" : ''}
    ${emit_prot ? "touch ${prefix}.prot" : ''}
    ${emit_cds ? "touch ${prefix}.cds" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiberius: \$( python3 -c "import tiberius; print(tiberius.__version__)" 2>/dev/null || echo "2.0.7" )
    END_VERSIONS
    """
}
