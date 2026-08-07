# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# RUSTAR_ALIGN — Rust reimplementation of STAR, reading FASTQ or CBQ natively.
# Mirrors modules/nf-core/star/align: same flags, same output filenames and the
# same STAR-compatible Log.final.out. Two deliberate differences:
#   - no inline `samtools index` (the image ships no samtools)
#   - a staged .cbq feeds a single --readFilesIn and suppresses zcat
# WDL 1.2+ removed contains(), so arg-override guards use a sub()-based probe.

version 1.3

task align {
  input {
    Array[File]+ reads
    Directory index
    File? gtf
    File? additional_junctions
    Boolean star_ignore_sjdbgtf = false
    String? seq_platform
    String? seq_center
    Boolean keep_bam = true
    Boolean delete_fastq = false
    Int threads = 1
    String extra_args = ""
  }

  Boolean is_cbq = basename(reads[0], ".cbq") != basename(reads[0])
  String prefix = sub(basename(reads[0]), "\\.(fastq|fq|cbq)(\\.gz)?$", "")
  String reads_in = if is_cbq then "--readFilesIn " + reads[0] + " --readFilesNthreads 4"
                    else if length(reads) == 1 then "--readFilesIn " + reads[0]
                    else "--readFilesIn " + reads[0] + " " + reads[1]
  String delete_targets = sep(' ', reads)
  String has_out_sam_type = sub(extra_args, ".*--outSAMtype.*", "HIT")
  String has_attr_rg = sub(extra_args, ".*--outSAMattrRGline.*", "HIT")
  String has_read_files_cmd = sub(extra_args, ".*--readFilesCommand.*", "HIT")
  String has_unsorted_mv = sub(extra_args, ".*--outSAMtype BAM Unsorted SortedByCoordinate.*", "HIT")
  String has_wig = sub(extra_args, ".*--outWigType.*", "HIT")
  String attr_rg = if has_attr_rg == "HIT" then ""
                   else "--outSAMattrRGline 'ID:" + prefix + "'"
                        + (if defined(seq_center) then " 'CN:" + select_first([seq_center]) + "'" else "")
                        + " 'SM:" + prefix + "'"
                        + (if defined(seq_platform) then " 'PL:" + select_first([seq_platform]) + "'" else "")

  command <<<
    set -euo pipefail

    rustar-aligner \
      --genomeDir ~{index} \
      ~{reads_in} \
      --runThreadN ~{threads} \
      --outFileNamePrefix ~{prefix}. \
      ~{extra_args} \
      ~{if is_cbq || has_read_files_cmd == "HIT" then "" else "--readFilesCommand zcat"} \
      ~{if has_out_sam_type == "HIT" then "" else "--outSAMtype BAM SortedByCoordinate"} \
      ~{if star_ignore_sjdbgtf then "" else "--sjdbGTFfile " + gtf} \
      ~{if defined(additional_junctions) then "--sjdbFileChrStartEnd " + additional_junctions else ""} \
      ~{attr_rg}

    ~{if has_unsorted_mv == "HIT" then "mv ~{prefix}.Aligned.out.bam ~{prefix}.Aligned.unsort.out.bam" else ""}

    if [ -f ~{prefix}.Unmapped.out.mate1 ]; then
      mv ~{prefix}.Unmapped.out.mate1 ~{prefix}.unmapped_1.fastq
      gzip ~{prefix}.unmapped_1.fastq
    fi
    if [ -f ~{prefix}.Unmapped.out.mate2 ]; then
      mv ~{prefix}.Unmapped.out.mate2 ~{prefix}.unmapped_2.fastq
      gzip ~{prefix}.unmapped_2.fastq
    fi

    if [ -f "~{prefix}.Aligned.sortedByCoord.out.bam" ]; then
      BAM_SIZE=$(stat -c%s "~{prefix}.Aligned.sortedByCoord.out.bam")
    else
      BAM_SIZE=0
    fi
    export BAM_SIZE
    echo "$BAM_SIZE" > ~{prefix}.bam_size.txt

    if [ "~{keep_bam}" == "false" ]; then
      rm ~{prefix}.Aligned.sortedByCoord.out.bam
    fi

    if [ "~{delete_fastq}" == "true" ]; then
      # Delete actual input files, not just symlinks
      for file in ~{delete_targets}; do
        if [ -L "$file" ]; then
          realpath=$(readlink -f "$file")
          rm -f "$realpath"
        else
          rm -f "$file"
        fi
      done
    fi

    if [ "~{has_wig}" == "HIT" ]; then
      rm ~{prefix}.Signal.UniqueMultiple.*
      sort -k1,1 -k2,2n ~{prefix}.Signal.Unique.str1.out.bg > tmp.bg
      mv tmp.bg ~{prefix}.Signal.Unique.str1.out.bg
    fi
  >>>

  output {
    File log_final = "~{prefix}.Log.final.out"
    File log_out = "~{prefix}.Log.out"
    File log_progress = "~{prefix}.Log.progress.out"
    File bam_size = "~{prefix}.bam_size.txt"
    File? bam_sorted = "~{prefix}.Aligned.sortedByCoord.out.bam"
    File? bam_unsorted = "~{prefix}.Aligned.unsort.out.bam"
    File? bam_transcript = "~{prefix}.toTranscriptome.out.bam"
    Array[File] fastq = glob("~{prefix}.unmapped_*.fastq.gz")
    File? spl_junc_tab = "~{prefix}.SJ.out.tab"
    File? read_per_gene_tab = "~{prefix}.ReadsPerGene.out.tab"
    File? junction = "~{prefix}.Chimeric.out.junction"
    File? sam = "~{prefix}.out.sam"
    Array[File] wig = glob("~{prefix}*Unique*.wig")
    Array[File] bedgraph = glob("~{prefix}*Unique*.bg")
  }

  requirements {
    container: "ghcr.io/hillerlab/rustar-aligner-cbq:latest"
  }
}

workflow run {
  input {
    Array[File]+ reads
    Directory index
    File? gtf
    File? additional_junctions
    Boolean star_ignore_sjdbgtf = false
    String? seq_platform
    String? seq_center
    Boolean keep_bam = true
    Boolean delete_fastq = false
    Int threads = 1
    String extra_args = ""
  }

  call align {
    input:
      reads = reads,
      index = index,
      gtf = gtf,
      additional_junctions = additional_junctions,
      star_ignore_sjdbgtf = star_ignore_sjdbgtf,
      seq_platform = seq_platform,
      seq_center = seq_center,
      keep_bam = keep_bam,
      delete_fastq = delete_fastq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File log_final = align.log_final
    File log_out = align.log_out
    File log_progress = align.log_progress
    File bam_size = align.bam_size
    File? bam_sorted = align.bam_sorted
    File? bam_unsorted = align.bam_unsorted
    File? bam_transcript = align.bam_transcript
    Array[File] fastq = align.fastq
    File? spl_junc_tab = align.spl_junc_tab
    File? read_per_gene_tab = align.read_per_gene_tab
    File? junction = align.junction
    File? sam = align.sam
    Array[File] wig = align.wig
    Array[File] bedgraph = align.bedgraph
  }
}
