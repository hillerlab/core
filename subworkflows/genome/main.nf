/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { TWOBIT_TO_FA } from '../../modules/nextflow/ucsc/twobittofa/main'
include { GUNZIP as GUNZIP_FASTA } from '../../modules/nextflow/gunzip/main'
include { CHROMSIZE } from '../../modules/nextflow/chromsize/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
 
workflow GENOME {
    take:
      genome  // file: /path/to/genome.{2bit/fasta}

    main:
      ch_versions = Channel.empty()
      ch_fasta = Channel.empty()

      def genome_file = file(genome, checkIfExists: true)
      def genome_path = genome_file.toString()

      ch_chrom_sizes = CHROMSIZE([[:], genome_file]).chromsize.map { it[1] }

      // INFO: if fasta is .2bit or .gz, convert or uncompress it
      if (genome_path.endsWith(".2bit")) {
          ch_fasta = TWOBIT_TO_FA([[:], genome_file]).fasta.map { it[1] }
          ch_versions = ch_versions.mix(TWOBIT_TO_FA.out.versions)
      } else if (genome_path.endsWith(".gz")) {
          ch_fasta = GUNZIP_FASTA([[:], genome_file]).gunzip.map { it[1] }
          ch_versions = ch_versions.mix(GUNZIP_FASTA.out.versions)
      } else {
          ch_fasta = Channel.value(genome_file)
      }

      ch_versions = ch_versions.mix(CHROMSIZE.out.versions)

    emit:
      genome      = ch_fasta
      chrom_sizes = ch_chrom_sizes
      versions    = ch_versions
}
