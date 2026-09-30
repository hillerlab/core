/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ORIONGENO as RUN; oriongenoLineages; oriongenoScatterModes } from '../../subworkflows/oriongeno/main.nf'
include { GENOME } from '../../subworkflows/genome/main.nf'

params.genome                  = null
params.lineage                 = null
params.species_name            = null
params.checkpoint              = null
params.oriongeno_scatter       = 'chromosome'
params.oriongeno_bins          = 8
params.oriongeno_format        = 'gtf'
params.oriongeno_output_repeat = false
params.oriongeno_extra_args    = ''

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ORIONGENO {
    main:
      if (!params.genome) {
          error "Missing required --genome"
      }
      if (!params.lineage) {
          error "Missing required --lineage"
      }

      def lin = params.lineage.toString()
      def lineages = oriongenoLineages()
      if (!lineages.contains(lin)) {
          error "Unsupported OrionGeno lineage '${lin}'. Choose one of: ${lineages.join(', ')}"
      }

      def scatter = (params.oriongeno_scatter ?: 'chromosome').toString()
      def scatter_modes = oriongenoScatterModes()
      if (!scatter_modes.contains(scatter)) {
          error "Unsupported OrionGeno scatter mode '${scatter}'. Choose one of: ${scatter_modes.join(', ')}"
      }

      def format = (params.oriongeno_format ?: 'gtf').toString().toLowerCase()
      if (!(format in ['gtf', 'gff', 'gff3'])) {
          error "Unsupported OrionGeno format '${format}'. Use gtf or gff3."
      }

      def bins = params.oriongeno_bins
      if (bins == null || bins.toString().trim() == '') {
          bins = 8
      }
      if (scatter == 'weighted' && (bins as int) < 1) {
          error "OrionGeno weighted scatter requires --oriongeno_bins >= 1"
      }

      GENOME(params.genome)

      GENOME.out.genome
          .map { fasta ->
              def meta = [
                  id            : fasta.baseName,
                  oriongeno_args: params.oriongeno_extra_args ?: '',
              ]
              if (params.species_name) {
                  meta.species_name = params.species_name.toString()
              }
              if (params.checkpoint) {
                  meta.checkpoint = params.checkpoint.toString()
              }
              [meta, fasta]
          }
          .set { ch_input }

      RUN(
          ch_input,
          lin,
          scatter,
          bins,
          format,
          params.oriongeno_output_repeat
      )

    emit:
      gtf        = RUN.out.gtf
      gff        = RUN.out.gff
      repeat_gtf = RUN.out.repeat_gtf
      repeat_gff = RUN.out.repeat_gff
      versions   = RUN.out.versions
}

workflow {
    ORIONGENO()
}
