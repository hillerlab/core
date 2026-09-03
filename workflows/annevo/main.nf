/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ANNEVO as RUN } from '../../subworkflows/annevo/main.nf'
include { GENOME } from '../../subworkflows/genome/main.nf'

params.genome                  = null
params.lineage                 = null
params.annevo_scatter          = 'chromosome'
params.annevo_bins             = 8
params.annevo_overlap_pred     = null
params.annevo_prediction_args  = ''
params.annevo_decoding_args    = ''

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ANNEVO {
    main:
      if (!params.genome) {
          error "Missing required --genome"
      }
      if (!params.lineage) {
          error "Missing required --lineage"
      }

      def scatter = (params.annevo_scatter ?: 'chromosome').toString()
      def bins    = params.annevo_bins ?: 8
      def overlap = params.annevo_overlap_pred

      GENOME(params.genome)

      GENOME.out.genome
          .map { fasta ->
              [
                  [
                      id                   : fasta.baseName,
                      annevo_args          : params.annevo_prediction_args ?: '',
                      annevo_decoding_args : params.annevo_decoding_args ?: '',
                  ],
                  fasta,
              ]
          }
          .set { ch_input }

      RUN(
          ch_input,
          params.lineage,
          scatter,
          bins,
          overlap
      )

    emit:
      gff         = RUN.out.gff
      predictions = RUN.out.predictions
}

workflow {
    ANNEVO()
}
