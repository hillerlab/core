/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { KINGFISHER_GET } from '../../modules/nextflow/kingfisher/get/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    LOCAL SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow KINGFISHER {
    take:
      joblist        // path(joblist), list with accessions
      ch_versions    // channel: [ path(version) ]

    main:
      Channel.fromPath(
        joblist
      )
      .splitText()
      .map{ it.trim() }
      .set { ch_accessions }

      KINGFISHER_GET(
        ch_accessions
      )

      ch_versions = KINGFISHER_GET.out.versions
      
    emit:
      fastq = KINGFISHER_GET.out.fastq
      fasta = KINGFISHER_GET.out.fasta
      bam = KINGFISHER_GET.out.bam
      versions = ch_versions
}
