/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ORIONGENO_PREDICT — Ab initio OrionGeno annotation on one GPU.

    Thin wrapper around `oriongeno`. Inference requires an NVIDIA GPU
    (compute capability >= 7.0, driver >= 525.60.13). There is no CPU fallback.
    `lineage` selects a checkpoint baked into the image. It does not select
    the species. The published image contains mammals unless it was built
    with ORIONGENO_MODELS. A directory in task.ext.checkpoint or
    meta.checkpoint overrides the lineage. Species conditioning is
    meta.species_name (or meta.species, or task.ext.species_name).
    meta.oriongeno_format is gtf (default) or gff3. meta.oriongeno_output_repeat
    also writes the repeat annotation. Extra flags go in task.ext.args or
    meta.oriongeno_args and are not given biological defaults here.
    Bundled OrionGeno is non-commercial.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ORIONGENO_PREDICT {
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
    if (!(format in ['gtf', 'gff', 'gff3'])) {
        error "Unknown OrionGeno format '${format}'. Use gtf or gff3."
    }
    def ext = (format == 'gff' || format == 'gff3') ? 'gff3' : 'gtf'
    def species = (task.ext.species_name ?: meta.species_name ?: meta.species ?: '').toString()
    def species_arg = species ? "--species-name \"${species}\"" : ''
    def emit_repeat = meta.oriongeno_output_repeat == true || meta.oriongeno_output_repeat == 'true'
    """
    set -euo pipefail
    mkdir -p annotation

    oriongeno \\
        --genome "${genome}" \\
        --output "annotation/${prefix}.${ext}" \\
        --checkpoint "${checkpoint}" \\
        --output-gene true \\
        --output-repeat ${emit_repeat ? 'true' : 'false'} \\
        ${species_arg} \\
        ${args}

    if [ -f "annotation/${prefix}.repeat.${ext}" ]; then
        mkdir -p repeats
        mv "annotation/${prefix}.repeat.${ext}" "repeats/${prefix}.repeat.${ext}"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        oriongeno: \$( oriongeno --version 2>/dev/null | sed 's/^oriongeno //' || echo "2026.7.10" )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def format = (meta.oriongeno_format ?: 'gtf').toString().toLowerCase()
    def ext = (format == 'gff' || format == 'gff3') ? 'gff3' : 'gtf'
    def emit_repeat = meta.oriongeno_output_repeat == true || meta.oriongeno_output_repeat == 'true'
    """
    set -euo pipefail
    mkdir -p annotation
    touch "annotation/${prefix}.${ext}"
    ${emit_repeat ? "mkdir -p repeats && touch \"repeats/${prefix}.repeat.${ext}\"" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        oriongeno: \$( oriongeno --version 2>/dev/null | sed 's/^oriongeno //' || echo "2026.7.10" )
    END_VERSIONS
    """
}
