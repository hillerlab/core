/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SPLICEAI2 as RUN } from '../../subworkflows/spliceai2/main.nf'
include { GENOME } from '../../subworkflows/genome/main.nf'

params.genome              = null
params.compression         = false
params.spliceai2_models    = null
params.spliceai2_species   = 'GRCh38'
params.spliceai2_loci      = null

workflow SPLICEAI2 {
    main:
      if (!params.genome) {
          error "Missing required --genome"
      }
      if (!params.spliceai2_models) {
          error "Missing required --spliceai2_models"
      }

      def genome_fasta = file(params.genome, checkIfExists: true)
      def models = file(params.spliceai2_models, checkIfExists: true)
      if (!models.toFile().isDirectory()) {
          error "--spliceai2_models must be a directory"
      }

      def compression = params.compression?.toString()?.toBoolean() ?: false
      def species = (params.spliceai2_species ?: 'GRCh38').toString()
      def genome_fai = null
      def loci = null
      if (params.spliceai2_loci) {
          def uncompressed_genome = genome_fasta.toString().replaceFirst(/\.gz$/, '')
          def fasta_name = uncompressed_genome.toLowerCase()
          if (!(fasta_name.endsWith('.fa') || fasta_name.endsWith('.fasta'))) {
              error "--spliceai2_loci requires a .fa or .fasta genome, optionally compressed as .gz"
          }
          genome_fai = file("${uncompressed_genome}.fai", checkIfExists: false)
          if (!genome_fai.toFile().isFile()) {
              error "Missing FASTA index '${genome_fai}' required by --spliceai2_loci; index the uncompressed FASTA (e.g. gunzip -k genome.fa.gz && samtools faidx genome.fa) and keep the .fai next to --genome"
          }
          loci = file(params.spliceai2_loci, checkIfExists: true)
          if (!loci.toFile().isFile()) {
              error "--spliceai2_loci must be a BED file"
          }
      }

      GENOME(genome_fasta)

      RUN(
          GENOME.out.genome.map { g -> [ [ id: g.baseName ], g ] },
          GENOME.out.chrom_sizes,
          compression,
          models,
          species,
          genome_fai,
          loci,
          GENOME.out.versions
      )

    emit:
      spliceai2   = RUN.out.spliceai2
      transcripts = RUN.out.transcripts
      skipped     = RUN.out.skipped
}

workflow {
    SPLICEAI2()
}
