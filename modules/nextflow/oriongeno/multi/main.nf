/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ORIONGENO_MULTI — Ab initio OrionGeno annotation across one or more GPUs.

    Thin wrapper around `oriongeno multi`. `--devices` is the GPU list
    Nextflow assigned in CUDA_VISIBLE_DEVICES, or 0 when that variable is
    unset. `label 'process_gpu'` requests one GPU under `-profile gpu`.
    To use several GPUs, set accelerator for this process in the config;
    that selector overrides the label:

        process {
            withName: 'ORIONGENO_MULTI' {
                accelerator = 4
            }
        }

    `oriongeno multi` writes GTF. meta.oriongeno_format other than gtf is
    an error. Lineage, species, repeat output, and extra args match
    ORIONGENO_PREDICT. Inference requires an NVIDIA GPU; there is no CPU
    fallback. Bundled OrionGeno is non-commercial.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ORIONGENO_MULTI {
    tag "$meta.id"
    label 'process_high'
    label 'process_gpu'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/oriongeno:latest' }"

    input:
    tuple val(meta), path(genome)
    val lineage

    output:
    tuple val(meta), path("annotation/*"), emit: annotation
    tuple val(meta), path("repeats/*"),    emit: repeats, optional: true
    path "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = [task.ext.args ?: '', meta.oriongeno_args ?: ''].findAll { it }.join(' ')
    def prefix = task.ext.prefix ?: "${meta.id}"
    def known = ['mammals', 'birds', 'fish', 'other_vertebrates', 'arthropods', 'other_invertebrates', 'plants', 'fungi']
    def lineage_name = lineage.toString()
    def checkpoint = (task.ext.checkpoint ?: meta.checkpoint ?: '').toString()
    if (!checkpoint) {
        if (!known.contains(lineage_name)) {
            error "Unknown OrionGeno lineage '${lineage_name}'. Expected one of: ${known.join(', ')}. Or set task.ext.checkpoint / meta.checkpoint to a checkpoint directory."
        }
        checkpoint = "/opt/oriongeno/checkpoints/oriongeno_${lineage_name}"
    }
    def format = (meta.oriongeno_format ?: 'gtf').toString().toLowerCase()
    if (format != 'gtf') {
        error "ORIONGENO_MULTI writes GTF. oriongeno multi does not emit GFF."
    }
    def species = (task.ext.species_name ?: meta.species_name ?: meta.species ?: '').toString()
    def species_arg = species ? "--species-name \"${species}\"" : ''
    def emit_repeat = meta.oriongeno_output_repeat == true || meta.oriongeno_output_repeat == 'true'
    """
    set -euo pipefail
    mkdir -p annotation

    devices="\${CUDA_VISIBLE_DEVICES:-0}"
    if [ -z "\$devices" ]; then
        devices=0
    fi

    oriongeno multi \\
        --genome "${genome}" \\
        --output "annotation/${prefix}.gtf" \\
        --checkpoint "${checkpoint}" \\
        --devices "\$devices" \\
        --work-dir oriongeno-work \\
        --output-gene true \\
        --output-repeat ${emit_repeat ? 'true' : 'false'} \\
        ${species_arg} \\
        ${args}

    if [ -f "annotation/${prefix}.repeat.gtf" ]; then
        mkdir -p repeats
        mv "annotation/${prefix}.repeat.gtf" "repeats/${prefix}.repeat.gtf"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        oriongeno: \$( oriongeno --version 2>/dev/null | sed 's/^oriongeno //' || echo "2026.7.10" )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def emit_repeat = meta.oriongeno_output_repeat == true || meta.oriongeno_output_repeat == 'true'
    """
    set -euo pipefail
    mkdir -p annotation
    touch "annotation/${prefix}.gtf"
    ${emit_repeat ? "mkdir -p repeats && touch \"repeats/${prefix}.repeat.gtf\"" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        oriongeno: \$( oriongeno --version 2>/dev/null | sed 's/^oriongeno //' || echo "2026.7.10" )
    END_VERSIONS
    """
}
