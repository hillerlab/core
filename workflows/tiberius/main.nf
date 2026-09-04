/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { TIBERIUS as RUN } from '../../subworkflows/tiberius/main.nf'
include { GENOME } from '../../subworkflows/genome/main.nf'

params.genome                 = null
params.model_cfg              = null
params.tiberius_scatter       = 'chromosome'
params.tiberius_bins          = 8
params.tiberius_batch_size    = null
params.tiberius_seq_len       = null
params.tiberius_protseq       = false
params.tiberius_codingseq     = false
params.tiberius_extra_args    = ''

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TIBERIUS {
    main:
      if (!params.genome) {
          error "Missing required --genome"
      }
      if (!params.model_cfg) {
          error "Missing required --model_cfg (Hiller alias from models.tsv, e.g. mammalia_nosoftmasking_v2)"
      }

      def scatter = (params.tiberius_scatter ?: 'chromosome').toString()
      def bins    = params.tiberius_bins ?: 8

      def flags = []
      if (params.tiberius_batch_size) {
          flags << "--batch_size ${params.tiberius_batch_size}"
      }
      if (params.tiberius_seq_len) {
          flags << "--seq_len ${params.tiberius_seq_len}"
      }
      if (params.tiberius_extra_args) {
          flags << params.tiberius_extra_args
      }

      GENOME(params.genome)

      GENOME.out.genome
          .map { fasta ->
              [
                  [
                      id            : fasta.baseName,
                      tiberius_args : flags.join(' '),
                  ],
                  fasta,
              ]
          }
          .set { ch_input }

      RUN(
          ch_input,
          params.model_cfg,
          scatter,
          bins,
          params.tiberius_protseq,
          params.tiberius_codingseq
      )

    emit:
      gtf       = RUN.out.gtf
      gff       = RUN.out.gff
      proteins  = RUN.out.proteins
      codingseq = RUN.out.codingseq
}

workflow {
    TIBERIUS()
}
